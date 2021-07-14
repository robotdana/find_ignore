require 'strscan'
require 'pry'
class FastIgnore
  class GitconfigParser
    def self.parse(file, root: Dir.pwd)
      new(file, root: root).parse
    end

    def initialize(path, root: Dir.pwd)
      @path = path
      @root = root
    end

    def parse
      read_file(path)
      return if invalid
      return if value.empty?

      value
    end

    private

    attr_reader :file
    attr_accessor :value, :within_quotes, :invalid, :section

    def read_file(path)
      return unless ::File.readable?(path)
      file = StringScanner.new(::File.read(path))

      until file.eos?
        if invalid
          break
        elsif file.skip(/(\s+|[#;].*\n)/)
          # skip
        elsif file.skip(/\[core\]/)
          self.section = :core
        elsif file.skip(/\[include\]/)
          self.section = :include
        elsif file.skip(/\[includeIf "onbranch:/)
          if file.scan(/([^\0\\"]|\\(\\{2})*"|\\{2}*)+(?="\])/)
            self.section = on_branch?(file.matched) ? :include : :not_include
            file.skip(/"\]/)
          else
            self.invalid = true
          end
        elsif file.skip(/\[includeIf "gitdir:/)
          if file.scan(/([^\0\\"]|\\(\\{2})*"|\\{2}*)+(?="\])/)
            self.section = gitdir?(file.matched, path: path) ? :include : :not_include
            file.skip(/"\]/)
          else
            self.invalid = true
          end
        elsif file.skip(/\[includeIf "gitdir/i:/)
          if file.scan(/([^\0\\"]|\\(\\{2})*"|\\{2}*)+(?="\])/)
            self.section = gitdir?(file.matched, ::File::FNM_CASEFOLD, path: path) ? :include : :not_include
            file.skip(/"\]/)
          else
            self.invalid = true
          end
        elsif file.skip(/\[[\w.]+( "([^\0\\"]|\\(\\{2})*"|\\{2}*)+")?\]/)
          self.section = :other
        elsif section == :core && file.skip(/excludesfile\s*=(\s|\\\n)*/)
          self.value = scan_value(file)
          break if invalid
        elsif section == :include && file.skip(/path\s*=(\s|\\\n)*/)
          include_path = scan_value(file)
          break if invalid
          read_file(::File.expand_path(include_path, path))
          self.section = :include
        elsif file.skip(/[a-zA-Z0-9]\w*\s*([#;].*)?\n/)
        elsif file.skip(/[a-zA-Z0-9]\w*\s*=(\s|\\\n)*/)
          skip_value(file)
        else
          self.invalid = true
          break
        end
      end
    end

    def on_branch?(branch_pattern)
      branch_pattern += '**' if branch_pattern.end_with?('/')
      current_branch = ::File.readable?("#{root}/.git/HEAD") && ::File.read("#{root}/.git/HEAD").sub!(/\Aref: refs\/heads\//, '')
      return unless current_branch

      # goddamit git what does 'a pattern with standard globbing wildcards' mean
      ::File.fnmatch(branch_pattern, current_branch, ::File::FNM_PATHNAME | ::File::FNM_DOTMATCH)
    end

    def gitdir?(gitdir, options = 0, path:)
      gitdir.delete_suffix!('/.git')
      gitdir += '**' if gitdir.endwith?('/')
      gitdir.sub!(/\A~\//, ENV['HOME'] + "/")
      gitdir.sub!(/\A\./, path + "/")
      gitdir = "**/#{gitdir}" unless gitdir.start_with?('/')

      ::File.fnmatch(gitdir, root, options | ::File::FNM_PATHNAME | ::File::FNM_DOTMATCH)
    end

    def scan_value
      value = +''
      until file.eos?
        if invalid
          break
        elsif file.skip(/\\\n/)
          # continue
        elsif file.skip(%r{\\\\})
          value << '\\'
        elsif file.skip(/\\n/)
          value << "\n"
        elsif file.skip(/\\t/)
          value << "\t"
        elsif file.skip(/\\b/)
          value.chop!
        elsif file.skip(/\\"/)
          value << '"'
        elsif file.skip(%r{\\})
          self.invalid = true
        elsif within_quotes
          if file.skip(/"/)
            self.within_quotes = false
          elsif file.scan(/[^"\\]+/)
            value << file.matched
          elsif file.skip(/\n/)
            self.invalid = true
          else
            raise file.rest
          end
        elsif file.skip(/"/)
          self.within_quotes = true
        elsif file.scan(/[^;#"\s\\]+/)
          value << file.matched
        elsif file.skip(/\s*[;#\n]/)
          break
        elsif file.scan(/\s+/)
          value << file.matched
        else
          raise file.rest
        end
      end
      value
    end

    def skip_value
      until file.eos?
        if file.skip(/\\(?:\n|\\|n|t|b|")/)
        elsif file.skip(%r{\\})
          self.invalid = true
          break
        elsif within_quotes
          if file.skip(/"/)
            self.within_quotes = false
          elsif file.skip(/[^"\\]+/)
          elsif file.scan(/\n/)
            self.invalid = true
            break
          else raise file.rest
          end
        elsif file.skip(/"/)
          self.within_quotes = true
        elsif file.skip(/[^;#"\s\\]+/)
        elsif file.skip(/\s*[;#\n]/)
          break
        elsif file.skip(/\s+/)
        else
          raise file.rest
        end
      end
    end
  end
end
