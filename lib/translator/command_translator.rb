require_relative "translator"
require_relative "../config/configuration"
require_relative "../config/os_configuration"
require_relative "../symbolic/symbolic"
require_relative "../symbolic/visitor"
require_relative "../types/types"

module Ikra
    module Translator
        class CommandTranslator < Symbolic::Visitor
            @@unique_id = 0

            def self.next_unique_id
                @@unique_id = @@unique_id + 1
                return @@unique_id
            end

            class CommandTranslationResult
                # Source code that performs the computation of this command for one thread. May 
                # consist of multiple statement. Optional.
                attr_reader :execution

                # Source code that returns the result of the computation. If the computation can
                # be expressed in a single expression, this string can contain the entire
                # computation and `execution` should then be empty.
                attr_reader :result

                attr_reader :return_type

                def initialize(execution: "", result:, return_type:)
                    @execution = execution
                    @return_type = return_type
                    @result = result;
                end
            end

            # Entry point for translator. Returns a [ProgramBuilder], which contains all
            # required information for compiling and executing the CUDA program.
            def self.translate_command(command)
                command_translator = self.new(root_command: command)
                command_translator.start_translation
                return command_translator.program_builder
            end

            attr_reader :environment_builder
            attr_reader :kernel_launcher_stack
            attr_reader :program_builder
            attr_reader :object_tracer
            attr_reader :root_command

            def initialize(root_command:)
                @kernel_launcher_stack = []
                @environment_builder = EnvironmentBuilder.new
                @program_builder = ProgramBuilder.new(environment_builder: environment_builder, root_command: root_command)
                @root_command = root_command
            end

            def start_translation
                Log.info("CommandTranslator: Starting translation...")

                # Trace all objects
                @object_tracer = TypeInference::ObjectTracer.new(root_command)
                all_objects = object_tracer.trace_all


                # --- Translate ---

                # Create new kernel launcher
                push_kernel_launcher

                # Result of this kernel should be written back to the host
                kernel_launcher.write_back_to_host!

                # Translate the command (might create additional kernels)
                result = root_command.accept(self)

                # Add kernel builder to ProgramBuilder
                pop_kernel_launcher(result)

                # --- End of Translation ---


                # Add SoA arrays to environment
                object_tracer.register_soa_arrays(environment_builder)
            end

            def kernel_launcher
                return kernel_launcher_stack.last
            end

            def kernel_builder
                return kernel_launcher_stack.last.kernel_builder
            end


            # --- Actual Visitor parts stars here ---

            def visit_array_command(command)
                if command.keep && command.gpu_result_pointer.nil?
                    # Create slot for result pointer on GPU in env
                    environment_builder.add_previous_result(command.unique_id, 0)
                end
            end

            # Translate the block of an `Array.pnew` section.
            def visit_array_new_command(command)
                Log.info("Translating ArrayNewCommand [#{command.unique_id}]")

                super

                # This is a root command, determine grid/block dimensions
                kernel_launcher.configure_grid(command.size)

                # Thread ID is always int
                parameter_types = {command.block_parameter_names.first => Types::UnionType.create_int}

                # All variables accessed by this block should be prefixed with the unique ID
                # of the command in the environment.
                env_builder = @environment_builder[command.unique_id]

                block_translation_result = Translator.translate_block(
                    block_def_node: command.block_def_node,
                    block_parameter_types: parameter_types,
                    environment_builder: env_builder,
                    lexical_variables: command.lexical_externals,
                    command_id: command.unique_id)

                kernel_builder.add_methods(block_translation_result.aux_methods)
                kernel_builder.add_block(block_translation_result.block_source)

                if command.keep
                    command_result = Constants::TEMP_RESULT_IDENTIFIER + command.unique_id.to_s
                    command_execution = "\n        " + block_translation_result.result_type.to_c_type + " " + command_result + " = " + block_translation_result.function_name + "(_env_, _tid_);"
                    kernel_builder.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    kernel_launcher.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    command.gpu_result_pointer = Symbolic::GPUResultPointer.new(return_type: block_translation_result.result_type)
                    environment_builder.add_previous_result_type(command.unique_id, block_translation_result.result_type)
                else
                    command_result = block_translation_result.function_name + "(_env_, _tid_)"
                    command_execution = ""
                end

                command_translation = CommandTranslationResult.new(
                    execution: command_execution,
                    result: command_result,
                    return_type: block_translation_result.result_type)
                
                Log.info("DONE translating ArrayNewCommand [#{command.unique_id}]")

                return command_translation
            end

            def visit_array_combine_command(command)
                Log.info("Translating ArrayCombineCommand [#{command.unique_id}]")

                # Process dependent computation (receiver), returns [CommandTranslationResult]
                input_translated = command.input.map do |input|
                    translate_input(input)
                end
                # Map translated input on return types to prepare hashing of parameter_types
                return_types = input_translated.map do |input|
                    input.return_type
                end

                # Take return types from previous computation
                parameter_types = Hash[command.block_parameter_names.zip(return_types)]

                # All variables accessed by this block should be prefixed with the unique ID
                # of the command in the environment.
                env_builder = @environment_builder[command.unique_id]

                block_translation_result = Translator.translate_block(
                    block_def_node: command.block_def_node,
                    block_parameter_types: parameter_types,
                    environment_builder: env_builder,
                    lexical_variables: command.lexical_externals,
                    command_id: command.unique_id)

                kernel_builder.add_methods(block_translation_result.aux_methods)
                kernel_builder.add_block(block_translation_result.block_source)

                # Build command invocation string
                command_args = (["_env_"] + input_translated.map do |input|
                    input.result
                end).join(", ")


                input_execution = input_translated.map do |input|
                    input.execution
                end.join("\n\n")

                if command.keep
                    command_result = Constants::TEMP_RESULT_IDENTIFIER + command.unique_id.to_s
                    command_execution = "\n        " + block_translation_result.result_type.to_c_type + " " + command_result + " = " + block_translation_result.function_name + "(" + command_args + ");"
                    kernel_builder.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    kernel_launcher.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    command.gpu_result_pointer = Symbolic::GPUResultPointer.new(return_type: block_translation_result.result_type)
                    environment_builder.add_previous_result_type(command.unique_id, block_translation_result.result_type)
                else
                    command_result = block_translation_result.function_name + "(" + command_args + ")"
                    command_execution = ""
                end

                command_translation = CommandTranslationResult.new(
                    execution: input_execution + command_execution,
                    result: command_result,
                    return_type: block_translation_result.result_type)

                kernel_launcher.update_result_name(command.unique_id.to_s)

                Log.info("DONE translating ArrayCombineCommand [#{command.unique_id}]")

                return command_translation
            end

            def visit_array_reduce_command(command)
                Log.info("Translating ArrayReduceCommand [#{command.unique_id}]")

                # Process dependent computation (receiver), returns [CommandTranslationResult]
                input_translated = translate_input(command.input.first)
                block_size = command.block_size

                # Take return type from previous computation
                parameter_types = Hash[command.block_parameter_names.zip([input_translated.return_type] * 2)]

                # All variables accessed by this block should be prefixed with the unique ID
                # of the command in the environment.
                env_builder = @environment_builder[command.unique_id]

                block_translation_result = Translator.translate_block(
                    block_def_node: command.block_def_node,
                    block_parameter_types: parameter_types,
                    environment_builder: env_builder,
                    lexical_variables: command.lexical_externals,
                    command_id: command.unique_id)

                kernel_builder.add_methods(block_translation_result.aux_methods)
                kernel_builder.add_block(block_translation_result.block_source)

                # Add "odd" parameter to the kernel which is needed for reduction
                kernel_builder.add_additional_parameters(Constants::ODD_TYPE + " " + Constants::ODD_IDENTIFIER)

                # Number of elements that will be reduced
                num_threads = command.size
                odd = num_threads % 2 == 1
                # Number of threads needed for reduction
                num_threads = num_threads.fdiv(2).ceil

                previous_result_kernel_var = input_translated.result
                first_launch = true
                
                # While more kernel launches than one are needed to finish reduction
                while num_threads >= block_size + 1
                    # Launch new kernel (with same kernel builder)
                    push_kernel_launcher(kernel_builder)
                    # Configure kernel with correct arguments and grid
                    kernel_launcher.add_additional_arguments(odd)
                    kernel_launcher.configure_grid(num_threads)
                    
                    # First launch of kernel is supposed to allocate new memory, so only reuse memory after first launch 
                    if first_launch
                        first_launch = false
                    else
                        kernel_launcher.reuse_memory!(previous_result_kernel_var)
                    end

                    previous_result_kernel_var = kernel_launcher.kernel_result_var_name

                    pop_kernel_launcher(input_translated)

                    # Update number of threads needed
                    num_threads = num_threads.fdiv(block_size).ceil
                    odd = num_threads % 2 == 1
                    num_threads = num_threads.fdiv(2).ceil
                end

                # Configuration for last launch of kernel
                kernel_launcher.add_additional_arguments(odd)
                kernel_launcher.configure_grid(num_threads)

                if !first_launch
                    kernel_launcher.reuse_memory!(previous_result_kernel_var)
                end

                command_execution = Translator.read_file(file_name: "reduce_body.cpp", replacements: {
                    "previous_result" => input_translated.result,
                    "block_name" => block_translation_result.function_name,
                    "arguments" => Constants::ENV_IDENTIFIER,
                    "block_size" => block_size.to_s,
                    "temp_result" => Constants::TEMP_RESULT_IDENTIFIER,
                    "odd" => Constants::ODD_IDENTIFIER,
                    "type" => block_translation_result.result_type.to_c_type,
                    "num_threads" => Constants::NUM_THREADS_IDENTIFIER})

                command_translation = CommandTranslationResult.new(
                    execution: command_execution,
                    result:  Constants::TEMP_RESULT_IDENTIFIER,
                    return_type: block_translation_result.result_type)

                Log.info("DONE translating ArrayReduceCommand [#{command.unique_id}]")

                return command_translation
            end

            def visit_array_identity_command(command)
                Log.info("Translating ArrayIdentityCommand [#{command.unique_id}]")

                # This is a root command, determine grid/block dimensions
                kernel_launcher.configure_grid(command.size)

                # Add base array to environment
                need_union_type = !command.base_type.is_singleton?
                transformed_base_array = object_tracer.convert_base_array(
                    command.input.first.command, need_union_type)
                environment_builder.add_base_array(command.unique_id, transformed_base_array)

                if command.keep
                    command_result = Constants::TEMP_RESULT_IDENTIFIER + command.unique_id.to_s
                    command_execution = "\n        " + block_translation_result.result_type.to_c_type + " " + command_result + " = " + "#{Constants::ENV_IDENTIFIER}->#{EnvironmentBuilder.base_identifier(command.unique_id)}[_tid_];"
                    kernel_builder.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    kernel_launcher.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    command.gpu_result_pointer = Symbolic::GPUResultPointer.new(return_type: command.base_type)
                    environment_builder.add_previous_result_type(command.unique_id, command.base_type)
                else
                    command_result = "#{Constants::ENV_IDENTIFIER}->#{EnvironmentBuilder.base_identifier(command.unique_id)}[_tid_]"
                    command_execution = ""
                end

                command_translation = CommandTranslationResult.new(
                    execution: command_execution,
                    result: command_result,
                    return_type: command.base_type)

                kernel_launcher.update_result_name(command.unique_id.to_s)

                Log.info("DONE translating ArrayIdentityCommand [#{command.unique_id}]")

                return command_translation
            end

            def visit_array_stencil_command(command)
                Log.info("Translating ArrayStencilCommand [#{command.unique_id}]")

                # Process dependent computation (receiver), returns [CommandTranslationResult]
                input_translated = translate_input(command.input.first)

                # Count number of parameters
                num_parameters = command.offsets.size

                if command.use_parameter_array
                    # Parameters are allocated in a constant-sized array

                    first_param = command.block_parameter_names.first

                    # Take return type from previous computation
                    parameter_types = {first_param => Types::UnionType.new(Types::ArrayType.new(input_translated.return_type))}

                    # Allocate and fill array of parameters
                    actual_parameter_names = (0...num_parameters).map do |param_index| 
                        "_#{first_param}_#{param_index}"
                    end

                    param_array_init = actual_parameter_names.join(", ")

                    pre_execution = "#{input_translated.return_type.to_c_type} #{first_param}[] = {#{param_array_init}};"

                    # Pass multiple single values instead of array
                    override_parameter_decl = actual_parameter_names.map do |param_name|
                        input_translated.return_type.to_c_type + " " + param_name
                    end

                else
                    # Pass separate parameters

                    # Take return type from previous computation
                    parameter_types = Hash[command.block_parameter_names.zip([input_translated.return_type] * num_parameters)]

                    pre_execution = ""
                    override_parameter_decl = nil
                end

                # All variables accessed by this block should be prefixed with the unique ID
                # of the command in the environment.
                env_builder = @environment_builder[command.unique_id]

                block_translation_result = Translator.translate_block(
                    block_def_node: command.block_def_node,
                    block_parameter_types: parameter_types,
                    environment_builder: env_builder,
                    lexical_variables: command.lexical_externals,
                    command_id: command.unique_id,
                    pre_execution: pre_execution,
                    override_parameter_decl: override_parameter_decl)

                kernel_builder.add_methods(block_translation_result.aux_methods)
                kernel_builder.add_block(block_translation_result.block_source)

                # `previous_result` should be an expression returning the array containing the
                # result of the previous computation.
                previous_result = input_translated.result

                arguments = ["_env_"]

                # Pass values from previous computation that are required by this thread.
                for i in 0...num_parameters
                    arguments.push("#{previous_result}[_tid_ + #{command.offsets[i]}]")
                end

                argument_str = arguments.join(", ")
                stencil_computation = block_translation_result.function_name + "(#{argument_str})"

                temp_var_name = Constants::TEMP_RESULT_IDENTIFIER + command.unique_id.to_s

                if command.keep
                    kernel_builder.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    kernel_launcher.add_cached_result(block_translation_result.result_type, command.unique_id.to_s)
                    command.gpu_result_pointer = Symbolic::GPUResultPointer.new(return_type: block_translation_result.result_type)
                    environment_builder.add_previous_result_type(command.unique_id, block_translation_result.result_type)
                end

                # The following template checks if there is at least one index out of bounds. If
                # so, the fallback value is used. Otherwise, the block is executed.
                command_execution = Translator.read_file(file_name: "stencil_body.cpp", replacements: {
                    "execution" => input_translated.execution,
                    "temp_var" => temp_var_name,
                    "result_type" => block_translation_result.result_type.to_c_type,
                    "min_offset" => command.min_offset.to_s,
                    "max_offset" => command.max_offset.to_s,
                    "thread_id" => "_tid_",
                    "input_size" => command.input.first.command.size.to_s,
                    "out_of_bounds_fallback" => command.out_of_range_value.to_s,
                    "stencil_computation" => stencil_computation})

                command_translation = CommandTranslationResult.new(
                    execution: command_execution,
                    result: temp_var_name,
                    return_type: block_translation_result.result_type)

                kernel_launcher.update_result_name(command.unique_id.to_s)

                Log.info("DONE translating ArrayStencilCommand [#{command.unique_id}]")

                return command_translation
            end

            def push_kernel_launcher(kernel_builder = KernelBuilder.new)
                @kernel_launcher_stack.push(KernelLauncher.new(kernel_builder))
            end

            # Pops a KernelBuilder from the kernel builder stack. This method is called when all
            # blocks (parallel sections) for that kernel have been translated, i.e., the kernel
            # is fully built.
            def pop_kernel_launcher(command_translation_result)
                previous_launcher = kernel_launcher_stack.pop
                previous_launcher.kernel_builder.block_invocation = command_translation_result.result
                previous_launcher.kernel_builder.execution = command_translation_result.execution
                previous_launcher.kernel_builder.result_type = command_translation_result.return_type

                if previous_launcher == nil
                    raise "Attempt to pop kernel launcher, but stack is empty"
                end

                program_builder.add_kernel_launcher(previous_launcher)
            end

            # Processes a [Symbolic::Input] objects, which contains a reference to a command
            # object and information about how elements are accessed. If elements are only
            # accessed according to the current thread ID, this input can be fused. Otherwise,
            # a new kernel will be built.
            def translate_input(input)
                if input.pattern == :tid
                    # Stay in current kernel                    
                    if input.command.gpu_result_pointer.nil? || input.command.gpu_result_pointer.device_pointer == 0
                        result = input.command.accept(self)
                    else
                        environment_builder.add_previous_result(input.command.unique_id, input.command.gpu_result_pointer.device_pointer)
                        environment_builder.add_previous_result_type(input.command.unique_id, input.command.gpu_result_pointer.return_type)
                        kernel_launcher.configure_grid(input.command.size)
                        result = CommandTranslationResult.new(
                            execution: "",
                            result: "((#{input.command.gpu_result_pointer.return_type.to_c_type} *)(_env_->" + "prev_" + input.command.unique_id.to_s + "))[_tid_]",
                            #return_type: environment_builder.ffi_struct[("prev_" + input.command.unique_id.to_s).to_sym])
                            return_type: input.command.gpu_result_pointer.return_type)
                    end
                    return result
                elsif input.pattern == :entire
                    if input.command.gpu_result_pointer.nil? || input.command.gpu_result_pointer.device_pointer == 0
                        # Create new kernel
                        push_kernel_launcher

                        previous_result = input.command.accept(self)
                        previous_result_kernel_var = kernel_launcher.kernel_result_var_name
                        
                        pop_kernel_launcher(previous_result)
                    else
                        environment_builder.add_previous_result(input.command.unique_id, input.command.gpu_result_pointer.device_pointer)
                        environment_builder.add_previous_result_type(input.command.unique_id, input.command.gpu_result_pointer.return_type)
                        kernel_launcher.use_cached_result(input.command.gpu_result_pointer.return_type, input.command.unique_id)
                        previous_result = CommandTranslationResult.new(
                            execution: "",
                            result: "((#{input.command.gpu_result_pointer.return_type.to_c_type} *)(_env_->" + "prev_" + input.command.unique_id.to_s + "))",
                            #return_type: environment_builder.ffi_struct[("prev_" + input.command.unique_id.to_s).to_sym])
                            return_type: input.command.gpu_result_pointer.return_type)
                        previous_result_kernel_var = "prev_" + input.command.unique_id.to_s
                    end

                    # Add parameter for previous input to this kernel
                    kernel_launcher.add_previous_kernel_parameter(Variable.new(
                        name: previous_result_kernel_var,
                        type: previous_result.return_type))

                    # This is a root command for this kernel, determine grid/block dimensions
                    kernel_launcher.configure_grid(input.command.size)

                    kernel_translation = CommandTranslationResult.new(
                        result: previous_result_kernel_var,
                        return_type: previous_result.return_type)

                    return kernel_translation
                else
                    raise "Unknown input pattern: #{input.pattern}"
                end
            end
        end
    end
end

require_relative "program_builder"
require_relative "kernel_launcher"