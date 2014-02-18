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
require 'data_tree'

module NicInfo

  def NicInfo.display_key_data json_data, config, data_node
    key_data = KeyData.new( config ).process( json_data ).display
  end

  # deals with RDAP key data structures
  class KeyData

    attr_accessor :objectclass, :asEventActors

    def initialize config
      @config = config
      @common = CommonJson.new config
      @asEventActors = Array.new
    end

    def process json_data
      @objectclass = json_data
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.data_title "[ KEY DATA ]"
      @config.logger.terse "Algorithm", NicInfo::get_algorithm( @objectclass )
      @config.logger.terse "Flags", @objectclass[ "flags" ]
      @config.logger.terse "Protocol", @objectclass[ "protocol" ]
      @config.logger.terse "Public Key", @objectclass[ "publicKey" ]
      @common.display_events @objectclass
      @common.display_as_events_actors @asEventActors
      @config.logger.end_data_item
    end

    def get_cn
      algorithm = NicInfo::DNSSEC_ALGORITHMS[ NicInfo::get_algorithm( @objectclass ) ]
      algorithm = algorithm + " Key Data" if algorithm
      algorithm = "(unidentifiable key data #{object_id})" if !algorithm
      return algorithm
    end

    def to_node
      node = DataNode.new( get_cn, nil, NicInfo::get_self_link( NicInfo::get_links( @objectclass, @config ) ) )
      node.data_type=self.class.name
      return node
    end

  end

end