require_relative "../config/configuration"

require_relative "ast_translator"
require_relative "block_translator"
require_relative "command_translator"
require_relative "last_returns_visitor"

module Ikra

    # This module contains functionality for translating Ruby code to CUDA (C++) code.
    module Translator
        module Constants
            ENV_IDENTIFIER = "_env_"
            ENV_DEVICE_IDENTIFIER = "dev_env"
            ENV_HOST_IDENTIFIER = "host_env"
            LEXICAL_VAR_PREFIX = "lex_"
        end

        class << self
            def wrap_in_c_block(str)
                "{\n" + str.split("\n").map do |line| "    " + line end.join("\n") + "\n}\n"
            end

            # Reads a CUDA source code file and replaces identifiers by provided substitutes.
            # @param [String] file_name name of source code file
            # @param [Hash{String => String}] replacements replacements
            def read_file(file_name:, replacements: {})
                full_name = Ikra::Configuration.resource_file_name(file_name)
                if !File.exist?(full_name)
                    raise "File does not exist: #{full_name}"
                end

                contents = File.open(full_name, "rb").read

                replacements.each do |s1, s2|
                    replacement = "/*{#{s1}}*/"
                    contents = contents.gsub(replacement, s2)
                end

                contents
            end
        end
    end

    module AST
        module Constants
            SELF_IDENTIFIER = "_self_"
        end
    end
end