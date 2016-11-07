require "set"
require_relative "../translator/command_translator"
require_relative "../types/types"
require_relative "../type_aware_array"
require_relative "../parsing"
require_relative "../ast/nodes"
require_relative "../ast/lexical_variables_enumerator"
require_relative "../config/os_configuration"

Ikra::Configuration.check_software_configuration

module Ikra
    module Symbolic
        DEFAULT_BLOCK_SIZE = 256

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
            include Enumerable

            attr_reader :block_size

            # [Fixnum] Returns a unique ID for this command. It is used during name mangling in
            # the code generator to determine the name of array identifiers (and do other stuff?).
            attr_reader :unique_id

            @@unique_id  = 1

            def self.reset_unique_id
                @@unique_id = 1
            end

            def initialize
                super

                # Generate unique ID
                @unique_id = @@unique_id
                @@unique_id += 1
            end

            def [](index)
                if @result == nil
                    execute
                end
                
                @result[index]
            end

            def each(&block)
                next_index = 0

                while next_index < size
                    yield(self[next_index])
                    next_index += 1
                end
            end

            def pack(fmt)
                if @result == nil
                    execute
                end

                @result.pack(fmt)
            end

            def execute
                @result = Translator.translate_command(self).execute
            end
            
            def to_command
                self
            end
            
            def pmap(block_size: Ikra::Symbolic::DEFAULT_BLOCK_SIZE, &block)
                ArrayMapCommand.new(self, block, block_size: block_size)
            end

            # Returns a collection of the names of all block parameters.
            # @return [Array(Symbol)] list of block parameters
            def block_parameter_names
                block.parameters.map do |param|
                    param[1]
                end
            end

            # Returns the size (number of elements) of the result, after executing the parallel 
            # section.
            # @return [Fixnum] size
            def size
                raise NotImplementedError
            end

            def target
                raise NotImplementedError
            end

            # Returns the abstract syntax tree for a parallel section.
            def block_def_node
                # TODO: add caching for AST here
                parser_local_vars = block.binding.local_variables + block_parameter_names
                source = Parsing.parse_block(block, parser_local_vars)
                AST::BlockDefNode.new(
                    ruby_block: block,
                    body: AST::Builder.from_parser_ast(source))
            end

            # Returns a collection of lexical variables that are accessed within a parallel 
            # section.
            # @return [Hash{Symbol => Object}]
            def lexical_externals
                all_lexical_vars = block.binding.local_variables
                lexical_vars_enumerator = AST::LexicalVariablesEnumerator.new(all_lexical_vars)
                block_def_node.accept(lexical_vars_enumerator)
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
            
            def initialize(size, block, block_size: DEFAULT_BLOCK_SIZE)
                super()

                @size = size
                @block = block
                @block_size = block_size
            end
            
            def size
                @size
            end

            protected

            attr_reader :block
        end

        class ArrayMapCommand
            include ArrayCommand
            
            attr_reader :target

            def initialize(target, block, block_size: DEFAULT_BLOCK_SIZE)
                super()

                @target = target
                @block = block
                @block_size = block_size
            end
            
            def size
                @target.size
            end
            
            protected

            attr_reader :block
        end

        def ArrayStencilCommand
            include ArrayCommand

            attr_reader :target
            attr_reader :offsets
            attr_reader :out_of_range_value

            def initialize(target, offsets, out_of_range_value, block, block_size: DEFAULT_BLOCK_SIZE)
                super

                @target = target
                @offsets = offsets
                @out_of_range_value = out_of_range_value
                @block = block
                @block_size = block_size
            end

            protected

            attr_reader :block
        end

        class ArraySelectCommand
            include ArrayCommand

            attr_reader :target

            def initialize(target, block)
                super

                @target = target
                @block = block
            end
            
            # how to implement SELECT?
            # idea: two return values (actual value and boolean indicator as struct type)
        end

        class ArrayIdentityCommand
            include ArrayCommand
            
            attr_reader :target

            Block = Proc.new do |element|
                element
            end

            @@unique_id = 1

            def initialize(target)
                super()

                @target = target

                # Ensure that base array cannot be modified
                target.freeze
            end
            
            def execute
                @target
            end
            
            def size
                @target.size
            end

            # Returns a collection of external objects that are accessed within a parallel section. This includes all elements of the base array.
            def externals
                lexical_externals.keys + @target
            end

            def base_type
                # TODO: add caching (@target is frozen)
                type = Types::UnionType.new

                @target.each do |element|
                    type.add(element.class.to_ikra_type)
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
        def pnew(size, block_size: Ikra::Symbolic::DEFAULT_BLOCK_SIZE, &block)
            Ikra::Symbolic::ArrayNewCommand.new(size, block, block_size: block_size)
        end
    end
    
    def pmap(block_size: Ikra::Symbolic::DEFAULT_BLOCK_SIZE, &block)
        Ikra::Symbolic::ArrayMapCommand.new(to_command, block, block_size: block_size)
    end

    def pstencil(offsets, out_of_range_value, block_size: Ikra::Symbolic::DEFAULT_BLOCK_SIZE, &block)
        Ikra::Symbolic::ArrayStencilCommand.new(to_command, offsets, out_of_range_value, block, block_size: block_size)
    end

    def to_command
        Ikra::Symbolic::ArrayIdentityCommand.new(self)
    end
end

