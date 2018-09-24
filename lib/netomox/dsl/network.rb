require 'netomox/const'
require 'netomox/dsl/base'
require 'netomox/dsl/network_attr'
require 'netomox/dsl/node'
require 'netomox/dsl/link'

module Netomox
  module DSL
    # supporting network container
    class SupportNetwork
      def initialize(nw_ref)
        @nw_ref = nw_ref
      end

      def topo_data
        { 'network-ref' => @nw_ref }
      end
    end

    # network, node and link container
    class Network < DSLObjectBase
      def initialize(parent, name, &block)
        super(parent, name)
        @type = {}
        @nodes = []
        @links = []
        @supports = [] # supporting network
        @attribute = {} # for augments
        register(&block) if block_given?
      end

      def type(type = nil)
        if type
          @type[type] = {} ## TODO recursive type definition
        else
          @type # called as attr_reader
        end
      end

      def support(nw_ref)
        @supports.push(SupportNetwork.new(nw_ref))
      end

      def attribute(attr)
        @attribute = if @type.key?(NWTYPE_L2)
                       L2NWAttribute.new(attr)
                     elsif @type.key?(NWTYPE_L3)
                       L3NWAttribute.new(attr)
                     else
                       {}
                     end
      end

      def node(name, &block)
        node = find_node(name)
        if node
          node.register(&block) if block_given?
        else
          node = Node.new(self, name, &block)
          @nodes.push(node)
        end
        node
      end

      # make uni-directional link
      def link(src_node, src_tp = false,
               dst_node = false, dst_tp = false, &block)
        args = normalize_link_args(src_node, src_tp, dst_node, dst_tp)
        link = find_link(args.join(','))
        if link
          link.register(&block) if block_given?
        else
          link = Link.new(self, args[0], args[1], args[2], args[3], &block)
          @links.push(link)
        end
        link
      end

      # make bi-directional link
      # TODO: supporting-link implementation
      def bdlink(src_node, src_tp = false,
                 dst_node = false, dst_tp = false, &block)
        args = normalize_link_args(src_node, src_tp, dst_node, dst_tp)
        link(args[0], args[1], args[2], args[3], &block)
        link(args[2], args[3], args[0], args[1], &block)
      end

      # rubocop:disable Metrics/MethodLength
      def topo_data
        data = {
          'network-id' => @name,
          'network-types' => @type,
          'node' => @nodes.map(&:topo_data),
          "#{NS_TOPO}:link" => @links.map(&:topo_data)
        }
        unless @supports.empty?
          data['supporting-network'] = @supports.map(&:topo_data)
        end
        data[@attribute.type] = @attribute.topo_data unless @attribute.empty?
        data
      end
      # rubocop:enable Metrics/MethodLength

      private

      def normalize_link_args(src_node, src_tp = false,
                              dst_node = false, dst_tp = false)
        case src_node
        when Array
          # with 1 arg (with an array)
          src_node
        else
          # with 4 args
          [src_node, src_tp, dst_node, dst_tp]
        end
      end

      def find_node(name)
        @nodes.find { |node| node.name == name }
      end

      def find_link(name)
        @links.find { |link| link.name == name }
      end
    end
  end
end
