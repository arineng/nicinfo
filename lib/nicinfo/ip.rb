# Copyright (C) 2011-2017 American Registry for Internet Numbers
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

require 'netaddr'

require 'nicinfo/config'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'
require 'nicinfo/common_json'
require 'nicinfo/entity'
require 'nicinfo/data_tree'
require 'nicinfo/cidrs'

module NicInfo

  def NicInfo.display_ip json_data, config, data_tree
    ip = config.factory.new_ip.process( json_data )
    NicInfo::display_object_with_entities( ip, config, data_tree )
  end

  # deals with RDAP IP network structures
  class Ip

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
      @config.logger.data_title "[ IP NETWORK ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @config.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass )
      start_addr = NicInfo.get_startAddress( @objectclass )
      if start_addr.include?( '/' )
        @config.conf_msgs << "start IP #{start_addr} is not an IP address (possibly a CIDR)"
      end
      @config.logger.terse "Start Address", start_addr , NicInfo::AttentionType::SUCCESS
      end_addr = NicInfo.get_endAddress( @objectclass )
      if end_addr.include?( '/' )
        @config.conf_msgs << "end IP #{end_addr} is not an IP address (possibly a CIDR)"
      end
      @config.logger.terse "End Address", end_addr, NicInfo::AttentionType::SUCCESS
      @config.logger.terse "CIDRs", get_CIDRs
      @config.logger.datum "IP Version", @objectclass[ "ipVersion" ]
      @config.logger.extra "Name", NicInfo.get_name( @objectclass )
      @config.logger.terse "Country", NicInfo.get_country( @objectclass )
      @config.logger.datum "Type", NicInfo.get_type( @objectclass )
      @config.logger.extra "Parent Handle", @objectclass[ "parentHandle" ]
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      if !handle
        startAddress = NicInfo.get_startAddress @objectclass
        handle << startAddress if startAddress
        endAddress = NicInfo.get_endAddress @objectclass
        handle << " - " if startAddress and endAddress
        handle << endAddress if endAddress
      end
      return handle if handle
      return "(unidentifiable network #{object_id})"
    end

    def get_CIDRs
      startAddress = NicInfo.get_startAddress @objectclass
      endAddress = NicInfo.get_endAddress @objectclass
      if startAddress and endAddress
        cidrs = find_cidrs(startAddress, endAddress)
        return cidrs.join(', ')
      elsif startAddress
        return NetAddr::CIDR.create(startAddress).to_s
      elsif endAddress
        return NetAddr::CIDR.create(endAddress).to_s
      else
        return ""
      end
    end

    def to_node
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @config ) ) )
    end

  end

end
