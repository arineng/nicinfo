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

  def NicInfo.display_ip json_data, config, data_tree
    ip = Ip.new( config ).process( json_data )
    NicInfo::display_object_with_entities( ip, config, data_tree )
  end

  # deals with RDAP IP network structures
  class Ip

    attr_accessor :entities

    def initialize config
      @config = config
      @common = CommonJson.new config
      @entities = Array.new
    end

    def process json_data
      @objectclass = json_data
      @entities = @common.process_entities @objectclass
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass )
      @config.logger.terse "Start Address", NicInfo.get_startAddress( @objectclass )
      @config.logger.terse "End Address", NicInfo.get_endAddress( @objectclass )
      @config.logger.datum "IP Version", @objectclass[ "ipVersion" ]
      @config.logger.extra "Name", NicInfo.get_name( @objectclass )
      @config.logger.terse "Country", NicInfo.get_country( @objectclass )
      @config.logger.datum "Type", NicInfo.get_type( @objectclass )
      @config.logger.extra "Parent Handle", @objectclass[ "parentHandle" ]
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_entities_as_events @entities
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
      return "(unidentifiable network)"
    end

    def to_node
      DataNode.new( get_cn, NicInfo::get_self_link( NicInfo::get_links( @objectclass ) ) )
    end

  end

end