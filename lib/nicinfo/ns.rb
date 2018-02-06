# Copyright (C) 2011,2012,2013,2014 American Registry for Internet Numbers
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
require 'nicinfo/entity'
require 'nicinfo/data_tree'

module NicInfo

  def NicInfo.display_ns json_data, config, data_node
    ns = config.factory.new_ns.process( json_data )
    NicInfo::display_object_with_entities( ns, config, data_node )
  end

  def NicInfo.display_nameservers json_data, config, data_node
    ns_array = json_data[ "nameserverSearchResults" ]
    if ns_array != nil
      if ns_array.instance_of? Array
        display_array = Array.new
        ns_array.each do |ea|
          ns = config.factory.new_ns.process( ea )
          display_array << ns
        end
        NicInfo::display_object_with_entities( display_array, config, data_node )
      else
        config.conf_msgs << "'nameserverSearchResults' is not an array"
      end
    else
      config.conf_msgs << "'nameserverSearchResults' is not present"
    end
  end

  # deals with RDAP nameserver structures
  class Ns

    attr_accessor :entities, :objectclass, :asEventActors

    def initialize config
      @config = config
      @common = CommonJson.new config
      @entities = Array.new
      @asEventActors = Array.new
    end

    def process json_data
      @objectclass = json_data
      @entities = @common.process_entities @objectclass
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.data_title "[ NAME SERVER ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @config.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass, "nameserver", @config )
      @config.logger.terse "Host Name", NicInfo::get_ldhName( @objectclass ), NicInfo::AttentionType::SUCCESS
      @config.logger.terse "IDN Host Name", NicInfo::get_unicodeName( @objectclass ), NicInfo::AttentionType::SUCCESS
      ipAddrs = @objectclass[ "ipAddresses" ]
      if ipAddrs
        v6Addrs = ipAddrs[ "v6" ]
        v6Addrs.each do |v6|
          @config.logger.terse "IPv6 Address", v6, NicInfo::AttentionType::SUCCESS
        end if v6Addrs
        v4Addrs = ipAddrs[ "v4" ]
        v4Addrs.each do |v4|
          @config.logger.terse "IPv4 Address", v4, NicInfo::AttentionType::SUCCESS
        end if v4Addrs
      end
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @common.display_port43 @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @config.logger.end_data_item
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
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @config ) ) )
    end

  end

end
