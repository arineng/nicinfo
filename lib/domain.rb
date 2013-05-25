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
      domain.entities.each do |entity|
        root.add_child( entity.to_node )
      end
      domain.nameservers.each do |ns|
        ns_node = ns.to_node
        root.add_child( ns_node )
        ns.entities.each do |entity|
          ns_node.add_child( entity.to_node )
        end
      end
      data_node.to_normal_log( config.logger, true )
    end
    domain.display
    domain.entities.each do |entity|
      entity.display
    end
    domain.nameservers.each do |ns|
      ns.display
      ns.entities.each do |entity|
        entity.display
      end
    end
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
        variant_names = variant[ "variantNames" ]
        variant_names.each do |variant_name|
          @config.logger.extra "Variant Domain", NicInfo::get_ldhName( variant_name )
          @config.logger.extra "Variant IDN", NicInfo::get_unicodeName( variant_name )
        end if variant_names
        variant_no = variant_no + 1
      end if variants
      delegationKeys = @objectclass[ "delegationKeys" ]
      delegation_no = 1
      delegationKeys.each do |dkey|
        @config.logger.extra "DS #{delegation_no} Algorithm", dkey[ "algorithm" ]
        @config.logger.extra "DS #{delegation_no} Digest", dkey[ "digest" ]
        @config.logger.extra "DS #{delegation_no} Digest Type", dkey[ "digestType" ]
        @config.logger.extra "DS #{delegation_no} Key Tag", dkey[ "keyTag" ]
        delegation_no = delegation_no + 1
      end if delegationKeys
      @common.display_status @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @common.display_events @objectclass
      @common.display_entities_as_events @entities
      @common.display_port43 @objectclass
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      handle = NicInfo::get_ldhName @objectclass if !handle
      handle = "(unidentifiable nameserver)" if !handle
      if (name = NicInfo::get_ldhName( @objectclass ) ) != nil
        return "#{name} ( #{handle} )"
      end
      return handle
    end

    def to_node
      DataNode.new( get_cn, NicInfo::get_self_link( NicInfo::get_links( @objectclass ) ) )
    end

  end

end