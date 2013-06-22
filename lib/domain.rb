# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'config'
require 'nicinfo_logger'
require 'utils'
require 'common_json'
require 'entity'
require 'data_tree'

module NicInfo

  def NicInfo.display_domain json_data, config, data_node
    domain = Domain.new( config ).process( json_data )
    if !domain.entities.empty? or !domain.nameservers.empty?
      root = domain.to_node
      data_node.add_root( root )
      NicInfo::add_entity_nodes( domain.entities, root )
      domain.nameservers.each do |ns|
        ns_node = ns.to_node
        root.add_child( ns_node )
        NicInfo::add_entity_nodes( ns.entities, ns_node )
      end
      data_node.to_normal_log( config.logger, true )
    end
    dispobjs = DisplayObjects.new
    dispobjs.add domain
    NicInfo::add_entity_dispobjs( domain.entities, dispobjs )
    domain.nameservers.each do |ns|
      dispobjs.add ns
      NicInfo::add_entity_dispobjs( ns.entities, dispobjs )
    end
    dispobjs.display
  end

  # deals with RDAP nameserver structures
  class Domain

    attr_accessor :entities, :nameservers

    def initialize config
      @config = config
      @common = CommonJson.new config
      @entities = Array.new
      @nameservers = Array.new
    end

    def process json_data
      @objectclass = json_data
      @entities = @common.process_entities @objectclass
      json_nses = NicInfo::get_nameservers json_data
      json_nses.each do |json_ns|
        ns = Ns.new( @config )
        ns.process( json_ns )
        @nameservers << ns
      end if json_nses
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.data_title "[ DOMAIN ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass )
      @config.logger.terse "Domain Name", NicInfo::get_ldhName( @objectclass )
      @config.logger.datum "I18N Domain Name", NicInfo::get_unicodeName( @objectclass )
      variants = @objectclass[ "variants" ]
      variant_no = 1
      variants.each do |variant|
        relation = variant[ "relation" ]
        item_value = ""
        if relation
          arr = Array.new
          relation.each do |rel|
            arr << NicInfo.capitalize( rel )
          end
          item_value = arr.join( ", " )
        end
        @config.logger.extra "Variant #{variant_no}", item_value
        @config.logger.extra "IDN Table", variant[ "idnTable" ]
        variant_names = variant[ "variantNames" ]
        variant_names.each do |variant_name|
          @config.logger.extra "Variant Domain", NicInfo::get_ldhName( variant_name )
          @config.logger.extra "Variant IDN", NicInfo::get_unicodeName( variant_name )
        end if variant_names
        variant_no = variant_no + 1
      end if variants
      @common.display_public_ids @objectclass
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_entities_as_events @entities
      @common.display_port43 @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @config.logger.end_data_item
      secureDns = @objectclass[ "secureDNS" ]
      if secureDns
        zoneSigned = secureDns[ "zoneSigned" ]
        delegationSigned = secureDns[ "delegationSigned" ]
        maxSigLife = secureDns[ "maxSigLife" ]
        if zoneSigned or delegationSigned or maxSigLife
          @config.logger.start_data_item
          @config.logger.data_title "[ SECURE DNS ]"
          @config.logger.terse "Zone Signed", zoneSigned
          @config.logger.terse "Delegation Signed", delegationSigned
          @config.logger.terse "Max Signature Life", maxSigLife
          @config.logger.end_data_item
        end
        dsData = secureDns[ "dsData" ]
        dsData.each do |ds|
          @config.logger.start_data_item
          @config.logger.data_title "[ DELEGATION SIGNER ]"
          @config.logger.terse "Algorithm", ds[ "algorithm" ]
          @config.logger.terse "Digest", ds[ "digest" ]
          @config.logger.terse "Digest Type", ds[ "digestType" ]
          @config.logger.terse "Key Tag", ds[ "keyTag" ]
          @common.display_events ds
          @config.logger.end_data_item
        end if dsData
        keyData = secureDns[ "keyData" ]
        keyData.each do |key|
          @config.logger.start_data_item
          @config.logger.data_title "[ KEY DATA ]"
          @config.logger.terse "Algorithm", key[ "algorithm" ]
          @config.logger.terse "Flags", key[ "flags" ]
          @config.logger.terse "Protocol", key[ "protocol" ]
          @config.logger.terse "Public Key", key[ "publicKey" ]
          @common.display_events key
          @config.logger.end_data_item
        end if keyData
      end
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      handle = NicInfo::get_ldhName @objectclass if !handle
      handle = "(unidentifiable nameserver #{object_id})" if !handle
      if (name = NicInfo::get_ldhName( @objectclass ) ) != nil
        return "#{name} ( #{handle} )"
      end
      return handle
    end

    def to_node
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass ) ) )
    end

  end

end