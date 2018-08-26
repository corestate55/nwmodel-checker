require_relative 'topo_support_base'

module TopoChecker
  # Termination point reference
  class TpRef < SupportingRefBase
    ATTRS = %i[node_ref tp_ref].freeze
    attr_reader(*ATTRS)
    attr_reader :parent_path

    def initialize(data, parent_path)
      super(:tp_ref, ATTRS)
      @parent_path = parent_path
      @node_ref = data['source-node'] || data['dest-node']
      @tp_ref = data['source-tp'] || data['dest-tp']
    end

    def ref_path
      [@parent_path, @node_ref, @tp_ref].join('/')
    end

    def to_data(direction)
      {
        "#{direction}-node" => @node_ref,
        "#{direction}-tp" => @tp_ref,
        '_diff_state_' => @diff_state.to_data
      }
    end
  end

  # Supporting link for topology link data
  class SupportingLink < SupportingRefBase
    ATTRS = %i[network_ref link_ref].freeze
    attr_reader(*ATTRS)

    def initialize(data)
      super(:link_ref, ATTRS)
      @network_ref = data['network-ref']
      @link_ref = data['link-ref']
    end
  end
end