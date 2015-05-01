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

require 'config'
require 'nicinfo_logger'
require 'utils'
require 'common_json'
require 'entity'
require 'data_tree'

module NicInfo

  def NicInfo.display_autnum json_data, config, data_tree
    autnum = Autnum.new( config ).process( json_data )
    NicInfo::display_object_with_entities( autnum, config, data_tree )
  end

  # deals with RDAP autonomous number structures
  class Autnum

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
      @config.logger.data_title "[ AS NUMBER ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass )
      @config.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass )
      endNum = NicInfo.get_endAutnum @objectclass
      startNum = NicInfo.get_startAutnum @objectclass
      if endNum
        @config.logger.terse "Start AS Number", startNum
        @config.logger.terse "End AS Number", endNum
      else
        @config.logger.terse "AS Number", startNum
      end
      @config.logger.extra "Name", NicInfo.get_name( @objectclass )
      @config.logger.terse "Country", NicInfo.get_country( @objectclass )
      @config.logger.datum "Type", NicInfo.get_type( @objectclass )
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
        startNum = NicInfo.get_startAutnum @objectclass
        handle = startNum if startNum
        endNum = NicInfo.get_endAutnum @objectclass
        handle << " - " if startNum and endNum
        handle << endNum if endNum
      end
      return handle if handle
      return "(unidentifiable autonomous system number #{object_id})"
    end

    def to_node
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @config ) ) )
    end

  end

end