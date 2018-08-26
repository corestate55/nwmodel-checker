require_relative 'topo_diff_state'

module TopoChecker
  # Diff function Mix-in, forward check functions
  # NOTICE: who receive the method? (receiver?)
  # when (a) - (b) => (c)
  module TopoDiff
    def diff_supports(other)
      # receiver of this method will be (a), other will be (b)
      diff_list(:supports, other)
    end

    def diff_attribute(other)
      # receiver of this method will be (a), other will be (b)
      result = diff_single_value(@attribute, other.attribute)
      arg = { forward: result, pair: @attribute }
      other.attribute.diff_state = DiffState.new(arg)
      other.attribute
    end

    def diff_forward_check_of(attr, other)
      # receiver of this method will be (a), other will be (b)
      obj_diff = diff_list(attr, other)
      obj_diff.map do |od|
        if od.diff_state.forward == :kept
          # take diff for kept(or changed) object recursively
          lhs = od.diff_state.pair
          lhs.diff(od)
        else
          # mark all child attr by diff_state itself recursively
          od.fill_diff_state
          od # must return itself
        end
      end
    end

    private

    def fill_diff_state_of(attrs)
      attrs.each do |attr|
        case send(attr)
        when Array then
          fill_array_diff_state(send(attr))
        else
          set_diff_state(send(attr), forward: @diff_state.forward)
        end
      end
    end

    def fill_array_diff_state(child_array)
      child_array.each do |child|
        set_diff_state(child, forward: @diff_state.forward)
        child.fill_diff_state # recursive state marking
      end
    end

    def diff_list(attr, other)
      results = []
      send(attr).each do |lhs|
        rhs = other.send(attr).find { |r| lhs == r }
        # kept when lhs found in rhs or deleted when not found
        results.push(select_diff_list(lhs, rhs))
      end
      other.send(attr).each do |rhs|
        next if send(attr).find { |l| rhs == l }
        # rhs only in other -> added
        results.push(set_diff_state(rhs, forward: :added))
      end
      results
    end

    def select_diff_list(lhs, rhs)
      if rhs
        # lhs found in rhs -> kept
        set_diff_state(rhs, forward: :kept, pair: lhs)
      else
        # lhs only in self -> deleted
        set_diff_state(lhs, forward: :deleted)
      end
    end

    def set_diff_state(rlhs, state_hash)
      rlhs.diff_state = DiffState.new(state_hash)
      rlhs # set diff state and return itself
    end

    def diff_single_value(lhs, rhs)
      if lhs == rhs
        :kept
      elsif lhs.empty?
        :added
      elsif rhs.empty?
        :deleted
      else
        :changed
      end
    end
  end
end