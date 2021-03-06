# frozen_string_literal: true

class FastIgnore
  class RuleSet
    attr_reader :gitignore
    alias_method :gitignore?, :gitignore
    undef :gitignore

    def initialize(rules, allow, gitignore, squash = true)
      @dir_rules = (squash ? squash_rules(rules.reject(&:file_only?)) : rules.reject(&:file_only?)).freeze
      @file_rules = (squash ? squash_rules(rules.reject(&:dir_only?)) : rules.reject(&:dir_only?)).freeze
      @has_shebang_rules = rules.any?(&:shebang?)

      @allowed_recursive = { '.' => true }
      @allow = allow
      @gitignore = gitignore

      freeze unless gitignore?
    end

    def <<(other)
      return unless other

      @has_shebang_rules ||= other.has_shebang_rules
      @dir_rules = squash_rules(@dir_rules + other.dir_rules)
      @file_rules = squash_rules(@file_rules + other.file_rules)
    end

    def allowed_recursive?(relative_path, dir, full_path, filename, content = nil)
      @allowed_recursive.fetch(relative_path) do
        @allowed_recursive[relative_path] =
          allowed_recursive?(::File.dirname(relative_path), true, nil, nil, nil) &&
          allowed_unrecursive?(relative_path, dir, full_path, filename, content)
      end
    end

    def allowed_unrecursive?(relative_path, dir, full_path, filename, content)
      (dir ? @dir_rules : @file_rules).reverse_each do |rule|
        return rule.negation? if rule.match?(relative_path, full_path, filename, content)
      end

      not @allow
    end

    def squash_rules(rules) # rubocop:disable Metrics/MethodLength
      running_component_rule_size = rules.first&.component_rules_count || 0
      rules.chunk_while do |a, b|
        # a.squashable_type == b.squashable_type
        next true if a.squashable_type == b.squashable_type &&
          (running_component_rule_size + b.component_rules_count <= 40)

        running_component_rule_size = b.component_rules_count
        false
      end.map do |chunk| # rubocop:disable Style/MultilineBlockChain
        first = chunk.first
        next first if chunk.length == 1

        first.squash(chunk)
      end
    end

    def weight
      @dir_rules.length + (@has_shebang_rules ? 10 : 0)
    end

    def empty?
      @dir_rules.empty? && @file_rules.empty?
    end

    protected

    attr_reader :dir_rules
    attr_reader :file_rules
    attr_reader :has_shebang_rules
  end
end
