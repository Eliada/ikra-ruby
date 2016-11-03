require_relative "../ast/nodes"
require_relative "../ast/visitor"
require_relative "../types/types"

module Ikra
    module AST
        class LVarReadNode
            attr_accessor :variable_kind

            def mangled_identifier
                if variable_kind == :lexical
                    return Translator::Constants::LEXICAL_VAR_PREFIX + identifier.to_s
                else
                    return identifier
                end
            end
        end
        
        class LVarWriteNode
            attr_accessor :variable_kind

            def mangled_identifier
                if variable_kind == :lexical
                    return Translator::Constants::LEXICAL_VAR_PREFIX + identifier.to_s
                else
                    return identifier
                end
            end
        end
    end

    module Translator
        class VariableClassifier < AST::Visitor
            def initialize(lexical_variable_names:)
                @lexical_variable_names = lexical_variable_names
            end

            def visit_lvar_read_node(node)
                node.variable_kind = var_type(node.identifier)
            end
            
            def visit_lvar_write_node(node)
                node.variable_kind = var_type(node.identifier)
                super(node)
            end

            def var_type(identifier)
                if @lexical_variable_names.include?(identifier)
                    return :lexical
                else
                    return :local
                end
            end
        end
    end
end