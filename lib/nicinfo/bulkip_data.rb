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
require 'nicinfo/net_tree'

module NicInfo

  # things to think about
  # TODO second pass feature that does not query network
  # TODO percentage of total observations by registry
  # TODO mean, std dev, and cv of both period and frequency
  # TODO track redirect URLs too
  # TODO track error count per URL
  # TODO track avg response time per URL
  # TODO feature to turn off deep object caching
  # TODO unique nets by fixed size
  # TODO get rid of explicit exits
  # TODO make CSV/TSV output compliant with RFC4180
  # TODO when no files in bulk-in glob, throw error
  # TODO add feature to set sorted line buffer size

  class Stat

    attr_accessor :sum, :count, :sum_squared

    def initialize
      @sum = 0
      @sum_squared = 0
      @count = 0
    end

    def datum( value )
      if value
        @sum = @sum + value
        @sum_squared = @sum_squared + value**2
        @count = @count + 1
      end
    end

    def get_average( sum = @sum, count = @count )
      retval = nil
      retval = sum.fdiv( count ) if count > 0
      return retval
    end

    def get_std_dev( sample, count = @count, sum = @sum, sum_squared = @sum_squared )
      retval = nil
      devisor = count
      if sample
        devisor = count - 1
      end
      variance = ( sum_squared - sum**2.0 / count )
      if devisor > 0 && variance > 0
        retval = Math.sqrt( variance / devisor )
      end
      return retval
    end

    def get_cv( sample, count = @count, sum = @sum, sum_squared = @sum_squared, average = get_average( @sum, @count ) )
      retval = nil
      std_dev = get_std_dev( sample, count, sum, sum_squared )
      if std_dev && average
        retval = std_dev.fdiv( average )
      end
      return retval
    end

    def get_percentage( value )
      retval = nil
      if value
        retval = "#{value * 100}%"
      end
      return retval
    end

  end

  class BulkIPObservation < Stat

    attr_accessor :observations, :first_observed_time, :last_observed_time
    attr_accessor :this_second
    # magnitude is defined as observations per second
    attr_accessor :magnitude, :magnitude_ceiling, :magnitude_floor
    attr_accessor :magnitude_sum, :magnitude_count, :magnitude_sum_squared
    # interval is defined as the time in seconds between seconds with an observation
    # by definition, must be greater than zero
    attr_accessor :shortest_interval, :longest_interval
    attr_accessor :interval_sum, :interval_count, :interval_sum_squared
    # run is defined as the consecutive seconds with an observation
    # by definition, must be greater than zero
    attr_accessor :run, :shortest_run, :longest_run
    attr_accessor :run_count, :run_sum, :run_sum_squared

    def initialize( time )
      @observations = 0
      @interval_sum = 0
      @interval_sum_squared = 0
      @interval_count = 0
      @run_count = 0
      @run_sum = 0
      @run_sum_squared = 0
      @magnitude_sum = 0
      @magnitude_sum_squared = 0
      observed( time )
    end

    def observed( time )
      @observations = @observations + 1
      if time
        @first_observed_time = time unless @first_observed_time
        @first_observed_time = time if time < @first_observed_time
        @last_observed_time = time unless @last_observed_time
        @last_observed_time = time if time > @last_observed_time

        if @this_second == nil
          @this_second = time.to_i
          @magnitude = 1
          @magnitude_ceiling = 1
          @magnitude_count = 1
          @run = 1
          @longest_run = 1
        elsif time.to_i == @this_second
          @magnitude = @magnitude + 1
          if @magnitude > @magnitude_ceiling
            @magnitude_ceiling = @magnitude
          end
        elsif time.to_i != @this_second
          interval = time.to_i - @this_second - 1
          if interval > 0 && @shortest_interval == nil
            @shortest_interval = interval
          elsif interval > 0 && interval < @shortest_interval
            @shortest_interval = interval
          end
          if interval > 0 && ( @longest_interval == nil || interval > @longest_interval )
            @longest_interval = interval
          end
          if interval > 0
            @interval_sum = @interval_sum + interval
            @interval_sum_squared = @interval_sum_squared + interval**2
            @interval_count = @interval_count + 1
          end
          if interval == 0
            @run = @run + 1
          else
            @shortest_run = @run unless @shortest_run
            @shortest_run = @run if @shortest_run > @run
            @longest_run = @run if @longest_run < @run
            @run_count = @run_count + 1
            @run_sum = @run_sum + @run
            @run_sum_squared = @run_sum_squared + @run**2
            @run = 1
          end
          if @magnitude_floor == nil
            @magnitude_floor = @magnitude
          elsif @magnitude < @magnitude_floor
            @magnitude_floor = @magnitude
          end
          @magnitude_sum = @magnitude_sum + @magnitude
          @magnitude_sum_squared = @magnitude_sum_squared + @magnitude**2
          @magnitude_count = @magnitude_count + 1
          @this_second = time.to_i
          @magnitude = 1
        end
      end
    end

    def finish_calculations
      if @magnitude_floor == nil
        @magnitude_floor = @magnitude_ceiling
      elsif @magnitude < @magnitude_floor
        @magnitude_floor = @magnitude
      end
      @magnitude_sum = @magnitude_sum + @magnitude
      @magnitude_sum_squared = @magnitude_sum_squared + @magnitude**2
      if @run > 1
        @longest_run = @run if @longest_run < @run
        @run_count = @run_count + 1
        @run_sum = @run_sum + @run
        @run_sum_squared = @run_sum_squared + @run**2
      elsif @run_count == 0
        @run_count = 1
        @run_sum = 1
        @run_sum_squared = 1
      end
      @shortest_run = @run unless @shortest_run
    end

    def get_observed_period
      @last_observed_time.to_i - @first_observed_time.to_i + 1
    end

    def get_observations_per_observed_period
      @observations.fdiv( get_observed_period )
    end

    def get_observations_per_observation_period( observation_period_seconds )
      @observations.fdiv( observation_period_seconds )
    end

    def get_percentage_of_total_observations( total_observations )
      "#{@observations.fdiv( total_observations ) * 100.0}%"
    end

    def get_magnitude_average
      get_average( @magnitude_sum, @magnitude_count )
    end

    def get_magnitude_standard_deviation( sample )
      get_std_dev( sample, @magnitude_count, @magnitude_sum, @magnitude_sum_squared )
    end

    def get_magnitude_cv( sample )
      get_cv( sample, @magnitude_count, @magnitude_sum, @magnitude_sum_squared, get_magnitude_average )
    end

    def get_magnitude_cv_percentage( sample )
      get_percentage( get_magnitude_cv( sample ) )
    end

    def get_interval_average
      get_average( @interval_sum, @interval_count )
    end

    def get_interval_standard_deviation( sample )
      get_std_dev( sample, @interval_count, @interval_sum, @interval_sum_squared )
    end

    def get_interval_cv( sample )
      get_cv( sample, @interval_count, @interval_sum, @interval_sum_squared, get_interval_average )
    end

    def get_interval_cv_percentage( sample )
      get_percentage( get_interval_cv( sample ) )
    end

    def get_run_average
      get_average( @run_sum, @run_count )
    end

    def get_run_standard_deviation( sample )
      get_std_dev( sample, @run_count, @run_sum, @run_sum_squared )
    end

    def get_run_cv( sample )
      get_cv( sample, @run_count, @run_sum, @run_sum_squared, get_run_average )
    end

    def get_run_cv_percentage( sample )
      get_percentage( get_run_cv( sample ) )
    end

  end

  class BulkIPNetwork < BulkIPObservation

    attr_accessor :ipnetwork

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      super( time )
    end

  end

  class BulkIPBlock < BulkIPObservation

    attr_accessor :cidrstring, :bulkipnetwork, :bulkiplisted

    def initialize( cidrstring, time, bulkipnetwork, bulkiplisted )
      @bulkiplisted = bulkiplisted
      @bulkipnetwork = bulkipnetwork
      @cidrstring = cidrstring
      super( time )
    end

    def observed( time )
      super( time )
      @bulkipnetwork.observed( time ) if @bulkipnetwork
      @bulkiplisted.observed( time ) if @bulkiplisted
    end

  end

  class BulkIPListed < BulkIPObservation

    attr_accessor :ipnetwork

    def initialize( ipnetwork, time )
      @ipnetwork = ipnetwork
      super( time )
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

    attr_accessor :net_data, :listed_data, :block_data, :fetch_errors, :appctx, :network_lookups
    attr_accessor :interval_seconds_to_increment, :second_to_sample, :total_intervals

    UrlColumnHeaders = [ "Total Queries", "Averaged QPS", "URL" ]
    NotApplicable = "N/A"

    # result codes from query_for_net?
    NetNotFound = 0
    NetAlreadyRetreived = 1
    NetNotFoundBetweenIntervals = 2


    def initialize( appctx )
      @appctx = appctx
      @block_data = NicInfo::NetTree.new
      @listed_data = Hash.new
      @net_data = Array.new
      @fetch_errors = Array.new
      @non_global_unicast = 0
      @network_lookups = 0
      @total_observations = 0
      @total_fetch_errors = 0
      @total_ip_errors = 0
      @total_time_errors = 0
    end

    def set_top_observations_number( top_observations_number )
      if top_observations_number
        @top_observations_number = top_observations_number
        @top_block_observations = Array.new
        @top_network_observations = Array.new
        @top_listedname_observations = Array.new
      end
    end

    def set_top_ops_number( top_ops_number )
      if top_ops_number
        @top_ops_number = top_ops_number
        @top_block_ops = Array.new
        @top_network_ops = Array.new
        @top_listedname_ops = Array.new
      end
    end

    def sort_array_by_top( array, top_number )
      retval = array.sort_by do |i|
        i[0] * -1
      end
      return retval.first( top_number )
    end

    def note_times_in_data
      @do_time_statistics = true
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

    def observed_time( time )
      if time
        @first_observed_time = time unless @first_observed_time
        @first_observed_time = time if time < @first_observed_time
        @last_observed_time = time unless @last_observed_time
        @last_observed_time = time if time > @last_observed_time
      end
    end

    def valid_to_query?( ipaddr )
      retval = NicInfo.is_global_unicast?( ipaddr )
      @non_global_unicast = @non_global_unicast + 1 unless retval
      return retval
    end

    #real	2m4.086s
    #user	1m13.681s
    #sys	0m2.437s


    def query_for_net?(ipaddr, time )

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

      retval = NetNotFound
      datum = @block_data.find_by_ipaddr( ipaddr )
      if datum
        datum.observed( time )
        retval = NetAlreadyRetreived
        @appctx.logger.trace( "observed network already retreived" )
      end

      @total_observations = @total_observations + 1 if retval
      observed_time( time )

      # if doing sampling, note that
      if retval == NetNotFound && @interval_seconds_to_increment && time.to_i != @second_to_sample.to_i
        @appctx.logger.trace( "retreival unnecessary outside of sampling time" )
        retval = NetNotFoundBetweenIntervals
      end
      return retval

    end

    def observe_network( ipnetwork, time )

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
        b = @block_data.lookup_net( cidr )
        if b
          b.observed( time )
        else
          b = BulkIPBlock.new( cidr, time, bulkipnetwork, bulkiplisted )
          @block_data.insert( cidr, b )
        end
      end

      @total_observations = @total_observations + 1
      @network_lookups = @network_lookups + 1
      observed_time( time )

    end

    def fetch_error( ipaddr, time, code, reason )
      @fetch_errors << BulkIPFetchError.new( ipaddr, time, code, reason )
      @total_fetch_errors = @total_fetch_errors + 1
    end

    def review_fetch_errors
      # run back through and figure out which can be processed again
      # and delete them
      @fetch_errors.delete_if do |fetch_error|
        query_for_net?(fetch_error.ipaddr, fetch_error.time )
      end

      # now lets put these into blocks as unknown
      @fetch_errors.each do |fetch_error|
        block_found = query_for_net?(fetch_error.ipaddr, fetch_error.time )
        unless block_found
          if fetch_error.ipaddr.ipv6?
            cidr = "#{fetch_error.ipaddr.mask(56).to_s}/56"
          else
            cidr = "#{fetch_error.ipaddr.mask(24).to_s}/24"
          end
          b = BulkIPBlock.new( cidr, fetch_error.time, nil, nil )
          @block_data.insert( cidr, b )
          @total_observations = @total_observations + 1
        end
      end
    end

    def ip_error( ip )
      @total_ip_errors = @total_ip_errors + 1
    end

    def time_error( time )
      @total_time_errors = @total_time_errors + 1
    end

    def output_tsv( file_name )
      output_column_sv( file_name, ".tsv", "\t" )
    end

    def output_csv( file_name )
      output_column_sv( file_name, ".csv", "," )
    end

    def get_top_observations( top_observations )
      return top_observations if @top_observations_number
      return nil
    end

    def get_top_ops( top_ops )
      return top_ops if @top_ops_number
      return nil
    end

    def output_column_sv( file_name, extension, seperator )

      # prelim values
      if @first_observed_time != nil && @last_observed_time != nil
        @observation_period_seconds = @last_observed_time.to_i - @first_observed_time.to_i + 1
      else
        @observation_period_seconds = nil
      end

      n = file_name+"-blocks"+extension
      @appctx.logger.trace( "writing file #{n}")
      top_observations = get_top_observations( @top_block_observations )
      top_ops = get_top_ops( @top_block_ops )
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      @block_data.each do |datum|
        f.puts( output_block_columns(datum, seperator, top_observations, top_ops ) )
        top_observations = sort_array_by_top( top_observations, @top_observations_number ) if top_observations
        top_ops = sort_array_by_top( top_ops, @top_ops_number ) if top_ops
      end
      @top_block_observations = top_observations if top_observations
      @top_block_ops = top_ops if top_ops
      puts_signature( f )
      f.close

      n = file_name+"-networks"+extension
      @appctx.logger.trace( "writing file #{n}")
      top_observations = get_top_observations( @top_network_observations )
      top_ops = get_top_ops( @top_network_ops )
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      @net_data.each do |datum|
        f.puts( output_network_columns( datum, seperator, top_observations, top_ops ) )
        top_observations = sort_array_by_top( top_observations, @top_observations_number ) if top_observations
        top_ops = sort_array_by_top( top_ops, @top_ops_number ) if top_ops
      end
      @top_network_observations = top_observations if top_observations
      @top_network_ops = top_ops if top_ops
      puts_signature( f )
      f.close

      n = file_name+"-listednames"+extension
      @appctx.logger.trace( "writing file #{n}")
      top_observations = get_top_observations( @top_listedname_observations )
      top_ops = get_top_ops( @top_listedname_ops )
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      @listed_data.values.each do |datum |
        f.puts( output_listed_columns( datum, seperator, top_observations, top_ops ) )
        top_observations = sort_array_by_top( top_observations, @top_observations_number ) if top_observations
        top_ops = sort_array_by_top( top_ops, @top_ops_number ) if top_ops
      end
      @top_listedname_observations = top_observations if top_observations
      @top_listedname_ops = top_ops if top_ops
      puts_signature( f )
      f.close

      if @top_observations_number

        n = "#{file_name}-blocks-top#{@top_observations_number}-observations#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_block_column_headers(seperator ) )
        @top_block_observations.each do |item|
          f.puts( output_block_columns(item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
        f.close

        n = "#{file_name}-networks-top#{@top_observations_number}-observations#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_network_column_headers( seperator ) )
        @top_network_observations.each do |item|
          f.puts( output_network_columns( item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
        f.close

        n = "#{file_name}-listednames-top#{@top_observations_number}-observations#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_listed_column_headers( seperator ) )
        @top_listedname_observations.each do |item |
          f.puts( output_listed_columns( item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
        f.close

      end

      if @top_ops_number

        n = "#{file_name}-blocks-top#{@top_ops_number}-ops#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_block_column_headers(seperator ) )
        @top_block_ops.each do |item|
          f.puts( output_block_columns(item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
        f.close

        n = "#{file_name}-networks-top#{@top_ops_number}-ops#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_network_column_headers( seperator ) )
        @top_network_ops.each do |item|
          f.puts( output_network_columns( item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
        f.close

        n = "#{file_name}-listednames-top#{@top_ops_number}-ops#{extension}"
        @appctx.logger.trace( "writing file #{n}")
        f = File.open( n, "w" );
        f.puts( output_listed_column_headers( seperator ) )
        @top_listedname_ops.each do |item |
          f.puts( output_listed_columns( item[1], seperator, nil, nil ) )
        end
        puts_signature( f )
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

      unless @appctx.tracked_urls.empty?
        f.puts
        f.puts( UrlColumnHeaders.join( seperator ) )
        @appctx.tracked_urls.each_value do |tracker|
          qps = tracker.total_queries.fdiv( tracker.last_query_time.to_i - tracker.first_query_time.to_i )
          f.puts( output_tracked_urls( tracker, qps, seperator ) )
        end
      end

      f.puts
      f.puts( output_total_row( "First Observation Time", @first_observed_time.strftime('%d %b %Y %H:%M:%S'), seperator ) ) if @first_observed_time
      f.puts( output_total_row( "Last Observation Time", @last_observed_time.strftime('%d %b %Y %H:%M:%S'), seperator ) ) if @last_observed_time
      f.puts( output_total_row( "Observation Period", @observation_period_seconds, seperator ) )
      f.puts( output_total_row( "Total Observations", @total_observations, seperator ) )
      f.puts( output_total_row( "Total Networks", @net_data.length, seperator ) )
      f.puts( output_total_row( "Total Network Blocks", @block_data.length, seperator ) )
      f.puts( output_total_row( "Total Listed Names", @listed_data.length, seperator ) )
      f.puts( output_total_row( "Non-Global Unicast IPs", @non_global_unicast, seperator ) )
      f.puts( output_total_row( "Network Lookups", @network_lookups, seperator ) )
      f.puts( output_total_row( "Total Fetch Errors", @total_fetch_errors, seperator ) )
      f.puts( output_total_row( "Total IP Address Parse Errors", @total_ip_errors, seperator ) )
      f.puts( output_total_row( "Total Time Parse Errors", @total_time_errors, seperator ) )
      f.puts( output_total_row( "Analysis Start Time", @start_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Analysis End Time", @end_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Total Sampling Intervals", @total_intervals, seperator ) ) if @interval_seconds_to_increment

      puts_signature( f )
      f.close
    end

    def output_block_column_headers( seperator )
      headers = []
      headers << "Block"
      gather_query_and_timing_headers( headers )
      headers << "Registry" << "Listed Name" << "Listed Country" << "Abuse Email"
      return headers.join(seperator )
    end

    def output_network_column_headers( seperator )
      headers = []
      headers << "Network"
      gather_query_and_timing_headers( headers )
      headers << "Registry" << "Listed Name" << "Listed Country" << "Abuse Email"
      return headers.join( seperator )
    end

    def output_listed_column_headers( seperator )
      headers = []
      headers << "Listed Name"
      gather_query_and_timing_headers( headers )
      headers << "Registry" << "Listed Country" << "Abuse Email"
      return headers.join( seperator )
    end

    def puts_signature( file )
      file.puts
      file.puts( "Generated by NicInfo v.#{ NicInfo::VERSION }")
      file.puts( "https://github.com/arineng/nicinfo" )
    end

    def output_block_columns(datum, seperator, top_observations, top_ops )
      columns = Array.new
      columns << datum.cidrstring
      gather_query_and_timing_values( columns, datum, top_observations, top_ops )
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

    def output_network_columns( datum, seperator, top_observations, top_ops )
      columns = Array.new
      columns << datum.ipnetwork.get_cn
      gather_query_and_timing_values( columns, datum, top_observations, top_ops )
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_listed_columns( datum, seperator, top_observations, top_ops )
      columns = Array.new
      summary_data = datum.ipnetwork.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      gather_query_and_timing_values( columns, datum, top_observations, top_ops )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def gather_query_and_timing_values( columns, datum, top_observations = nil, top_ops = nil )
      datum.finish_calculations

      # observations
      columns << datum.observations.to_s
      top_observations << [ datum.observations, datum ] if top_observations

      # percentage of total observations
      columns << datum.get_percentage_of_total_observations( @total_observations )
      if @do_time_statistics

        # averaged obsvns / obsvn period
        columns << datum.get_observations_per_observation_period( @observation_period_seconds )

        # averaged obsvns / observed period
        ops = datum.get_observations_per_observed_period
        columns << ops
        top_ops << [ ops, datum ] if top_ops

        # observed period
        columns << datum.get_observed_period

        # first observation time
        columns << datum.first_observed_time.strftime('%d %b %Y %H:%M:%S')

        # last observation time
        columns << datum.last_observed_time.strftime('%d %b %Y %H:%M:%S')

        # magnitude ceiling
        columns << datum.magnitude_ceiling

        # magnitude floor
        columns << datum.magnitude_floor

        # magnitude average
        columns << datum.get_magnitude_average

        # magnitude standard deviation
        columns << to_columnar_data( datum.get_magnitude_standard_deviation( @interval_seconds_to_increment != nil ) )

        # magnitude cv percentage
        columns << to_columnar_data( datum.get_magnitude_cv_percentage( @interval_seconds_to_increment != nil ) )

        # longest interval
        columns << to_columnar_data( datum.longest_interval )

        # shortest interval
        columns << to_columnar_data( datum.shortest_interval )

        # interval count
        columns << to_columnar_data( datum.interval_count )

        # interval average
        columns << to_columnar_data( datum.get_interval_average )

        # interval standard deviation
        columns << to_columnar_data( datum.get_interval_standard_deviation( @interval_seconds_to_increment != nil ) )

        # interval cv percentage
        columns << to_columnar_data( datum.get_interval_cv_percentage( @interval_seconds_to_increment != nil ) )

        # longest run
        columns << datum.longest_run

        # shortest run
        columns << datum.shortest_run

        # run count
        columns << datum.run_count

        # run average
        columns << datum.get_run_average

        # run standard deviation
        columns << to_columnar_data( datum.get_run_standard_deviation( @interval_seconds_to_increment != nil ) )

        # run cv percentage
        columns << to_columnar_data( datum.get_run_cv_percentage( @interval_seconds_to_increment != nil ) )
      end
    end

    def gather_query_and_timing_headers( headers )
      headers << "Observations"
      headers << "% of Total Observations"
      if @do_time_statistics
        headers << "Avgd Obsvns / Obsvn Period"
        headers << "Avgd Obsvns / Observed Period"
        headers << "Observed Period"
        headers << "First Observation Time"
        headers << "Last Observation Time"
        headers << "Magnitude Ceiling"
        headers << "Magnitude Floor"
        headers << "Magnitude Average"
        headers << "Magnitude Std Deviation"
        headers << "Magnitude CV %"
        headers << "Longest Interval"
        headers << "Shortest Interval"
        headers << "Interval Count"
        headers << "Interval Average"
        headers << "Interval Std Deviation"
        headers << "Interval CV %"
        headers << "Longest Run"
        headers << "Shortest Run"
        headers << "Run Count"
        headers << "Run Average"
        headers << "Run Std Deviation"
        headers << "Run CV %"
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

    def to_columnar_data( data )
      retval = NotApplicable
      if data
        retval = data
      end
      return retval
    end

  end

end
