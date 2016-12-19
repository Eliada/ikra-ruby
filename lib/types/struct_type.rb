# No explicit `require`s. This file should be includes via types.rb

require "ffi"

module Ikra
    module Types
        class StructType
            include RubyType

            attr_reader :fields

            class << self
                # Ensure singleton per class
                def new(fields)
                    if @cache == nil
                        @cache = {} 
                    end

                    if not @cache.include?(identifier_from_hash(fields))
                        @cache[identifier_from_hash(fields)] = super(fields)
                    end

                    @cache[identifier_from_hash(fields)]
                end

                # Generates a unique type identifier based on the types of the struct fields.
                def identifier_from_hash(fields)
                    identifier = "indexed_struct_#{fields.size}_lt_"

                    type_parts = fields.map do |key, value|
                        value.to_c_type
                    end

                    identifier = identifier + type_parts.join("_")

                    return identifier + "_gt_t"
                end
            end

            def initialize(fields)
                fields.each do |key, value|
                    if not value.is_union_type?
                        raise "Union type expected for field #{key}"
                    end
                end

                @fields = fields
            end

            def to_c_type
                return StructType.identifier_from_hash(@fields)
            end

            def to_ffi_type
                # TODO: Support transfering zipped data back from GPU
                return :pointer
            end

            def to_ruby_type
                return Struct
            end
        end

        class ZipStructType < StructType
            class << self
                def new(*types)
                    identifiers = Array.new(types.size) do |index|
                        :"field_#{index}"
                    end

                    super(Hash[identifiers.zip(types)])
                end
            end

            # Performs type inference for the result of accessing this Zip "Array" by index.
            def get_return_type(selector, *arg_nodes)
                # TODO: Can only handle single cases at the moment. This should eventually forward
                # to Array integration code.

                if selector != :"[]"
                    raise "Selector not supported for ZipStructType: #{selector}"
                end

                if arg_nodes.size != 1
                    raise "Expected exactly one argument"
                end

                if arg_nodes.first.class == AST::IntNode
                    if arg_nodes.first.value >= @fields.size
                        raise "ZipStruct index out of bounds: #{arg_nodes.first.value}"
                    end

                    return self[arg_nodes.first.value]
                else
                    return get_return_type_non_constant(selector)
                end
            end

            # Performs type inference for the result of accessing this Zip "Array" by index.
            def get_return_type_non_constant(selector)
                # TODO: Can only handle single cases at the moment. This should eventually forward
                # to Array integration code.

                # TODO: This code assumes that the all struct elements have the same type
                return self[0]
            end

            # Returns the type of the element at [index].
            def [](index)
                return @fields[:"field_#{index}"]
            end

            # A module that provides array-like functionality for FFI Struct types.
            module ZipStruct
                def self.included(base)
                    base.include(Enumerable)
                end

                def method_missing(name, *args, &block)
                    # Call original method
                    return _method_missing(name, *args, &block)
                end

                def [](index)
                    # Out of bounds: returns nil
                    return super(:"field_#{index}")
                end

                def []=(index, value)
                    # Fill up missing slots with `nil`
                    for id in (@fields.size)..index
                        super(:"field_{id}", nil)
                    end

                    super(:"field_{index}", value)
                    return value
                end

                def each(&block)
                    for index in 0...(@fields.size)
                        yield(self[index])
                    end
                end
            end

            def to_ruby_type
                if @struct_type == nil
                    # Create class
                    @struct_type = Class.new(FFI::Struct)
                    @struct_type.include(ZipStruct)

                    # Define layout of struct
                    var_names = Array.new(@fields.size) do |index|
                        :"field_#{index}"
                    end

                    var_types = var_names.map do |name|
                        @fields[name].to_ffi_type
                    end

                    layout = var_names.zip(var_types).flatten
                    @struct_type.layout(*layout)
                end

                return @struct_type
            end
        end
    end

    class Struct
        def initialize(fields:)
            @fields = fields
        end

        alias_method :_method_missing, :method_missing

        def method_missing(name, *args, &block)
            if args.size == 0 && block == nil
                # Read value

                if @fields.include?(name)
                    return @fields[name]
                end
            elsif args.size == 1 && block == nil
                # Write value if last character of selector is `=`

                if name[-1] == "="
                    field_name = name[0...-1]
                    @fields[field_name] = args.first
                end
            end

            return super(name, *args, &block)
        end
    end

    class ZipStruct < Struct

    end
end
