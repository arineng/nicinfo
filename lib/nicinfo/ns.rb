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
require 'nicinfo/data_tree'

module NicInfo

  def NicInfo.display_ns json_data, appctx, data_node
    ns = appctx.factory.new_ns.process( json_data )
    NicInfo::display_object_with_entities( ns, appctx, data_node )
  end

  def NicInfo.display_nameservers json_data, appctx, data_node
    ns_array = json_data[ "nameserverSearchResults" ]
    if ns_array != nil
      if ns_array.instance_of? Array
        display_array = Array.new
        ns_array.each do |ea|
          ns = appctx.factory.new_ns.process( ea )
          display_array << ns
        end
        NicInfo::display_object_with_entities( display_array, appctx, data_node )
      else
        appctx.conf_msgs << "'nameserverSearchResults' is not an array"
      end
    else
      appctx.conf_msgs << "'nameserverSearchResults' is not present"
    end
  end

  def NicInfo.process_ns( json_data, appctx )
    return appctx.factory.new_ns.process( json_data )
  end

  # deals with RDAP nameserver structures
  class Ns

    attr_accessor :entities, :objectclass, :asEventActors

    def initialize appctx
      @appctx = appctx
      @common = CommonJson.new appctx
      @entities = Array.new
      @asEventActors = Array.new
    end

    def process json_data
      @objectclass = json_data
      @entities = @common.process_entities @objectclass
      common_summary = CommonSummary.new(@objectclass, @entities, @appctx )
      common_summary.inject
      return self
    end

    def display
      @appctx.logger.start_data_item
      @appctx.logger.data_title "[ NAME SERVER ]"
      @appctx.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass, "nameserver", @appctx )
      @appctx.logger.terse "Host Name", NicInfo::get_ldhName( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.terse "IDN Host Name", NicInfo::get_unicodeName( @objectclass ), NicInfo::AttentionType::SUCCESS
      ipAddrs = @objectclass[ "ipAddresses" ]
      if ipAddrs
        v6Addrs = ipAddrs[ "v6" ]
        v6Addrs.each do |v6|
          @appctx.logger.terse "IPv6 Address", v6, NicInfo::AttentionType::SUCCESS
        end if v6Addrs
        v4Addrs = ipAddrs[ "v4" ]
        v4Addrs.each do |v4|
          @appctx.logger.terse "IPv4 Address", v4, NicInfo::AttentionType::SUCCESS
        end if v4Addrs
      end
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @common.display_port43 @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @appctx.logger.end_data_item
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
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @appctx ) ) )
    end

  end

end
