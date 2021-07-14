# frozen_string_literal: true
require 'pry'
class FastIgnore
  module GlobalGitignore
    class << self
      def path(root:)
        gitconfig_gitignore_path(::File.expand_path('.git/config', root)) ||
          gitconfig_gitignore_path(::File.expand_path('~/.gitconfig')) ||
          gitconfig_gitignore_path(xdg_config_path) ||
          gitconfig_gitignore_path('/etc/gitconfig') ||
          default_global_gitignore_path
      end

      private

      def gitconfig_gitignore_path(config_path)
        return unless config_path
        return unless ::File.exist?(config_path)

        ignore_path = config_value(config_path)
        return unless ignore_path

        ignore_path.strip!
        return '' if ignore_path.empty? # don't expand path in this case

        ::File.expand_path(ignore_path)
      end

      def xdg_config_path
        xdg_config_home? && ::File.expand_path('git/config', xdg_config_home)
      end

      def default_global_gitignore_path
        if xdg_config_home?
          ::File.expand_path('git/ignore', xdg_config_home)
        else
          ::File.expand_path('~/.config/git/ignore')
        end
      end

      def config_value(path)
        puts ::File.readlines(path).inspect
        ::File.read(path).find do |line|
          if line.sub!(/\A\s*excludesfile\s*=\s*/, '')
            # quoted value or unquoted value (value within quote is allowed to be preceded by an odd number of backslashes)
            # quotes can include comment characters, unquoted strings can't.
            # quotes are just another type of escaping that can be introduced at any time
            # single quotes are literal
            line.scan(/(?:"(?<quoted>(?:[^"]|\\(?:\\\\)*")*")|(?<unquoted>[^;#]|\\(?:\\\\)*"))/) { |quoted, unquoted| }
            return match[0] # intentional early return from find
          end
        end
      end

      def xdg_config_home
        ::ENV['XDG_CONFIG_HOME']
      end

      def xdg_config_home?
        xdg_config_home && (not xdg_config_home.empty?)
      end
    end
  end
end
