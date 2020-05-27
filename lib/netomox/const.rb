# frozen_string_literal: true

module Netomox
  NS_NW = 'ietf-network'
  NS_TOPO = 'ietf-network-topology'
  NS_L2NW = 'ietf-l2-topology'
  NS_L3NW = 'ietf-l3-unicast-topology'
  NWTYPE_L2 = "#{NS_L2NW}:l2-network"
  NWTYPE_L3 = "#{NS_L3NW}:l3-unicast-topology"
  NWTYPE_MP = "multi-purpose-topology"
end
