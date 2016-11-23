require_relative "../ast/nodes.rb"
require_relative "../ast/builder.rb"
require_relative "../types/types"
require_relative "../parsing"
require_relative "../ast/printer"
require_relative "variable_classifier_visitor"

module Ikra
    module Translator

        # The result of Ruby-to-CUDA translation of a block using {Translator}
        class BlockTranslationResult

            # @return [String] Generated CUDA source code
            attr_accessor :block_source

            # @return [UnionType] Return value type of method/block
            attr_accessor :result_type

            # @return [String] Name of function of block in CUDA source code
            attr_accessor :function_name

            # @return [String] Auxiliary methods that are called by this block 
            # (including transitive method calls)
            attr_accessor :aux_methods

            def initialize(c_source:, result_type:, function_name:, aux_methods: [])
                @block_source = c_source
                @result_type = result_type
                @function_name = function_name
                @aux_methods = aux_methods
            end
        end

        BlockSelectorDummy = :"<BLOCK>"

        class << self
            # Translates a Ruby block to CUDA source code.
            # @param [AST::BlockDefNode] block_def_node AST (abstract syntax tree) of the block
            # @param [EnvironmentBuilder] environment_builder environment builder instance 
            # collecting information about lexical variables (environment)
            # @param [Hash{Symbol => UnionType}] block_parameter_types types of arguments passed 
            # to the block
            # @param [Hash{Symbol => Object}] lexical_variables all lexical variables that are 
            # accessed within the block
            # @param [Fixnum] command_id a unique identifier of the block
            # @param [String] pre_execution source code that should be run before executing the
            # block
            # @param [Array{String}] override_parameter_decl overrides the the declaration of
            # parameters that this block accepts. This parameter should be an array of C++
            # parameter declarations (type-name pairs).
            # @return [BlockTranslationResult]
            def translate_block(block_def_node:, environment_builder:, command_id:, block_parameter_types: {}, lexical_variables: {}, pre_execution: "", override_parameter_decl: nil)
                parameter_types_string = "[" + block_parameter_types.map do |id, type| "#{id}: #{type}" end.join(", ") + "]"
                Log.info("Translating block with input types #{parameter_types_string}")

                # Add information to block_def_node
                block_def_node.parameters_names_and_types = block_parameter_types

                # Lexical variables
                lexical_variables.each do |name, value|
                    block_def_node.lexical_variables_names_and_types[name] = Types::UnionType.new(value.class.to_ikra_type_obj(value))
                end

                # Type inference
                type_inference_visitor = TypeInference::Visitor.new
                return_type = type_inference_visitor.process_block(block_def_node)
                
                # Auxiliary methods are instance methods that are called by the block
                aux_methods = type_inference_visitor.all_methods.map do |method|
                    method.translate_method
                end

                # Classify variables (lexical or local)
                block_def_node.accept(VariableClassifier.new(
                    lexical_variable_names: lexical_variables.keys))

                # Translate to CUDA/C++ code
                translation_result = block_def_node.translate_block

                # Load environment variables
                lexical_variables.each do |name, value|
                    type = value.class.to_ikra_type_obj(value)
                    mangled_name = environment_builder.add_object(name, value)
                    translation_result.prepend("#{type.to_c_type} #{Constants::LEXICAL_VAR_PREFIX}#{name} = #{Constants::ENV_IDENTIFIER}->#{mangled_name};\n")
                end

                # Declare local variables
                block_def_node.local_variables_names_and_types.each do |name, type|
                    translation_result.prepend("#{type.to_c_type} #{name};\n")
                end

                # Function signature
                mangled_name = "_block_k_#{command_id}_"

                function_parameters = ["environment_t *#{Constants::ENV_IDENTIFIER}"]

                if override_parameter_decl == nil
                    block_parameter_types.each do |param|
                        function_parameters.push("#{param[1].to_c_type} #{param[0].to_s}")
                    end
                else
                    function_parameters.push(*override_parameter_decl)
                end

                function_head = Translator.read_file(
                    file_name: "block_function_head.cpp",
                    replacements: { 
                        "name" => mangled_name, 
                        "return_type" => return_type.to_c_type,
                        "parameters" => function_parameters.join(", ")})

                translation_result = function_head + 
                    wrap_in_c_block(pre_execution + "\n" + translation_result)

                # TODO: handle more than one result type
                return BlockTranslationResult.new(
                    c_source: translation_result, 
                    result_type: return_type,
                    function_name: mangled_name,
                    aux_methods: aux_methods)
            end
        end
    end
end