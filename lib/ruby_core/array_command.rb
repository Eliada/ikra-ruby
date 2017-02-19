require_relative "../types/types/array_type.rb"
require_relative "../ast/interpreter.rb"

module Ikra
    module RubyIntegration

        # This visitor traverses the tree of symbolically executed parallel operations. It raises
        # an exception, if an array command was generated by symbolic execution/interpretation of
        # `send_node`.
        class SymbolicCycleFinder < Symbolic::Visitor
            def self.raise_on_cycle(command, send_node)
                visitor = self.new(send_node)
                command.accept(visitor)
            end

            def initialize(send_node)
                @send_node = send_node
            end

            def visit_array_command(node)
                if node.generator_node == @send_node
                    raise CycleDetectedError.new(node: node)
                else
                    # No cycle found yet, check dependent computations
                    super
                end
            end
        end

        class CycleDetectedError < RuntimeError
            def initialize(node:)
                @node = node
            end
        end

        ALL_ARRAY_COMMAND_TYPES = proc do |type|
            type.is_a?(Symbolic::ArrayCommand)
        end

        PMAP_TYPE = proc do |rcvr_type, *args_types, send_node:|
            # TODO: Handle keyword arguments
            
            # Ensure that there is no cycle here. "Cycle" means that the same AST send node
            # was used earlier (i.e., in one of `rcvr_type`'s inputs/dependent computations).
            # In that case we have to abort type inference here, because it would not terminate.
            SymbolicCycleFinder.raise_on_cycle(rcvr_type, send_node)

            rcvr_type.pmap(ast: send_node.block_argument, generator_node: send_node).to_union_type
        end

        PZIP_TYPE = proc do |rcvr_type, *args_types, send_node:|
            # TODO: Support multiple arguments for `pzip`
            types = args_types[0].map do |sing_type|
                raise AssertionError.new("Singleton type expected") if sing_type.is_union_type?
                rcvr_type.pzip(sing_type, generator_node: send_node).to_union_type
            end

            types.reduce(Types::UnionType.new) do |acc, type|
                acc.expand_return_type(type)
            end
        end

        PSTENCIL_TYPE = proc do |rcvr_type, *args_types, send_node:|
            # TODO: Handle keyword arguments
            ruby_args = send_node.arguments.map do |node|
                AST::Interpreter.interpret(node)
            end

            rcvr_type.pstencil(*ruby_args, ast: send_node.block_argument, generator_node: send_node).to_union_type
        end

        LAUNCH_KERNEL = proc do |receiver, method_name, arguments, translator, result_type|
            # The result type is the symbolically executed result of applying this
            # parallel section. The result type is an ArrayCommand.
            array_command = receiver.get_type.singleton_type

            # Translate command
            command_translator = translator.command_translator
            command_translator.push_kernel_launcher
            result = array_command.accept(command_translator)
            kernel_launcher = command_translator.pop_kernel_launcher(result)

            # Generate launch code for all kernels
            launch_code = command_translator.program_builder.build_kernel_launchers

            # Always return a device pointer. Only at the very end, we transfer data to the host.
            result_expr = kernel_launcher.kernel_result_var_name

            result = Translator.read_file(file_name: "host_section_launch_parallel_section.cpp", replacements: {
                "array_command" => receiver.accept(translator.expression_translator),
                "array_command_type" => array_command.to_c_type,
                "result_size" => array_command.size.to_s,
                "kernel_invocation" => launch_code,
                "kernel_result" => result_expr})

            # Clear kernel launchers. Otherwise, we might launch them again in a later, unrelated
            # LAUNCH_KERNEL branch. This is because we reuse the same [ProgramBuilder] for an
            # entire host section.
            command_translator.program_builder.clear_kernel_launchers

            result
        end

        ARRAY_COMMAND_TO_ARRAY_TYPE = proc do |rcvr_type, *args_types, send_node:|
            Types::LocationAwareFixedSizeArrayType.new(
                rcvr_type.result_type,
                location: :device).to_union_type
        end

        SYMBOLICALLY_EXECUTE_KERNEL = proc do |receiver, method_name, arguments, translator, result_type|
            if !result_type.is_singleton?
                raise AssertionError.new("Singleton type expected")
            end

            "new array_command_t<#{result_type.singleton_type.result_type.to_c_type}>()"
        end

        ALL_LOCATION_AWARE_ARRAY_TYPES = proc do |type|
            type.is_a?(Types::LocationAwareFixedSizeArrayType)
        end

        LOCATION_AWARE_ARRAY_TO_HOST_ARRAY_TYPE = proc do |rcvr_type, *args_types|
            Types::LocationAwareFixedSizeArrayType.new(
                rcvr_type.inner_type,
                location: :host).to_union_type
        end

        COPY_ARRAY_TO_HOST = proc do |receiver, method_name, args, translator, result_type|
            if receiver.get_type.singleton_type.location == :host
                receiver.accept(translator.expression_translator)
            else
                c_type = receiver.get_type.singleton_type.inner_type.to_c_type

                Translator.read_file(file_name: "memcpy_device_to_host_expr.cpp", replacements: {
                    "type" => c_type,
                    "device_array" => receiver.accept(translator.expression_translator)})
            end
        end

        # Implement all parallel operations
        implement(
            ALL_ARRAY_COMMAND_TYPES,
            :pmap,
            PMAP_TYPE,
            0,
            SYMBOLICALLY_EXECUTE_KERNEL)

        implement(
            ALL_ARRAY_COMMAND_TYPES,
            :pzip,
            PZIP_TYPE,
            1,
            SYMBOLICALLY_EXECUTE_KERNEL,
            expect_singleton_args: true)

        implement(
            ALL_ARRAY_COMMAND_TYPES,
            :pstencil,
            PSTENCIL_TYPE,
            2,      # neighborhood and default value
            SYMBOLICALLY_EXECUTE_KERNEL)

        implement(
            ALL_ARRAY_COMMAND_TYPES,
            :__call__,
            ARRAY_COMMAND_TO_ARRAY_TYPE,
            0,
            LAUNCH_KERNEL)

        implement(
            ALL_LOCATION_AWARE_ARRAY_TYPES, 
            :__to_host_array__,
            LOCATION_AWARE_ARRAY_TO_HOST_ARRAY_TYPE,
            0,
            COPY_ARRAY_TO_HOST)
    end
end
