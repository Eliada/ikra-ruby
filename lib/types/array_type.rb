# No explicit `require`s. This file should be includes via types.rb

module Ikra
    module Types
        class ArrayType
            include RubyType

            class << self
                # Ensure singleton per class
                def new(inner_type)
                    if @cache == nil
                        @cache = {}
                        @cache.default_proc = Proc.new do |hash, key|
                            hash[key] = super(key)
                        end
                    end

                    @cache[inner_type]
                end
            end

            attr_reader :inner_type
            
            def initialize(inner_type)
                if not inner_type.is_union_type?
                    raise "Union type expected"
                end

                @inner_type = inner_type
            end

            def to_c_type
                "#{@inner_type.to_c_type} *"
            end

            def to_ffi_type
                :pointer
            end

            def to_ruby_type
                ::Array
            end
        end
    end
end

class Array
    def self.to_ikra_type_obj(object)
        inner_type = Ikra::Types::UnionType.new

        object.each do |element|
            inner_type.expand_with_singleton_type(element.class.to_ikra_type_obj(element))
        end

        Ikra::Types::ArrayType.new(inner_type)
    end
end