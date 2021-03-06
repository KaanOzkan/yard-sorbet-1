# typed: true
# frozen_string_literal: true

# A YARD Handler for Sorbet type declarations
class YARDSorbet::SigHandler < YARD::Handlers::Ruby::Base
  extend T::Sig
  handles :class, :module, :singleton_class?

  sig { returns(String).checked(:never) }
  def process
    # Find the list of declarations inside the class
    class_def = statement.children.find { |c| c.type == :list }
    class_contents = class_def.children

    process_class_contents(class_contents)
  end

  private def process_class_contents(class_contents)
    class_contents.each_with_index do |child, i|
      if child.type == :sclass && child.children.size == 2 && child.children[1].type == :list
        singleton_class_contents = child.children[1]
        process_class_contents(singleton_class_contents)
      end
      next unless type_signature?(child)

      next_statement = class_contents[i + 1]
      next unless processable_method?(next_statement)

      process_method_definition(next_statement, child)
    end
  end

  private def processable_method?(next_statement)
    %i[def defs command].include?(next_statement&.type) && !next_statement.docstring
  end

  private def process_method_definition(method_node, sig_node)
    # Swap the method definition docstring and the sig docstring.
    # Parse relevant parts of the `sig` and include them as well.
    docstring, directives = YARDSorbet::Directives.extract_directives(sig_node.docstring)
    parsed_sig = parse_sig(sig_node)
    enhance_tag(docstring, :abstract, parsed_sig)
    enhance_tag(docstring, :return, parsed_sig)
    if method_node.type != :command
      parsed_sig[:params]&.each do |name, types|
        enhance_param(docstring, name, types)
      end
    end
    method_node.docstring = docstring.to_raw
    YARDSorbet::Directives.add_directives(method_node.docstring, directives)
    sig_node.docstring = nil
  end

  private def enhance_param(docstring, name, types)
    tag = docstring.tags.find { |t| t.tag_name == 'param' && t.name == name }
    if tag
      docstring.delete_tag_if { |t| t == tag }
      tag.types = types
    else
      tag = YARD::Tags::Tag.new(:param, '', types, name)
    end
    docstring.add_tag(tag)
  end

  private def enhance_tag(docstring, type, parsed_sig)
    return if !parsed_sig[type]

    tag = docstring.tags.find { |t| t.tag_name == type.to_s }
    if tag
      docstring.delete_tags(type)
    else
      tag = YARD::Tags::Tag.new(type, '')
    end
    if parsed_sig[type].is_a?(Array)
      tag.types = parsed_sig[type]
    end
    docstring.add_tag(tag)
  end

  private def parse_sig(sig_node)
    parsed = {}
    parsed[:abstract] = false
    parsed[:params] = {}
    found_params = T.let(false, T::Boolean)
    found_return = T.let(false, T::Boolean)
    bfs_traverse(sig_node, exclude: %i[array hash]) do |n|
      if n.source == 'abstract'
        parsed[:abstract] = true
      elsif n.source == 'params' && !found_params
        found_params = true
        sibling = T.must(sibling_node(n))
        bfs_traverse(sibling, exclude: %i[array call hash]) do |p|
          if p.type == :assoc
            param_name = p.children.first.source[0...-1]
            types = YARDSorbet::SigToYARD.convert(p.children.last)
            parsed[:params][param_name] = types
          end
        end
      elsif n.source == 'returns' && !found_return
        found_return = true
        parsed[:return] = YARDSorbet::SigToYARD.convert(T.must(sibling_node(n)))
      elsif n.source == 'void'
        parsed[:return] ||= ['void']
      end
    end
    parsed
  end

  # Returns true if the given node is part of a type signature.
  private def type_signature?(node)
    loop do
      return false if node.nil?
      return false unless %i[call vcall fcall].include?(node.type)
      return true if T.unsafe(node).method_name(true) == :sig

      node = node.children.first
    end
  end

  private def sibling_node(node)
    found_sibling = T.let(false, T::Boolean)
    node.parent.children.each do |n|
      if found_sibling
        return n
      end

      if n == node
        found_sibling = true
      end
    end
    nil
  end

  # @yield [YARD::Parser::Ruby::AstNode]
  private def bfs_traverse(node, exclude: [])
    queue = [node]
    while !queue.empty?
      n = T.must(queue.shift)
      yield n
      n.children.each do |c|
        if !exclude.include?(c.type)
          queue.push(c)
        end
      end
    end
  end
end
