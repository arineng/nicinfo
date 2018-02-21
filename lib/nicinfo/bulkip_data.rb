# Copyright (C) 2018 American Registry for Internet Numbers
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

require 'ipaddr'
require 'nicinfo/ip'
require 'nicinfo/utils'
require 'nicinfo/common_summary'

module NicInfo

  class BulkIPDatum

    attr_accessor :ipnetwork, :total_queries, :first_query_time, :last_query_time

    def initialize( ipnetwork )
      @ipnetwork = ipnetwork
      @total_queries = 1
      @first_query_time = Time.now
      @last_query_time = @first_query_time
    end

    def hit( time )
      @total_queries = @total_queries + 1
      if time
        @first_query_time = time unless @first_query_time
        @first_query_time = time if time < @first_query_time
        @last_query_time = time unless @last_query_time
        @last_query_time = time if time > @last_query_time
      end
    end

  end

  class BulkIPFetchError

    attr_accessor :ipaddr, :time

    def initialize( ipaddr, time )
      @ipaddr = ipaddr
      @time = time
    end

  end

  class BulkIPData

    attr_accessor :data, :fetch_errors

    def initialize
      @data = Hash.new
      @fetch_errors = Array.new
    end

    def hit_ipaddr( ipaddr, time )

      retval = false
      @data.each do |datum_net, datum|
        if datum_net.include?( ipaddr )
          datum.hit( time )
          retval = true
          break;
        end
      end

      return retval

    end

    def hit_network( ipnetwork )

      cidrs = ipnetwork.summary_data[ NicInfo::CommonSummary::CIDRS ]
      cidrs.each do |cidr|
        d = BulkIPDatum.new( ipnetwork )
        @data[ IPAddr.new( cidr ) ] = d
      end

    end

    def fetch_error( ipaddr, time )
      @fetch_errors << BulkIPFetchError.new( ipaddr, time )
    end

    def review_errors
      @fetch_errors.delete_if do |fetch_error|
        hit_ipaddr( fetch_error.ipaddr, fetch_error.time )
      end
    end

  end

end
