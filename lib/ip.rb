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

module NicInfo

  def NicInfo.display_ip json_data, config
    Ip.new( config ).process( json_data ).display
  end

  # deals with RDAP IP network structures
  class Ip

    def initialize config
      @config = config
      @common = CommonJson.new config
      @ip = nil
    end

    def process json_data
      @objectclass = json_data
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
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      return handle if handle
      return "(unidentifiable network)"
    end

  end

end