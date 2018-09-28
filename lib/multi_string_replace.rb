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