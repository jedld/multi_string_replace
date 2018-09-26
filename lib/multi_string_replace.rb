require "multi_string_replace/version"
require 'pry-byebug'
require "multi_string_replace/multi_string_replace"

module MultiStringReplace
  class Substitution
    class Preparsed
      def initialize(body, replace)
        @body = body
        @replace = replace
      end

      def process(replacements = {})
        s = ""
        cur_index = 0
        body_ptr = 0
        lookup = replacements.collect { |k,v| [k.to_sym, v] }.to_h
  
        while body_ptr < @body.size
          target_index, end_index, lookup_key = @replace[cur_index]
          if body_ptr == target_index
            s << lookup[lookup_key]
            body_ptr = end_index + 1
            cur_index += 1
          else
            s << @body[body_ptr]
            body_ptr += 1
          end
        end
        s
      end
    end

    class Node
      attr_accessor :children, :other_children, :value, :name, :prefix

      def initialize
        @children = {}
        @other_children = {}
      end

      def children_size
        children.size + other_children.size
      end
    end

    ##
    # Creates a substitution object
    #
    # Args:
    # keys: Array - Array of unique strings to index in a text body
    def initialize(keys)
      @keys = keys
      @head = build_trie_structure(keys)
    end

    ##
    # Parse body, and replace given key instances with replacements
    def process(body, replacements = {})
      _indexes, replace = preparse(body)
      Preparsed.new(body, replace).process(replacements)
    end

    def for(body)
      _indexes, replace = preparse(body)
      Preparsed.new(body, replace)
    end

    def match(body)
      indexes, _replace = preparse(body)
      indexes
    end
  
    private

    def preparse(body)
      current_ptr = @head
      word_indexes = {}
      replace = []
      @keys.each { |k| word_indexes[k] = [] }

      body.each_char.with_index do |c, index|
        current_ptr = if current_ptr.children.key?(c)
                        current_ptr.children[c]
                      elsif current_ptr.other_children.key?(c)
                        current_ptr.other_children[c]
                      else
                        @head
                      end

        if current_ptr.name
          match_index = index - current_ptr.name.size + 1
          word_indexes[current_ptr.name] << match_index
          replace << [match_index, index, current_ptr.name.to_sym]
        end
      end

      [word_indexes, replace]
    end

    def print(node, level = 0, _printed = [])
      padding = "  " * level

      # return if _printed.include?(node)
      _printed << node
  
      node.children.each do |k, node|
        if _printed.include?(node)
          puts "#{padding}#{node.value}:#{node.name}:#{node.children_size}*"
        else
          puts "#{padding}#{node.value}:#{node.name}:#{node.children_size}"
        end

        next if _printed.include?(node)
        print(node, level + 1, _printed)
      end
    end

    def build_trie_structure(keys)
      root = Node.new
      keys.uniq.each do |key|
        add_word(root, key)
      end

      root.children.values.each do |c|
        add_parent_links(root, c)
      end

      root
    end

    def add_word(root, word)
      ptr = root
      prefix = ""
      word.each_char do |c|
        prefix += c
        if ptr.children.key?(c)
          ptr = ptr.children[c]
        else
          new_node = Node.new
          new_node.value = c
          new_node.prefix = prefix
          ptr.children[c] = new_node
          ptr = new_node
        end
      end

      ptr.name = word
    end

    def add_parent_links(root, node)
      root.children.each do |k, root_child|
        if !node.children.key?(k)
          node.other_children[k] = root_child
        end
      end

      node.children.values.each do |child|
        add_parent_links(root, child)
      end
    end
  end
end
