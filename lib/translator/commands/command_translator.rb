require_relative "../translator"
require_relative "../../config/configuration"
require_relative "../../config/os_configuration"
require_relative "../../symbolic/symbolic"
require_relative "../../symbolic/visitor"
require_relative "../../types/types"
require_relative "../input_translator"

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

                attr_reader :result_type

                def initialize(execution: "", result:, result_type:)
                    @execution = execution
                    @result_type = result_type
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
                if command.keep && !command.has_previous_result?
                    # Create slot for result pointer on GPU in env
                    environment_builder.allocate_previous_pointer(command.unique_id)
                end
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
                previous_launcher.kernel_builder.result_type = command_translation_result.result_type

                if previous_launcher == nil
                    raise "Attempt to pop kernel launcher, but stack is empty"
                end

                program_builder.add_kernel_launcher(previous_launcher)
            end

            def translate_entire_input(command)
                input_translated = command.input.each_with_index.map do |input, index|
                    input.translate_input(
                        command: command,
                        command_translator: self,
                        # Assuming that every input consumes exactly one parameter
                        start_eat_params_offset: index)
                end

                return EntireInputTranslationResult.new(input_translated)
            end

            # Processes a [Symbolic::Input] objects, which contains a reference to a command
            # object and information about how elements are accessed. If elements are only
            # accessed according to the current thread ID, this input can be fused. Otherwise,
            # a new kernel will be built.
            def translate_input(input)
                previous_result = ""

                if input.command.has_previous_result?
                    environment_builder.add_previous_result(input.command.unique_id, input.command.gpu_result_pointer.device_pointer)
                    environment_builder.add_previous_result_type(input.command.unique_id, input.command.gpu_result_pointer.result_type)

                    cell_access = ""
                    if input.pattern == :tid
                        cell_access = "[_tid_]"
                    end

                    kernel_launcher.configure_grid(input.command.size)
                    previous_result = CommandTranslationResult.new(
                        execution: "",
                        result: "((#{input.command.gpu_result_pointer.result_type.to_c_type} *)(_env_->" + "prev_#{input.command.unique_id}))#{cell_access}",
                        result_type: input.command.gpu_result_pointer.result_type)

                    if input.pattern == :tid
                        return previous_result
                    else
                    end
                end

                if input.pattern == :tid
                    # Stay in current kernel                    
                    return input.command.accept(self)
                elsif input.pattern == :entire
                    if !input.command.has_previous_result?
                        # Create new kernel
                        push_kernel_launcher

                        previous_result = input.command.accept(self)
                        previous_result_kernel_var = kernel_launcher.kernel_result_var_name
                        
                        pop_kernel_launcher(previous_result)
                    else
                        kernel_launcher.use_cached_result(input.command.unique_id, input.command.gpu_result_pointer.result_type) 
                        previous_result_kernel_var = "prev_" + input.command.unique_id.to_s
                    end

                    # Add parameter for previous input to this kernel
                    kernel_launcher.add_previous_kernel_parameter(Variable.new(
                        name: previous_result_kernel_var,
                        type: previous_result.result_type))

                    # This is a root command for this kernel, determine grid/block dimensions
                    kernel_launcher.configure_grid(input.command.size, block_size: input.command.block_size)

                    kernel_translation = CommandTranslationResult.new(
                        result: previous_result_kernel_var,
                        result_type: previous_result.result_type)

                    return kernel_translation
                else
                    raise "Unknown input pattern: #{input.pattern}"
                end
            end

            def build_command_translation_result(
                execution:, result:, result_type:, keep: false, unique_id: 0, command: nil)
                if keep
                    command_result = Constants::TEMP_RESULT_IDENTIFIER + unique_id.to_s
                    command_execution = execution + "\n        " + result_type.to_c_type + " " + command_result + " = " + result + ";"
                    kernel_builder.add_cached_result(unique_id.to_s, result_type)
                    kernel_launcher.add_cached_result(unique_id.to_s, result_type)
                    command.gpu_result_pointer = Symbolic::GPUResultPointer.new(result_type: result_type)
                    environment_builder.add_previous_result_type(command.unique_id, result_type)
                else
                    command_result = result
                    command_execution = execution
                end

                command_translation = CommandTranslationResult.new(
                    execution: command_execution,
                    result: command_result,
                    result_type: result_type)
            end
        end
    end
end

require_relative "array_combine_command"
require_relative "array_index_command"
require_relative "array_identity_command"
require_relative "array_reduce_command"
require_relative "array_stencil_command"
require_relative "array_zip_command"

require_relative "iterative"

require_relative "../program_builder"
require_relative "../kernel_launcher"