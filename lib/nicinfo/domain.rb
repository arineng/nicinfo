# Copyright (C) 2011-2018 American Registry for Internet Numbers
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

require 'nicinfo/appctx'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'
require 'nicinfo/common_json'
require 'nicinfo/common_summary'
require 'nicinfo/entity'
require 'nicinfo/ns'
require 'nicinfo/ds_data'
require 'nicinfo/key_data'
require 'nicinfo/data_tree'

module NicInfo

  def NicInfo.display_domain json_data, appctx, data_node
    obj_array = json_data
    unless json_data.instance_of? Array
      obj_array = Array.new
      obj_array << json_data
    end
    respObjs = ResponseObjSet.new appctx
    obj_array.each do |array_object|
      domain = appctx.factory.new_domain.process( array_object )
      root = domain.to_node
      data_node.add_root( root )
      if !domain.entities.empty? or !domain.nameservers.empty?
        domain.ds_data_objs.each do |ds|
          ds_node = ds.to_node
          root.add_child( ds_node )
        end
        domain.key_data_objs.each do |key|
          key_node = key.to_node
          root.add_child( key_node )
        end
        NicInfo::add_entity_nodes( domain.entities, root )
        domain.nameservers.each do |ns|
          ns_node = ns.to_node
          root.add_child( ns_node )
          NicInfo::add_entity_nodes( ns.entities, ns_node )
        end
      end
      if domain.network
        net_node = domain.network.to_node
        root.add_child net_node
        NicInfo::add_entity_nodes( domain.network.entities, net_node )
      end
      respObjs.add domain
      domain.ds_data_objs.each do |ds|
        respObjs.add ds
      end
      domain.key_data_objs.each do |key|
        respObjs.add key
      end
      NicInfo::add_entity_respobjs( domain.entities, respObjs )
      respObjs.associateEntities domain.entities
      domain.nameservers.each do |ns|
        respObjs.add ns
        NicInfo::add_entity_respobjs( ns.entities, respObjs )
        respObjs.associateEntities ns.entities
      end
      if domain.network
        respObjs.add domain.network
        NicInfo::add_entity_respobjs( domain.network.entities, respObjs )
      end
    end
    data_node.to_normal_log( appctx.logger, true )
    respObjs.display
  end

  def NicInfo.display_domains json_data, appctx, data_tree
    domain_array = json_data[ "domainSearchResults" ]
    if domain_array != nil
      if domain_array.instance_of? Array
        NicInfo.display_domain( domain_array, appctx, data_tree )
      else
        appctx.conf_msgs << "'domainSearchResults' is not an array"
      end
    else
      appctx.conf_msgs << "'domainSearchResults' is not present"
    end
  end

  def NicInfo.process_domain( json_data, appctx )
    return appctx.factory.new_domain.process( json_data )
  end

  # deals with RDAP nameserver structures
  class Domain

    attr_accessor :entities, :nameservers, :ds_data_objs, :key_data_objs, :objectclass, :asEventActors, :network

    def initialize appctx
      @appctx = appctx
      @common = CommonJson.new appctx
      @entities = Array.new
      @asEventActors = Array.new
      @nameservers = Array.new
      @ds_data_objs = Array.new
      @key_data_objs = Array.new
    end

    def process json_data
      @objectclass = json_data
      @entities = @common.process_entities @objectclass
      json_nses = NicInfo::get_nameservers json_data
      json_nses.each do |json_ns|
        ns = @appctx.factory.new_ns
        ns.process( json_ns )
        @nameservers << ns
      end if json_nses
      json_net = NicInfo::get_network json_data
      if json_net
        ip = @appctx.factory.new_ip
        ip.process json_net
        @network = ip
      end
      json_ds_data_objs = NicInfo::get_ds_data_objs @objectclass
      json_ds_data_objs.each do |json_ds|
        dsData = DsData.new( @appctx )
        dsData.process( json_ds )
        @ds_data_objs << dsData
      end if json_ds_data_objs
      json_key_data_objs = NicInfo::get_key_data_objs @objectclass
      json_key_data_objs.each do |json_key|
        keyData = KeyData.new( @appctx )
        keyData.process( json_key )
        @key_data_objs << keyData
      end if json_key_data_objs
      common_summary = CommonSummary.new(@objectclass, @entities, @appctx )
      nsldh = []
      @nameservers.each do |ns|
        nsldh << NicInfo::get_ldhName( ns.objectclass )
      end
      common_summary.summary_data[NicInfo::CommonSummary::NAMESERVERS ] = nsldh
      registrar = common_summary.find_entity_by_role( @entities, "registrar" )
      common_summary.summary_data[NicInfo::CommonSummary::REGISTRAR ] = registrar.get_cn if registrar
      common_summary.inject
      return self
    end

    def display
      @appctx.logger.start_data_item
      @appctx.logger.data_title "[ DOMAIN ]"
      @appctx.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass, "domain", @appctx )
      @appctx.logger.terse "Domain Name", NicInfo::get_ldhName( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.datum "I18N Domain Name", NicInfo::get_unicodeName( @objectclass ), NicInfo::AttentionType::SUCCESS
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
        @appctx.logger.extra "Variant #{variant_no}", item_value
        @appctx.logger.extra "IDN Table", variant[ "idnTable" ]
        variant_names = variant[ "variantNames" ]
        variant_names.each do |variant_name|
          @appctx.logger.extra "Variant Domain", NicInfo::get_ldhName( variant_name )
          @appctx.logger.extra "Variant IDN", NicInfo::get_unicodeName( variant_name )
        end if variant_names
        variant_no = variant_no + 1
      end if variants
      @common.display_public_ids @objectclass
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @common.display_port43 @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      secure_dns = NicInfo::get_secure_dns( @objectclass )
      if secure_dns.instance_of? Array
        secure_dns = secure_dns[ 0 ]
      end
      if secure_dns
        @appctx.logger.terse "Zone Signed", secure_dns[ "zoneSigned" ]
        @appctx.logger.terse "Delegation Signed", secure_dns[ "delegationSigned" ]
        @appctx.logger.terse "Max Signature Life", secure_dns[ "maxSigLife" ]
      end
      @appctx.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      handle = NicInfo::get_ldhName @objectclass if !handle
      handle = "(unidentifiable domain #{object_id})" if !handle
      if (name = NicInfo::get_ldhName( @objectclass ) ) != nil
        return "#{name} ( #{handle} )"
      end
      return handle
    end

    def to_node
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @appctx ) ) )
    end

  end

end
