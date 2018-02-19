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

  def NicInfo.display_autnum json_data, appctx, data_tree
    autnum = appctx.factory.new_autnum.process( json_data )
    NicInfo::display_object_with_entities( autnum, appctx, data_tree )
  end

  def NicInfo.process_autnum( json_data, appctx )
    return appctx.factory.new_autnum.process( json_data )
  end

  # deals with RDAP autonomous number structures
  class Autnum

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
      common_summary.inject
      return self
    end

    def display
      @appctx.logger.start_data_item
      @appctx.logger.data_title "[ AS NUMBER ]"
      @appctx.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @appctx.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass, "autnum", @appctx )
      endNum = NicInfo.get_endAutnum @objectclass
      startNum = NicInfo.get_startAutnum @objectclass
      if endNum
        @appctx.logger.terse "Start AS Number", startNum, NicInfo::AttentionType::SUCCESS
        @appctx.logger.terse "End AS Number", endNum, NicInfo::AttentionType::SUCCESS
      else
        @appctx.logger.terse "AS Number", startNum, NicInfo::AttentionType::SUCCESS
      end
      @appctx.logger.extra "Name", NicInfo.get_name( @objectclass )
      @appctx.logger.terse "Country", NicInfo.get_country( @objectclass )
      @appctx.logger.datum "Type", NicInfo.get_type(@objectclass )
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
      DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @appctx ) ) )
    end

  end

end
