require "set"
require_relative "../translator/compiler"
require_relative "../types/primitive_type"
require_relative "../types/class_type"
require_relative "../types/union_type"
require_relative "../type_aware_array"
require_relative "../parsing"
require_relative "../ast/nodes"
require_relative "../ast/lexical_variables_enumerator"
require_relative "../config/os_configuration"

Ikra::Configuration.check_software_configuration

module Ikra
    module Symbolic
        class BlockParameter
            Normal = 0
            Index = 1
            PreviousFusion = 2
            
            attr_accessor :name
            attr_accessor :type
            attr_accessor :source_type

            def initialize(name:, type:, source_type: Normal)
                @name = name
                @type = type
                @source_type = source_type
            end
        end

        module ArrayCommand
            def [](index)
                if @result == nil
                    execute
                end
                
                @result[index]
            end
            
            def execute
                compilation_result = translate
                allocate(compilation_result)
                @result = compilation_result.execute
            end
            
            def to_command
                self
            end
            
            def pmap(&block)
                ArrayMapCommand.new(self, block)
            end

            # Returns a collection of the names of all block parameters.
            # @return [Array(Symbol)] list of block parameters
            def block_parameter_names
                block.parameters.map do |param|
                    param[1]
                end
            end

            # Returns the size (number of elements) of the result, after executing the parallel section.
            # @return [Fixnum] size
            def size
                raise NotImplementedError
            end

            def target
                raise NotImplementedError
            end

            # Returns the abstract syntax tree for a parallel section.
            def ast
                # TODO: add caching for AST here
                parser_local_vars = block.binding.local_variables + block_parameter_names
                source = Parsing.parse_block(block, parser_local_vars)
                AST::Builder.from_parser_ast(source)
            end

            # Returns a collection of lexical variables that are accessed within a parallel section.
            # @return [Hash{Symbol => Object}]
            def lexical_externals
                all_lexical_vars = block.binding.local_variables
                lexical_vars_enumerator = AST::LexicalVariablesEnumerator.new(all_lexical_vars)
                ast.accept(lexical_vars_enumerator)
                accessed_variables = lexical_vars_enumerator.lexical_variables

                result = Hash.new
                for var_name in accessed_variables
                    result[var_name] = block.binding.local_variable_get(var_name)
                end

                result
            end

            # Returns a collection of external objects that are accessed within a parallel section.
            def externals
                lexical_externals.keys
            end

            protected

            # Returns the block of the parallel section.
            # @return [Proc] block
            def block
                raise NotImplementedError
            end
        end

        class ArrayNewCommand
            include ArrayCommand
            
            def initialize(size, block)
                @size = size
                @block = block
            end
            
            def translate
                current_request = Translator::Compiler::CompilationRequest.new(block: @block, size: size)
                # TODO: check if all elements are of same type?
                current_request.add_input_var(Translator::Compiler::InputVariable.new(
                    @block.parameters[0][1], 
                    Types::UnionType.create_int, 
                    Translator::Compiler::InputVariable::Index))
                Ikra::Translator::Compiler.compile(current_request)
            end
            
            def size
                @size
            end
            
            def allocate(compilation_request)
                
            end

            protected

            attr_reader :block
        end

        class ArrayMapCommand
            include ArrayCommand
            
            attr_reader :target

            def initialize(target, block)
                @target = target
                @block = block
            end
            
            def size
                @target.size
            end

            def translate
                compilation_result = @target.translate

                current_request = Translator::Compiler::CompilationRequest.new(block: @block, size: size)
                current_request.add_input_var(Translator::Compiler::InputVariable.new(
                    @block.parameters[0][1], 
                    Types::UnionType.create_unknown, 
                    Translator::Compiler::InputVariable::PreviousFusion))
                compilation_result.merge_request!(current_request)

                compilation_result
            end
            
            def allocate(compilation_request)
                @target.allocate(compilation_request)
            end

            protected

            attr_reader :block
        end

        class ArraySelectCommand
            include ArrayCommand

            attr_reader :target

            def initialize(target, block)
                @target = target
                @block = block
            end
            
            # how to implement SELECT?
            # idea: two return values (actual value and boolean indicator as struct type)
        end

        class ArrayIdentityCommand
            include ArrayCommand
            
            attr_reader :target
            attr_reader :unique_id                  # [Fixnum] Returns a unique ID for this command. It is used during name mangling in the code generator to determine the name of array identifiers.

            Block = Proc.new do |element|
                element
            end

            def initialize(target)
                @target = target

                # Generate unique ID
                if @@unique_id == nil
                    @@unique_id = 1
                end

                @unique_id = @@unique_id
                @@unique_id += 1

                # Ensure that base array cannot be modified
                target.freeze
            end
            
            def execute
                @target
            end
            
            def size
                @target.size
            end

            def translate
                current_request = Translator::Compiler::CompilationRequest.new(block: Block, size: size)
                
                current_request.add_input_var(Translator::Compiler::InputVariable.new(
                    Block.parameters[0][1], 
                    base_type))
                Translator::Compiler.compile(current_request)
            end
            
            def allocate(compilation_request)
                compilation_request.allocate_input_array(@target)
            end

            # Returns a collection of external objects that are accessed within a parallel section. This includes all elements of the base array.
            def externals
                lexical_externals.keys + @target
            end

            def base_type
                # TODO: add caching (@target is frozen)
                type = Types::UnionType.new

                @target.each do |element|
                    type.expand_with_singleton_type(element.class.to_ikra_type)
                end

                type
            end

            protected

            def block
                Block
            end
        end
    end
end

class Array
    class << self
        def pnew(size, &block)
            Ikra::Symbolic::ArrayNewCommand.new(size, block)
        end
    end
    
    def pmap(&block)
        Ikra::Symbolic::ArrayMapCommand.new(to_command, block)
    end
    
    def to_command
        Ikra::Symbolic::ArrayIdentityCommand.new(self)
    end
end

