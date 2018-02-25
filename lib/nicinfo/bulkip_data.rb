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
require 'nicinfo/appctx'
require 'nicinfo/ip'
require 'nicinfo/utils'
require 'nicinfo/common_summary'

module NicInfo

  class BulkIPNetwork

    attr_accessor :ipnetwork, :total_queries, :first_query_time, :last_query_time

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      @total_queries = 0
      hit( time )
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

  class BulkIPBlock

    attr_accessor :cidrstring, :bulkipnetwork, :bulkiplisted, :total_queries, :first_query_time, :last_query_time

    def initialize( cidrstring, time, bulkipnetwork, bulkiplisted )
      @bulkiplisted = bulkiplisted
      @bulkipnetwork = bulkipnetwork
      @cidrstring = cidrstring
      @total_queries = 0
      hit( time )
    end

    def hit( time )
      @total_queries = @total_queries + 1
      if time
        @first_query_time = time unless @first_query_time
        @first_query_time = time if time < @first_query_time
        @last_query_time = time unless @last_query_time
        @last_query_time = time if time > @last_query_time
      end
      bulkipnetwork.hit( time )
      bulkiplisted.hit( time )
    end

  end

  class BulkIPListed

    attr_accessor :ipnetwork, :total_queries, :first_query_time, :last_query_time

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      @total_queries = 0
      hit( time )
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

    attr_accessor :ipaddr, :time, :code, :reason

    def initialize( ipaddr, time, code, reason )
      @ipaddr = ipaddr
      @time = time
      @code = code
      @reason = reason
    end

  end

  class BulkIPData

    attr_accessor :net_data, :listed_data, :block_data, :fetch_errors, :ip_errors, :appctx

    BlockColumnHeaders = [ "Block", "Hits", "Avgd Hits/S", "Time Span", "Registry", "Listed Name", "Listed Country", "Abuse Email" ]
    NetworkColumnHeaders = [ "Network", "Hits", "Avgd Hits/S", "Time Span", "Registry", "Listed Name", "Listed Country", "Abuse Email" ]
    ListedColumnHeaders = [ "Listed Name", "Hits", "Avgd Hits/S", "Time Span", "Registry", "Listed Country", "Abuse Email" ]
    UrlColumnHeaders = [ "Total Queries", "Averaged QPS", "URL" ]
    NotApplicable = "N/A"

    def initialize( appctx )
      @appctx = appctx
      @block_data = Hash.new
      @listed_data = Hash.new
      @net_data = Array.new
      @fetch_errors = Array.new
      @ip_errors = Array.new
      @non_global_unicast = 0
      @network_lookups = 0
      @total_hits = 0
      @total_fetch_errors = 0
    end

    def note_start_time
      @start_time = Time.now
    end

    def note_end_time
      @end_time = Time.now
    end

    def valid_to_query?( ipaddr )
      retval = NicInfo.is_global_unicast?( ipaddr )
      @non_global_unicast = @non_global_unicast + 1 unless retval
      return retval
    end

    def hit_ipaddr( ipaddr, time )

      retval = false
      @block_data.each do |datum_net, datum|
        if datum_net.include?( ipaddr )
          datum.hit( time )
          retval = true
          break;
        end
      end

      @total_hits = @total_hits + 1 if retval
      return retval

    end

    def hit_network( ipnetwork, time )

      bulkipnetwork = BulkIPNetwork.new( ipnetwork, time )
      @net_data << bulkipnetwork

      listed_name = ipnetwork.summary_data[ NicInfo::CommonSummary::LISTED_NAME ]
      listed_name = NotApplicable unless listed_name
      bulkiplisted = @listed_data[ listed_name ]
      unless bulkiplisted
        bulkiplisted = BulkIPListed.new( ipnetwork, time )
        @listed_data[ listed_name ] = bulkiplisted
      end

      cidrs = ipnetwork.summary_data[ NicInfo::CommonSummary::CIDRS ]
      cidrs.each do |cidr|
        b = BulkIPBlock.new( cidr, time, bulkipnetwork, bulkiplisted )
        @block_data[IPAddr.new( cidr ) ] = b
      end

      @total_hits = @total_hits + 1
      @network_lookups = @network_lookups + 1

    end

    def fetch_error( ipaddr, time, code, reason )
      @fetch_errors << BulkIPFetchError.new( ipaddr, time, code, reason )
      @total_fetch_errors = @total_fetch_errors + 1
    end

    def review_fetch_errors
      @fetch_errors.delete_if do |fetch_error|
        hit_ipaddr( fetch_error.ipaddr, fetch_error.time )
      end
    end

    def ip_error( ip )
      @ip_errors << ip
    end

    def output_tsv( file_name )
      @appctx.logger.trace( "writing TSV file #{file_name}")
      output_column_sv( file_name, ".tsv", "\t" )
    end

    def output_csv( file_name )
      @appctx.logger.trace( "writing CSV file #{file_name}")
      output_column_sv( file_name, ".csv", "," )
    end

    def output_column_sv( file_name, extension, seperator )

      f = File.open( file_name+"-blocks"+extension, "w" );
      f.puts( output_block_column_headers(seperator ) )
      @block_data.values.each do |datum|
        f.puts( output_block_columns(datum, seperator ) )
      end
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      f = File.open( file_name+"-networks"+extension, "w" );
      f.puts( output_network_column_headers( seperator ) )
      @net_data.each do |datum|
        f.puts( output_network_columns( datum, seperator ) )
      end
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      f = File.open( file_name+"-listedname"+extension, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      @listed_data.values.each do |datum |
        f.puts( output_listed_columns( datum, seperator ) )
      end
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      f = File.open( file_name+"-meta"+extension, "w" );
      unless @fetch_errors.empty?
        f.puts
        f.puts( "Unresolved Fetch Errors" )
        @fetch_errors.each do |fetch_error|
          f.puts( "#{fetch_error.ipaddr.to_s}#{seperator}#{fetch_error.code}#{seperator}#{fetch_error.reason}" )
        end
      end

      unless @ip_errors.empty?
        f.puts
        f.puts( "Unrecognized IP Addresses" )
        @ip_errors.each do |ip|
          f.puts( ip )
        end
      end

      unless @appctx.tracked_urls.empty?
        f.puts
        f.puts( UrlColumnHeaders.join( seperator ) )
        @appctx.tracked_urls.each_value do |tracker|
          qps = tracker.total_queries.fdiv( tracker.last_query_time.to_i - tracker.first_query_time.to_i )
          f.puts( output_tracked_urls( tracker, qps, seperator ) )
        end
      end

      f.puts
      f.puts( output_total_row( "Non-Global Unicast IPs", @non_global_unicast, seperator ) )
      f.puts( output_total_row( "Network Lookups", @network_lookups, seperator ) )
      f.puts( output_total_row( "Total Hits", @total_hits, seperator ) )
      f.puts( output_total_row( "Total Fetch Errors", @total_fetch_errors, seperator ) )
      f.puts( output_total_row( "Start Time", @start_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "End Time", @end_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )

      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close
    end

    def output_block_column_headers(seperator )
      return BlockColumnHeaders.join(seperator )
    end

    def output_network_column_headers( seperator )
      return NetworkColumnHeaders.join( seperator )
    end

    def output_listed_column_headers( seperator )
      return ListedColumnHeaders.join( seperator )
    end

    def output_block_columns(datum, seperator )
      columns = Array.new
      columns << datum.cidrstring
      columns << datum.total_queries.to_s
      if datum.last_query_time == nil or datum.first_query_time == nil
        columns << NotApplicable #hits/s
        columns << NotApplicable #timespan
      else
        t = datum.last_query_time.to_i - datum.first_query_time.to_i
        if t > 0
          columns << datum.total_queries.fdiv( t ).to_s
        else
          columns << datum.total_queries.fdiv( 1 ).to_s
        end
        columns << "#{datum.first_query_time.strftime('%d %b %Y %H:%M:%S')} - #{datum.last_query_time.strftime('%d %b %Y %H:%M:%S')}"
      end
      summary_data = datum.bulkipnetwork.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_network_columns( datum, seperator )
      columns = Array.new
      columns << datum.ipnetwork.get_cn
      columns << datum.total_queries.to_s
      if datum.last_query_time == nil or datum.first_query_time == nil
        columns << NotApplicable #hits/s
        columns << NotApplicable #timespan
      else
        t = datum.last_query_time.to_i - datum.first_query_time.to_i
        if t > 0
          columns << datum.total_queries.fdiv( t ).to_s
        else
          columns << datum.total_queries.fdiv( 1 ).to_s
        end
        columns << "#{datum.first_query_time.strftime('%d %b %Y %H:%M:%S')} - #{datum.last_query_time.strftime('%d %b %Y %H:%M:%S')}"
      end
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_listed_columns( datum, seperator )
      columns = Array.new
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << datum.total_queries.to_s
      if datum.last_query_time == nil or datum.first_query_time == nil
        columns << NotApplicable #hits/s
        columns << NotApplicable #timespan
      else
        t = datum.last_query_time.to_i - datum.first_query_time.to_i
        if t > 0
          columns << datum.total_queries.fdiv( t ).to_s
        else
          columns << datum.total_queries.fdiv( 1 ).to_s
        end
        columns << "#{datum.first_query_time.strftime('%d %b %Y %H:%M:%S')} - #{datum.last_query_time.strftime('%d %b %Y %H:%M:%S')}"
      end
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_tracked_urls( tracker, qps, seperator )
      columns = Array.new
      columns << tracker.total_queries.to_s
      columns << qps.to_s
      columns << tracker.url
      return columns.join( seperator )
    end

    def output_total_row( description, value, seperator )
      return "#{description}#{seperator}#{value}"
    end

    def to_columnar_string( string, seperator )
      retval = NotApplicable
      if string
        retval = string.gsub( seperator, "\\" + seperator )
      end
      return retval
    end

  end

end
