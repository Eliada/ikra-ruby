module Ikra
    module AST
        class Node
            def to_s
                "[Node]"
            end
        end

        class RootNode
            def to_s
                "[RootNode: #{child.to_s}]"
            end
        end

        class LVarReadNode
            def to_s
                "[LVarReadNode: #{identifier.to_s}]"
            end
        end

        class LVarWriteNode
            def to_s
                "[LVarWriteNode: #{identifier.to_s} := #{value.to_s}]"
            end
        end

        class IntNode
            def to_s
                "<#{value.to_s}>"
            end
        end

        class FloatNode
            def to_s
                "<#{value.to_s}>"
            end
        end

        class BoolNode
            def to_s
                "<#{value.to_s}>"
            end
        end

        class ForNode
            def to_s
                "[ForNode: #{iterator_identifier.to_s} := #{range_from.to_s}...#{range_to.to_s}, #{body_stmts.to_s}]"
            end
        end

        class BreakNode
            def to_s
                "[BreakNode]"
            end
        end

        class IfNode
            def to_s
                if false_body_stmts != nil
                    "[IfNode: #{condition.to_s}, #{true_body_stmts.to_s}, #{false_body_stmts.to_s}]"
                else
                    "[IfNode: #{condition.to_s}, #{true_body_stmts.to_s}]"
                end
            end
        end

        class BeginNode
            def to_s
                stmts = body_stmts.map do |stmt|
                    stmt.to_s
                end.join(";\n")

                "[BeginNode: {#{stmts}}]"
            end
        end

        class SendNode
            def to_s
                args = arguments.map do |arg|
                    arg.to_s
                end.join("; ")

                "[SendNode: #{receiver.to_s}.#{selector.to_s}(#{args})]"
            end
        end

        class ReturnNode
            def to_s
                "[ReturnNode: #{value.to_s}]"
            end
        end
    end
end