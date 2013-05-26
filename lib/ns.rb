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

  def NicInfo.display_ns json_data, config, data_node
    ns = Ns.new( config ).process( json_data )
    NicInfo::display_object_with_entities( ns, config, data_node )
  end

  # deals with RDAP nameserver structures
  class Ns

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
      @config.logger.terse "Host Name", NicInfo::get_ldhName( @objectclass )
      @config.logger.terse "IDN Host Name", NicInfo::get_unicodeName( @objectclass )
      ipAddrs = @objectclass[ "ipAddresses" ]
      if ipAddrs
        v6Addrs = ipAddrs[ "v6" ]
        v6Addrs.each do |v6|
          @config.logger.terse "IPv6 Address", v6
        end if v6Addrs
        v4Addrs = ipAddrs[ "v4" ]
        v4Addrs.each do |v4|
          @config.logger.terse "IPv4 Address", v4
        end if v4Addrs
      end
      @common.display_status @objectclass
      @common.display_events @objectclass
      @common.display_entities_as_events @entities
      @common.display_port43 @objectclass
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
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