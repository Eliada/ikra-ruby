require "set"

module Ikra
    module Types

        # Defines the minimal interface for Ikra types. Instances of {UnionType} are expected in most cases.
        module RubyType
            @@next_class_id = 10

            def to_str
                return to_s
            end

            def inspect
                return to_s
            end
            
            def to_ruby_type
                raise NotImplementedError
            end
            
            def to_c_type
                raise NotImplementedError
            end
            
            def is_primitive?
                false
            end

            def is_union_type?
                false
            end

            def should_generate_self_arg?
                return true
            end

            def to_array_type
                # TODO: This should probably not return a union type by default
                return ArrayType.new(self).to_union_type
            end

            def to_union_type
                return UnionType.new(self)
            end

            def class_id
                if @class_id == nil
                    @class_id = @@next_class_id
                    @@next_class_id += 1
                end

                @class_id
            end

            def eql?(other)
                return self == other
            end

            def hash
                # TODO: Implement
                return 0
            end
        end

        # This type is marker and denotes that an expression should be executed only in the Ruby
        # interpreter. No CUDA code should be generated for such expressions.
        class InterpreterOnlyType
            include RubyType

            def self.new
                if @singleton_instance == nil
                    @singleton_instance = super
                end

                return @singleton_instance
            end
        end
    end
end

class Array
    def to_type_array_string
        "[" + map do |set|
            set.to_s
        end.join(", ") + "]"
    end
end
