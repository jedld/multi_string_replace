require "multi_string_replace/version"
require "multi_string_replace/multi_string_replace"

module MultiStringReplace
end

class String
  ##
  # Exact match replace using the Aho–Corasick algorithm
  # 
  # Args:
  # attrs: Hash - String Key value pairs of characters to search and replace respectively
  def mreplace(attrs = {})
    MultiStringReplace.replace(self, attrs)
  end
end

# Batch helpers for ergonomics and performance
module MultiStringReplace
  def self.batch_match(keys, bodies)
    ac = MultiStringReplace::Automaton.new(keys)
    bodies.map { |b| ac.match(b) }
  end

  def self.batch_replace(bodies, replace)
    ac = MultiStringReplace::Automaton.new(replace.keys)
    bodies.map { |b| ac.replace(b, replace) }
  end
end