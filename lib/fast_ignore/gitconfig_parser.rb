require 'strscan'
require 'pry'
class FastIgnore
  class GitconfigParser
    def self.parse(file)
      new(file).parse
    end
    def initialize(file)
      @file = StringScanner.new(file)
      @value = +''
      @within_quotes = false
      @escaped_prev_character = false
    end

    def parse
      read_file

      return if value.empty?
      return if within_quotes || invalid

      value
    end

    private

    attr_reader :file
    attr_accessor :value, :within_quotes, :invalid, :core

    def read_file
      until file.eos?
        if file.skip(/(\s+|[#;].*\n)/)
          # skip
        elsif file.skip(/\[core\]/)
          self.core = true
        elsif file.skip(/\[[\w.]+( "([^\0\\"]|\\(\\{2})*"|\\{2}*)+")?\]/)
          self.core = false
        elsif core && file.skip(/excludesfile\s*=(\s|\\\n)*/)
          scan_value
          break if invalid
        elsif file.skip(/[a-zA-Z0-9]\w*\s*([#;].*)?\n/)
        elsif file.skip(/[a-zA-Z0-9]\w*\s*=(\s|\\\n)*/)
          skip_value
          break if invalid
        else
          self.invalid = true
          break
        end
      end
    end

    def scan_value
      until file.eos?
        if file.skip(/\\\n/)
          # continue
        elsif file.skip(%r{\\\\})
          self.value << '\\'
        elsif file.skip(/\\n/)
          self.value << "\n"
        elsif file.skip(/\\t/)
          self.value << "\t"
        elsif file.skip(/\\b/)
          self.value.chop!
        elsif file.skip(/\\"/)
          self.value << '"'
        elsif file.skip(%r{\\})
          self.invalid = true
          break
        elsif within_quotes
          if file.skip(/"/)
            self.within_quotes = false
          elsif file.scan(/[^"\\]+/)
            self.value << file.matched
          elsif file.skip(/\n/)
            self.invalid = true
            break
          else
            raise file.rest
          end
        elsif file.skip(/"/)
          self.within_quotes = true
        elsif file.scan(/[^;#"\s\\]+/)
          self.value << file.matched
        elsif file.skip(/\s*[;#\n]/)
          break
        elsif file.scan(/\s+/)
          self.value << file.matched
        else
          raise file.rest
        end
      end
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
