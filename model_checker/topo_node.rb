require_relative 'topo_const'
require_relative 'topo_tp'
require_relative 'topo_support_base'
require_relative 'topo_node_attr'
require_relative 'topo_base'

module TopoChecker
  # Node for topology data
  class Node < TopoObjectBase
    attr_accessor :termination_points

    def initialize(data, parent_path)
      super(data['node-id'], parent_path)
      setup_termination_points(data)
      setup_supports(data, 'supporting-node', SupportingNode)
      key_klass_list = [
        { key: "#{NS_L2NW}:l2-node-attributes", klass: L2NodeAttribute },
        { key: "#{NS_L3NW}:l3-node-attributes", klass: L3NodeAttribute }
      ]
      setup_attribute(data, key_klass_list)
    end

    def diff(other)
      # forward check
      d_node = Node.new({ 'node-id' => @name }, @parent_path)
      attr = :termination_points
      d_node.termination_points = diff_forward_check_of(attr, other)
      d_node.supports = diff_supports(other)
      d_node.attribute = diff_attribute(other)
      d_node.diff_state = @diff_state
      # backward check
      d_node.diff_backward_check(%i[termination_points supports attribute])
      # return
      d_node
    end

    def fill_diff_state
      fill_diff_state_of(%i[termination_points supports attribute])
    end

    def to_s
      "node:#{@name}"
    end

    def to_data
      {
        'node-id' => @name,
        '_diff_state_' => @diff_state.to_data,
        "#{NS_TOPO}:termination-point" => @termination_points.map(&:to_data),
        'supporting-node' => @supports.map(&:to_data),
        @attribute.type => @attribute.to_data
      }
    end

    private

    def setup_termination_points(data)
      @termination_points = []
      tp_key = "#{NS_TOPO}:termination-point"
      return unless data.key?("#{NS_TOPO}:termination-point")
      @termination_points = data[tp_key].map do |tp|
        create_termination_point(tp)
      end
    end

    def create_termination_point(data)
      TerminationPoint.new(data, @path)
    end
  end
end
