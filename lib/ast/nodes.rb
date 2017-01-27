module Ikra
    module AST
        class Node
            attr_accessor :parent

            def eql?(other)
                return self == other
            end

            def ==(other)
                return self.class == other.class
            end

            def hash
                return 1231
            end
        end

        class ProgramNode < Node
            # First block is program entry point
            attr_reader :blocks
            attr_reader :classes

            def initialize(blocks: [], classes: [])
                @blocks = blocks
                @classes = classes
            end

            def ==(other)
                return super(other) && blocks == other.blocks && classes == other.classes
            end

            def hash
                return (blocks.hash + classes.hash) % 4524321
            end
        end

        class ClassDefNode < Node
            attr_reader :name
            attr_reader :instance_variables
            attr_reader :instance_methods
            attr_reader :ruby_class
            
            # Class variables/methods are defined as instance variables/methods on the singleton
            # class ClassDefNode

            def initialize(
                    name:, 
                    ruby_class:, 
                    instance_variables: [], 
                    instance_methods: [], 
                    class_variables: [], 
                    class_methods: [])
                @name = name
                @ruby_class = ruby_class
                @instance_variables = instance_variables
                @instance_methods = instance_methods
            end

            def add_instance_variable(inst_var)
                instance_variables.push(inst_var)
                inst_meth.parent = self
            end

            def add_instance_method(inst_meth)
                instance_methods.push(inst_meth)
                inst_meth.parent = self
            end

            def has_instance_method?(selector)
                return instance_method(selector) != nil
            end

            def instance_method(selector)
                return instance_methods.find do |meth|
                    meth.name == selector
                end
            end

            def enclosing_class
                return self
            end

            def ==(other)
                return super(other) && 
                    name == other.name &&
                    ruby_class == other.ruby_class &&
                    instance_variables == other.instance_variables &&
                    instance_methods == other.instance_methods &&
                    class_variables == other.class_variables &&
                    class_methods == other.class_methods
            end
        end

        class VarDefNode < Node
            attr_reader :name
            attr_accessor :read
            attr_accessor :written

            def initialize(name:, read: false, written: false)
                @name = name
                @read = read
                @written = written
            end

            def ==(other)
                return super(other) &&
                    name == other.name &&
                    read == other.read &&
                    written == other.written
            end
        end

        class BehaviorNode < Node
            def find_behavior_node
                return self
            end
        end

        class MethDefNode < BehaviorNode
            attr_reader :name
            attr_reader :ruby_method
            attr_reader :body

            def initialize(name:, body:, ruby_method:)
                @name = name
                @body = body
                @ruby_method = ruby_method

                body.parent = self
            end

            def binding
                if ruby_method == nil 
                    return nil
                else 
                    return ruby_method.send(:binding)
                end
            end

            def ==(other)
                return super(other) && name == other.name && body == other.body
            end
        end

        class BlockDefNode < BehaviorNode
            attr_reader :body
            attr_reader :ruby_block
            attr_reader :parameters

            def initialize(body:, ruby_block:, parameters: nil)
                @body = body
                @ruby_block = ruby_block
                @parameters = parameters

                body.parent = self
            end

            def binding
                return ruby_block.binding
            end

            def ==(other)
                return super(other) && body == other.body && parameters == other.parameters
            end
        end

        class TreeNode < Node
            def is_begin_node?
                false
            end

            def replace(another_node)
                parent.replace_child(self, another_node)
            end

            def replace_child(node, another_node)
                instance_variables.each do |inst_var|
                    if instance_variable_get(inst_var).equal?(node)
                        instance_variable_set(inst_var, another_node)
                        another_node.parent = self
                    end
                end
            end

            def enclosing_class
                @parent.enclosing_class
            end

            def find_behavior_node
                return parent.find_behavior_node
            end

            def ==(other)
                if instance_variables != other.instance_variables
                    return false
                end

                for var_name in instance_variables
                    if var_name != :@parent
                        # Avoid cycles via :parent... There could still be other cycles though
                        if instance_variable_get(var_name) != other.instance_variable_get(var_name)
                            return false
                        end
                    end
                end

                return true
            end
        end

        # Need to wrap block bodies in RootNode, so that the first node can be replaced if necessary (LastStatementReturnsVisitor)
        class RootNode < TreeNode
            attr_reader :single_child

            def initialize(single_child:)
                @single_child = single_child
                single_child.parent = self
            end
        end

        class ConstNode < TreeNode
            attr_reader :identifier

            def initialize(identifier:)
                @identifier = identifier
            end
        end

        class LVarReadNode < TreeNode
            attr_reader :identifier
            
            def initialize(identifier:)
                @identifier = identifier
            end
        end
        
        class LVarWriteNode < TreeNode
            attr_reader :identifier
            attr_reader :value
            
            def initialize(identifier:, value:)
                @identifier = identifier
                @value = value

                value.parent = self
            end
        end
        
        class IVarReadNode < TreeNode
            attr_reader :identifier

            def initialize(identifier:)
                @identifier = identifier
            end
        end

        class IntLiteralNode < TreeNode
            attr_reader :value
            
            def initialize(value:)
                @value = value
            end
        end
        
        class FloatLiteralNode < TreeNode
            attr_reader :value
            
            def initialize(value:)
                @value = value
            end
        end
        
        class BoolLiteralNode < TreeNode
            attr_reader :value
            
            def initialize(value:)
                @value = value
            end
        end

        class NilLiteralNode < TreeNode
            
        end
        
        class ForNode < TreeNode
            attr_reader :iterator_identifier
            attr_reader :range_from
            attr_reader :range_to
            attr_reader :body_stmts
            
            def initialize(iterator_identifier:, range_from:, range_to:, body_stmts: BeginNode.new)
                @iterator_identifier = iterator_identifier
                @range_from = range_from
                @range_to = range_to
                @body_stmts = body_stmts

                range_from.parent = self
                range_to.parent = self
                body_stmts.parent = self
            end
        end
        
        class WhileNode < TreeNode
            attr_reader :condition
            attr_reader :body_stmts

            def initialize(condition:, body_stmts:)
                @condition = condition
                @body_stmts = body_stmts

                condition.parent = self
                body_stmts.parent = self
            end
        end
        
        class WhilePostNode < TreeNode
            attr_reader :condition
            attr_reader :body_stmts

            def initialize(condition:, body_stmts:)
                @condition = condition
                @body_stmts = body_stmts

                condition.parent = self
                body_stmts.parent = self
            end
        end
        
        class UntilNode < TreeNode
            attr_reader :condition
            attr_reader :body_stmts

            def initialize(condition:, body_stmts:)
                @condition = condition
                @body_stmts = body_stmts

                condition.parent = self
                body_stmts.parent = self
            end
        end
        
        class UntilPostNode < TreeNode
            attr_reader :condition
            attr_reader :body_stmts

            def initialize(condition:, body_stmts:)
                @condition = condition
                @body_stmts = body_stmts

                condition.parent = self
                body_stmts.parent = self
            end
        end

        class BreakNode < TreeNode
        
        end
        
        class IfNode < TreeNode
            attr_reader :condition
            attr_reader :true_body_stmts
            attr_reader :false_body_stmts
            
            def initialize(condition:, true_body_stmts:, false_body_stmts: nil)
                if true_body_stmts == nil
                    # Handle empty `if` statements
                    true_body_stmts = BeginNode.new
                end

                @condition = condition
                @true_body_stmts = true_body_stmts
                @false_body_stmts = false_body_stmts

                condition.parent = self
                
                true_body_stmts.parent = self 

                if false_body_stmts != nil
                    false_body_stmts.parent = self
                end
            end
        end
        
        class TernaryNode < TreeNode
            attr_reader :condition
            attr_reader :true_val
            attr_reader :false_val
            
            def initialize(condition:, true_val:, false_val: nil)
                @condition = condition
                @true_val = true_val
                @false_val = false_val

                condition.parent = self
                
                true_val.parent = self
                false_val.parent = self
            end
        end
        
        class BeginNode < TreeNode
            attr_reader :body_stmts
            
            def initialize(body_stmts: [])
                @body_stmts = body_stmts

                body_stmts.each do |stmt|
                    stmt.parent = self
                end
            end
            
            def replace_child(node, another_node)
                @body_stmts = @body_stmts.map do |stmt|
                    if node.equal?(stmt)
                        another_node.parent = self
                        another_node
                    else
                        stmt
                    end
                end
            end

            def is_begin_node?
                true
            end
        end
        
        class SendNode < TreeNode
            attr_reader :receiver
            attr_reader :selector
            attr_reader :arguments
            attr_reader :block_argument
            
            def initialize(receiver:, selector:, arguments: [], block_argument: nil)
                @receiver = receiver
                @selector = selector
                @arguments = arguments
                @block_argument = block_argument

                receiver.parent = self
                arguments.each do |arg|
                    arg.parent = self
                end
            end

            def replace_child(node, another_node)
                if @receiver.equal?(node)
                    @receiver = another_node
                    another_node.parent = self
                end

                @arguments = @arguments.map do |arg|
                    if node.equal?(arg)
                        another_node.parent = self
                        another_node
                    else
                        arg
                    end
                end
            end

            # Setter required for [HostSectionBuilder]
            def block_argument=(value)
                @block_argument = value
            end
        end

        class ReturnNode < TreeNode
            attr_reader :value

            def initialize(value:)
                @value = value

                value.parent = self
            end
        end
    end
end