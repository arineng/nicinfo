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

  def NicInfo.display_ip json_data, config
    ip = Ip.new( config ).process( json_data )
    if !ip.entities.empty?
      data_tree = DataTree.new
      root = ip.to_node
      data_tree.add_root( root )
      ip.entities.each do |entity|
        root.add_child( entity.to_node )
      end
      data_tree.to_normal_log( config.logger, true )
    end
    ip.display
    ip.entities.each do |entity|
      entity.display
    end
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
      @config.logger.terse "Start Address", @objectclass[ "startAddress" ]
      @config.logger.terse "End Address", @objectclass[ "endAddress" ]
      @config.logger.datum "IP Version", @objectclass[ "ipVersion" ]
      @config.logger.extra "Name", @objectclass[ "name" ]
      @config.logger.terse "Country", @objectclass[ "country" ]
      @config.logger.datum "Type", @objectclass[ "type" ]
      @config.logger.extra "Parent Handle", @objectclass[ "parentHandle" ]
      @common.display_status @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @common.display_events @objectclass
      @common.display_entities_as_events @entities
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      return handle if handle
      return "(unidentifiable network)"
    end

    def to_node
      DataNode.new( get_cn, NicInfo::get_self_link( NicInfo::get_links( @objectclass ) ) )
    end

  end

end