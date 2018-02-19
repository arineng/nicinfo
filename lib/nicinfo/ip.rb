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

require 'netaddr'

require 'nicinfo/appctx'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'
require 'nicinfo/common_json'
require 'nicinfo/common_summary'
require 'nicinfo/entity'
require 'nicinfo/data_tree'
require 'nicinfo/cidrs'

module NicInfo

  def NicInfo.display_ip json_data, appctx, data_tree
    ip = NicInfo::process_ip( json_data, appctx )
    NicInfo::display_object_with_entities( ip, appctx, data_tree )
  end

  def NicInfo.process_ip( json_data, appctx )
    return appctx.factory.new_ip.process( json_data )
  end

  # deals with RDAP IP network structures
  class Ip

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
      unless common_summary.get_listed_country
        country = @objectclass[ "country" ]
        common_summary.set_listed_country( country ) if country
      end
      @cidr_array = get_cidr_array
      common_summary.meta_data[ NicInfo::CommonSummary::CIDRS ] = @cidr_array
      common_summary.inject
      return self
    end

    def display
      @appctx.logger.start_data_item
      @appctx.logger.data_title "[ IP NETWORK ]"
      @appctx.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass, "ip network", @appctx )
      start_addr = NicInfo.get_startAddress( @objectclass )
      if start_addr.include?( '/' )
        @appctx.conf_msgs << "start IP #{start_addr} is not an IP address (possibly a CIDR)"
      end
      @appctx.logger.terse "Start Address", start_addr , NicInfo::AttentionType::SUCCESS
      end_addr = NicInfo.get_endAddress( @objectclass )
      if end_addr.include?( '/' )
        @appctx.conf_msgs << "end IP #{end_addr} is not an IP address (possibly a CIDR)"
      end
      @appctx.logger.terse "End Address", end_addr, NicInfo::AttentionType::SUCCESS
      @appctx.logger.terse "CIDRs", @cidr_array.join( "," ) if @cidr_array.length > 0
      @appctx.logger.datum "IP Version", @objectclass[ "ipVersion" ]
      @appctx.logger.extra "Name", NicInfo.get_name( @objectclass )
      @appctx.logger.terse "Country", NicInfo.get_country( @objectclass )
      @appctx.logger.datum "Type", NicInfo.get_type( @objectclass )
      @appctx.logger.extra "Parent Handle", @objectclass[ "parentHandle" ]
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @appctx.logger.end_data_item
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

    def get_cidr_array
      cidr_array = []
      startAddress = NicInfo.get_startAddress @objectclass
      endAddress = NicInfo.get_endAddress @objectclass
      if startAddress and endAddress
        cidr_array = find_cidrs(startAddress, endAddress)
      elsif startAddress
        cidr_array << NetAddr::CIDR.create(startAddress).to_s
      elsif endAddress
        cidr_array << NetAddr::CIDR.create(endAddress).to_s
      end
      return cidr_array
    end

    def to_node
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @appctx ) ) )
    end

  end

end
