require 'json'
require 'termcolor'
require_relative 'diff_view_utils'

module TopoChecker
  # Topology diff data viewer
  class DiffView
    def to_s
      stringify.gsub!(/:\s+/, ': ').termcolor
    end

    def stringify
      output_strs = stringify_data
      output_strs.flatten.join("\n")
    end

    private

    def stringify_data
      case @data
      when Array then
        [array_bra, stringify_array, array_bra(:end)]
      when Hash then
        # @diff_state is used to decide text color, set at first
        @diff_state = @data['_diff_state_'] if @data.key?('_diff_state_')
        [hash_bra, stringify_hash, hash_bra(:end)]
      end
    end

    def stringify_single_value(value)
      str = value.nil? || value == '' ? '""' : value
      coloring(str)
    end

    def stringify_array_value(value)
      case value
      when Array, Hash then
        dv = DiffView.new(value, @indent_b)
        # stringify array element recursively with deep indent
        dv.stringify
      else
        "#{@indent_b}#{stringify_single_value(value)}"
      end
    end

    def stringify_array
      strs = @data.map do |value|
        stringify_array_value(value)
      end
      strs.join(",\n")
    end

    def empty_value?(value)
      # avoid empty list(or hash)
      # and empty-key hash (that has only diff_state)
      value.empty? || value.is_a?(Hash) \
      && value.key?('_diff_state_') && value.keys.length == 1
    end

    def state_by_stringified_str(str)
      # return nil means set color with self diff_state
      # string doesn't have any color tags, use color as :kept state
      str.match?(%r{<\w+>.*<\/\w+>}) ? nil : :kept
    end

    def stringify_hash_key_array(key, value)
      return nil if empty_value?(value)
      dv = DiffView.new(value, @indent_b)
      v_str = dv.stringify
      # set key color belongs to its value(array)
      v_state = state_by_stringified_str(v_str)
      "#{@indent_b}#{coloring(key, v_state)}: #{v_str}"
    end

    def stringify_hash_key_hash(key, value)
      return nil if empty_value?(value)
      dv = DiffView.new(value, @indent_b)
      # set key color belongs to its value(Hash)
      v_str = dv.stringify # decide dv diff_state before make key str
      "#{@indent_b}#{dv.coloring(key)}: #{v_str}"
    end

    def stringify_hash_key_value(key, value)
      # stringify object recursively with deep indent
      case value
      when Array then stringify_hash_key_array(key, value)
      when Hash then stringify_hash_key_hash(key, value)
      else
        "#{@indent_b}#{coloring(key)}: #{stringify_single_value(value)}"
      end
    end

    def stringify_hash
      keys = @data.keys
      keys.delete('_diff_state_')
      return '' if keys.empty?
      strs = keys.map do |key|
        stringify_hash_key_value(key, @data[key])
      end
      strs.delete(nil) # delete empty value
      strs.join(",\n")
    end
  end
end