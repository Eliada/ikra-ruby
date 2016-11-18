module Ikra
    module Translator

        # Interface for transferring data to the CUDA side using FFI. Builds a struct containing all required objects (including lexical variables). Traces objects.
        class EnvironmentBuilder

            class UnionTypeStruct < FFI::Struct
                layout :class_id, :int32, :object_id, :int32
            end

            attr_accessor :objects
            attr_accessor :device_struct_allocation

            def initialize
                @objects = {}
                @device_struct_allocation = ""
            end

            # Adds an objects as a lexical variable.
            def add_object(command_id, identifier, object)
                cuda_id = "l#{command_id}_#{identifier}"
                objects[cuda_id] = object
                
                update_dev_struct_allocation(cuda_id, object)

                cuda_id
            end

            # Adds an object as a base array
            def add_base_array(command_id, object)
                cuda_id = "b#{command_id}_base"
                objects[cuda_id] = object

                cuda_id_size = "b#{command_id}_size"
                if object.class == FFI::MemoryPointer
                    objects[cuda_id_size] = object.size / UnionTypeStruct.size
                else
                    objects[cuda_id_size] = object.size
                end

                # Generate code for copying data to global memory
                update_dev_struct_allocation(cuda_id, object)

                cuda_id
            end

            # Add an array for the Structure of Arrays object layout
            def add_soa_array(name, object)
                objects[name] = object
                objects["#{name}_size"] = object.size

                update_dev_struct_allocation(name, object)
            end

            def update_dev_struct_allocation(field, object)
                if object.class == Array
                    # Allocate new array
                    @device_struct_allocation += Translator.read_file(
                        file_name: "env_builder_copy_array.cpp",
                        replacements: { 
                            "field" => field, 
                            "host_env" => Constants::ENV_HOST_IDENTIFIER,
                            "dev_env" => Constants::ENV_DEVICE_IDENTIFIER,
                            "size_bytes" => (object.first.class.to_ikra_type.c_size * object.size).to_s})
                elsif object.class == FFI::MemoryPointer
                    # This is an array of union type structs
                    # Allocate new array
                    @device_struct_allocation += Translator.read_file(
                        file_name: "env_builder_copy_array.cpp",
                        replacements: { 
                            "field" => field, 
                            "host_env" => Constants::ENV_HOST_IDENTIFIER,
                            "dev_env" => Constants::ENV_DEVICE_IDENTIFIER,
                            "size_bytes" => object.size.to_s})   
                else
                    # Nothing to do, this case is handled by mem-copying the struct
                end
            end

            # Returns the name of the field containing the base array for a certain identity command.
            def self.base_identifier(command_id)
                return "b#{command_id}_base"
            end

            def build_environment_variable
                # Copy arrays to device side
                result = @device_struct_allocation

                # Allocate and copy over environment to device
                result = result + Translator.read_file(
                    file_name: "allocate_memcpy_environment_to_device.cpp",
                    replacements: {
                        "dev_env" => Constants::ENV_DEVICE_IDENTIFIER,
                        "host_env" => Constants::ENV_HOST_IDENTIFIER})

                return result
            end

            def build_environment_struct
                @objects.freeze

                struct_def = "struct environment_struct\n{\n"
                @objects.each do |key, value|
                    if value.class == FFI::MemoryPointer
                        # TODO: can this be an extension method of FFI::MemoryPointer?
                        struct_def += "    union_t * #{key};\n"
                    else
                        struct_def += "    #{value.class.to_ikra_type_obj(value).to_c_type} #{key};\n"
                    end
                end
                struct_def += "};\n"

                return struct_def
            end

            def build_ffi_type
                struct_layout = []
                @objects.each do |key, value|
                    if value.class == FFI::MemoryPointer
                        # TODO: can this be an extension method of FFI::MemoryPointer?
                        struct_layout += [key.to_sym, :pointer]
                    else
                        struct_layout += [key.to_sym, value.class.to_ikra_type_obj(value).to_ffi_type]
                    end
                end

                # Add dummy at the end of layout, because layouts cannot be empty
                struct_layout += [:dummy, :int]

                struct_type = Class.new(FFI::Struct)
                struct_type.layout(*struct_layout)

                struct_type
            end

            def build_ffi_object
                struct_type = build_ffi_type
                struct = struct_type.new

                @objects.each do |key, value|
                    # TODO: need proper Array handling
                    if value.class == Array
                        # Check first element to determine type of array
                        # TODO: check for polymorphic
                        inner_type = value.first.class.to_ikra_type
                        array_ptr = FFI::MemoryPointer.new(value.size * inner_type.c_size)

                        if inner_type == Types::PrimitiveType::Int
                            array_ptr.put_array_of_int(0, value)
                        elsif inner_type == Types::PrimitiveType::Float
                            array_ptr.put_array_of_float(0, value)
                        else
                            raise NotImplementedError
                        end

                        struct[key.to_sym] = array_ptr
                    else
                        struct[key.to_sym] = value
                    end
                end

                struct[:dummy] = 0
                
                struct.to_ptr
            end

            def [](command_id)
                CurriedBuilder.new(self, command_id)
            end

            class CurriedBuilder
                def initialize(builder, command_id)
                    @builder = builder
                    @command_id = command_id
                end

                def add_object(identifier, object)
                    @builder.add_object(@command_id, identifier, object)
                end

                def add_base_array(object)
                    @builder.add_base_array(@command_id, object)
                end
            end

            def clone
                result = self.class.new
                result.objects = @objects.clone
                result.device_struct_allocation = @device_struct_allocation
                result
            end
        end
    end
end
