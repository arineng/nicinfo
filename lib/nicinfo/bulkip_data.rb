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

  # things to think about
  # TODO second pass feature that does not query network
  # TODO percentage of total observations
  # TODO mean, std dev, and cv of both period and frequency
  # TODO refactor using statistical terms
  # TODO hit_ipaddr should be query_for_net? and return a reason code
  # TODO remove invalid IP address strings and just produce a count
  # TODO track redirect URLs too
  # TODO feature to turn off deep object caching
  # TODO unique nets by fixed size

  class BulkIPNetwork

    attr_accessor :ipnetwork, :total_hits, :first_hit_time, :last_hit_time

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      @total_hits = 0
      hit( time )
    end

    def hit( time )
      @total_hits = @total_hits + 1
      if time
        @first_hit_time = time unless @first_hit_time
        @first_hit_time = time if time < @first_hit_time
        @last_hit_time = time unless @last_hit_time
        @last_hit_time = time if time > @last_hit_time
      end
    end

  end

  class BulkIPBlock

    attr_accessor :cidrstring, :bulkipnetwork, :bulkiplisted, :total_hits, :first_hit_time, :last_hit_time

    def initialize( cidrstring, time, bulkipnetwork, bulkiplisted )
      @bulkiplisted = bulkiplisted
      @bulkipnetwork = bulkipnetwork
      @cidrstring = cidrstring
      @total_hits = 0
      hit( time )
    end

    def hit( time )
      @total_hits = @total_hits + 1
      if time
        @first_hit_time = time unless @first_hit_time
        @first_hit_time = time if time < @first_hit_time
        @last_hit_time = time unless @last_hit_time
        @last_hit_time = time if time > @last_hit_time
      end
      @bulkipnetwork.hit( time ) if @bulkipnetwork
      @bulkiplisted.hit( time ) if @bulkiplisted
    end

  end

  class BulkIPListed

    attr_accessor :ipnetwork, :total_hits, :first_hit_time, :last_hit_time

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      @total_hits = 0
      hit( time )
    end

    def hit( time )
      @total_hits = @total_hits + 1
      if time
        @first_hit_time = time unless @first_hit_time
        @first_hit_time = time if time < @first_hit_time
        @last_hit_time = time unless @last_hit_time
        @last_hit_time = time if time > @last_hit_time
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
    attr_accessor :interval_seconds_to_increment, :second_to_sample, :total_intervals

    BlockColumnHeaders = [ "Block", "Hits", "Avgd Hits/s", "Duration (s)", "First Hit Time", "Last Hit Time", "Registry", "Listed Name", "Listed Country", "Abuse Email" ]
    NetworkColumnHeaders = [ "Network", "Hits", "Avgd Hits/s", "Duration (s)", "First Hit Time", "Last Hit Time", "Registry", "Listed Name", "Listed Country", "Abuse Email" ]
    ListedColumnHeaders = [ "Listed Name", "Hits", "Avgd Hits/s", "Duration (s)", "First Hit Time", "Last Hit Time", "Registry", "Listed Country", "Abuse Email" ]
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

    def set_top_hits_number( top_hits_number )
      if top_hits_number
        @top_hits_number = top_hits_number
        @top_block_hits = Array.new
        @top_network_hits = Array.new
        @top_listedname_hits = Array.new
      end
    end

    def set_top_hps_number( top_hps_number )
      if top_hps_number
        @top_hps_number = top_hps_number
        @top_block_hps = Array.new
        @top_network_hps = Array.new
        @top_listedname_hps = Array.new
      end
    end

    def sort_array_by_top( array, top_number )
      retval = array.sort_by do |i|
        i[0] * -1
      end
      return retval.first( top_number )
    end

    def note_start_time
      @start_time = Time.now
    end

    def note_end_time
      @end_time = Time.now
    end

    def note_new_file
      @first_file_time = nil
    end

    def set_interval_seconds_to_increment( seconds )
      @interval_seconds_to_increment = seconds
      @total_intervals = 0
    end

    def hit_time( time )
      if time
        @first_hit_time = time unless @first_hit_time
        @first_hit_time = time if time < @first_hit_time
        @last_hit_time = time unless @last_hit_time
        @last_hit_time = time if time > @last_hit_time
      end
    end

    def valid_to_query?( ipaddr )
      retval = NicInfo.is_global_unicast?( ipaddr )
      @non_global_unicast = @non_global_unicast + 1 unless retval
      return retval
    end

    def hit_ipaddr( ipaddr, time )

      if @interval_seconds_to_increment
        if @first_file_time
          if time > ( @second_to_sample + @interval_seconds_to_increment )
            @second_to_sample = time
            @total_intervals = @total_intervals + 1
            @appctx.logger.trace( "setting sample time to be now: #{@second_to_sample}" )
          elsif time > @second_to_sample
            @second_to_sample = time + rand( @interval_seconds_to_increment )
            @total_intervals = @total_intervals + 1
            @appctx.logger.trace( "calculating next sample time to be #{@second_to_sample}" )
          end
        else
          @first_file_time = time
          @second_to_sample = @first_file_time
          @appctx.logger.trace( "first time sample is #{@second_to_sample}")
        end
      end

      retval = false
      @block_data.each do |datum_net, datum|
        if datum_net.include?( ipaddr )
          datum.hit( time )
          retval = true
          @appctx.logger.trace( "observed network already retreived" )
          break;
        end
      end

      @total_hits = @total_hits + 1 if retval
      hit_time( time )

      # if doing sampling, then return true when not in the sample second
      # this will avoid a call to hit_network
      # if sampling is being done can be detected with @interval_seconds_to_increment
      if @interval_seconds_to_increment && time.to_i != @second_to_sample.to_i
        @appctx.logger.trace( "retreival unnecessary outside of sampling time" )
        retval = true
      end
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
      hit_time( time )

    end

    def fetch_error( ipaddr, time, code, reason )
      @fetch_errors << BulkIPFetchError.new( ipaddr, time, code, reason )
      @total_fetch_errors = @total_fetch_errors + 1
    end

    def review_fetch_errors
      # run back through and figure out which can be processed again
      # and delete them
      @fetch_errors.delete_if do |fetch_error|
        hit_ipaddr( fetch_error.ipaddr, fetch_error.time )
      end

      # now lets put these into blocks as unknown
      @fetch_errors.each do |fetch_error|
        block_found = hit_ipaddr( fetch_error.ipaddr, fetch_error.time )
        unless block_found
          if fetch_error.ipaddr.ipv6?
            cidr = "#{fetch_error.ipaddr.mask(56).to_s}/56"
          else
            cidr = "#{fetch_error.ipaddr.mask(24).to_s}/24"
          end
          b = BulkIPBlock.new( cidr, fetch_error.time, nil, nil )
          @block_data[IPAddr.new( cidr ) ] = b
          @total_hits = @total_hits + 1
        end
      end
    end

    def ip_error( ip )
      @ip_errors << ip
    end

    def output_tsv( file_name )
      output_column_sv( file_name, ".tsv", "\t" )
    end

    def output_csv( file_name )
      output_column_sv( file_name, ".csv", "," )
    end

    def output_column_sv( file_name, extension, seperator )

      n = file_name+"-blocks"+extension
      @appctx.logger.trace( "writing file #{n}")
      if @top_hits_number
        top_hits = @top_block_hits
      else
        top_hits = nil
      end
      if @top_hps_number
        top_hps = @top_block_hps
      else
        top_hps = nil
      end
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      @block_data.values.each do |datum|
        f.puts( output_block_columns(datum, seperator, top_hits, top_hps ) )
        top_hits = sort_array_by_top( top_hits, @top_hits_number ) if top_hits
        top_hps = sort_array_by_top( top_hps, @top_hps_number ) if top_hps
      end
      @top_block_hits = top_hits if top_hits
      @top_block_hps = top_hps if top_hps
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      n = file_name+"-networks"+extension
      @appctx.logger.trace( "writing file #{n}")
      if @top_hits_number
        top_hits = @top_network_hits
      else
        top_hits = nil
      end
      if @top_hps_number
        top_hps = @top_network_hps
      else
        top_hps = nil
      end
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      @net_data.each do |datum|
        f.puts( output_network_columns( datum, seperator, top_hits, top_hps ) )
        top_hits = sort_array_by_top( top_hits, @top_hits_number ) if top_hits
        top_hps = sort_array_by_top( top_hps, @top_hps_number ) if top_hps
      end
      @top_network_hits = top_hits if top_hits
      @top_network_hps = top_hps if top_hps
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      n = file_name+"-listedname"+extension
      @appctx.logger.trace( "writing file #{n}")
      if @top_hits_number
        top_hits = @top_listedname_hits
      else
        top_hits = nil
      end
      if @top_hps_number
        top_hps = @top_listedname_hps
      else
        top_hps = nil
      end
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      @listed_data.values.each do |datum |
        f.puts( output_listed_columns( datum, seperator, top_hits, top_hps ) )
        top_hits = sort_array_by_top( top_hits, @top_hits_number ) if top_hits
        top_hps = sort_array_by_top( top_hps, @top_hps_number ) if top_hps
      end
      @top_listedname_hits = top_hits if top_hits
      @top_listedname_hps = top_hps if top_hps
      f.puts
      f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      f.puts( "https://github.com/arineng/nicinfo" )
      f.close

      if @top_hits_number

        n = "#{file_name}-blocks-top#{@top_hits_number}-hits#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_block_column_headers(seperator ) )
        @top_block_hits.each do |item|
          f.puts( output_block_columns(item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

        n = "#{file_name}-networks-top#{@top_hits_number}-hits#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_network_column_headers( seperator ) )
        @top_network_hits.each do |item|
          f.puts( output_network_columns( item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

        n = "#{file_name}-listedname-top#{@top_hits_number}-hits#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_listed_column_headers( seperator ) )
        @top_listedname_hits.each do |item |
          f.puts( output_listed_columns( item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

      end

      if @top_hps_number

        n = "#{file_name}-blocks-top#{@top_hits_number}-hps#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_block_column_headers(seperator ) )
        @top_block_hps.each do |item|
          f.puts( output_block_columns(item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

        n = "#{file_name}-networks-top#{@top_hits_number}-hps#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_network_column_headers( seperator ) )
        @top_network_hps.each do |item|
          f.puts( output_network_columns( item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

        n = "#{file_name}-listedname-top#{@top_hits_number}-hps#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_listed_column_headers( seperator ) )
        @top_listedname_hps.each do |item |
          f.puts( output_listed_columns( item[1], seperator, nil, nil ) )
        end
        f.puts
        f.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
        f.puts( "https://github.com/arineng/nicinfo" )
        f.close

      end

      n = file_name+"-meta"+extension
      @appctx.logger.trace( "writing file #{n}")
      f = File.open( n, "w" );
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
      f.puts( output_total_row( "First Hit Time", @first_hit_time.strftime('%d %b %Y %H:%M:%S'), seperator ) ) if @first_hit_time
      f.puts( output_total_row( "Last Hit Time", @last_hit_time.strftime('%d %b %Y %H:%M:%S'), seperator ) ) if @last_hit_time
      f.puts( output_total_row( "Non-Global Unicast IPs", @non_global_unicast, seperator ) )
      f.puts( output_total_row( "Network Lookups", @network_lookups, seperator ) )
      f.puts( output_total_row( "Total Hits", @total_hits, seperator ) )
      f.puts( output_total_row( "Total Fetch Errors", @total_fetch_errors, seperator ) )
      f.puts( output_total_row( "Analysis Start Time", @start_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Analysis End Time", @end_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Total Intervals", @total_intervals, seperator ) ) if @interval_seconds_to_increment

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

    def output_block_columns(datum, seperator, top_hits, top_hps )
      columns = Array.new
      columns << datum.cidrstring
      gather_query_and_timing_values( columns, datum, top_hits, top_hps )
      if datum.bulkipnetwork
        summary_data = datum.bulkipnetwork.ipnetwork.summary_data
        columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
        columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
        columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
        columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      else
        columns << NotApplicable
        columns << NotApplicable
        columns << NotApplicable
        columns << NotApplicable
      end
      return columns.join( seperator )
    end

    def output_network_columns( datum, seperator, top_hits, top_hps )
      columns = Array.new
      columns << datum.ipnetwork.get_cn
      gather_query_and_timing_values( columns, datum, top_hits, top_hps )
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_listed_columns( datum, seperator, top_hits, top_hps )
      columns = Array.new
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      gather_query_and_timing_values( columns, datum, top_hits, top_hps )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def gather_query_and_timing_values( columns, datum, top_hits = nil, top_hps = nil )
      columns << datum.total_hits.to_s
      top_hits << [ datum.total_hits, datum ] if top_hits
      if datum.last_hit_time == nil or datum.first_hit_time == nil
        columns << NotApplicable #hits/s
        columns << NotApplicable #duration
        columns << NotApplicable #first query time
        columns << NotApplicable #last query time
      else
        t = datum.last_hit_time.to_i - datum.first_hit_time.to_i + 1
        hps = datum.total_hits.fdiv( t )
        columns << hps.to_s
        top_hps << [ hps, datum ] if top_hps
        columns << t.to_s
        columns << datum.first_hit_time.strftime('%d %b %Y %H:%M:%S')
        columns << datum.last_hit_time.strftime('%d %b %Y %H:%M:%S')
      end
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
