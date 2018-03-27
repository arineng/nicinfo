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
  # TODO get rid of explicit exits
  # TODO make CSV/TSV output compliant with RFC4180
  # TODO block statistics by /24 and /56
  # TODO check track redirect URLs too
  # TODO check track error count per URL
  # TODO check track avg response time per URL
  # TODO check when no files in bulk-in glob, throw error
  # TODO check if no bulkip out given, thrown an error
  # TODO check add feature to set sorted line buffer size
  # TODO check change configuration of bulkip to its own YAML file

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

    OverallStats = Struct.new( :magnitude, :interval, :run )

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
    # overall stat objects
    attr_accessor :overall_interval_stats, :overall_run_stats, :overall_magnitude_stats

    def initialize( time, overall_stats )
      @overall_magnitude_stats = overall_stats.magnitude
      @overall_interval_stats = overall_stats.interval
      @overall_run_stats = overall_stats.run
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
            @overall_interval_stats.datum( interval )
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
            @overall_run_stats.datum( @run )
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
          @overall_magnitude_stats.datum( @magnitude )
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
      @overall_magnitude_stats.datum( @magnitude )
      if @run > 1
        @longest_run = @run if @longest_run < @run
        @run_count = @run_count + 1
        @run_sum = @run_sum + @run
        @run_sum_squared = @run_sum_squared + @run**2
        @overall_run_stats.datum( @run )
      elsif @run_count == 0
        @run_count = 1
        @run_sum = 1
        @run_sum_squared = 1
        @overall_run_stats.datum( 1 )
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

    attr_accessor :cn, :summary_data

    def initialize( ipnetwork, time, overall_stats )
      @cn = ipnetwork.get_cn
      @summary_data = ipnetwork.summary_data
      super( time, overall_stats )
    end

  end

  class BulkIPBlock < BulkIPObservation

    attr_accessor :cidrstring, :bulkipnetwork, :bulkiplisted

    def initialize( cidrstring, time, bulkipnetwork, bulkiplisted, overall_stats )
      @bulkiplisted = bulkiplisted
      @bulkipnetwork = bulkipnetwork
      @cidrstring = cidrstring
      super( time, overall_stats )
    end

    def observed( time )
      super( time )
      @bulkipnetwork.observed( time ) if @bulkipnetwork
      @bulkiplisted.observed( time ) if @bulkiplisted
    end

  end

  class BulkIPListed < BulkIPObservation

    attr_accessor :summary_data

    def initialize( ipnetwork, time, overall_stats )
      @summary_data = ipnetwork.summary_data
      super( time, overall_stats )
    end

  end

  class BulkIPData

    attr_accessor :net_data, :listed_data, :block_data, :appctx, :network_lookups
    attr_accessor :interval_seconds_to_increment, :second_to_sample, :total_intervals, :do_sampling
    attr_accessor :top_scores, :overall_block_stats, :overall_network_stats, :overall_listedname_stats

    HostColumnHeaders = [ "Host", "Total Queries", "Avg QPS", "Avg Response Time" ]
    NotApplicable = "N/A"

    # result codes from query_for_net?
    NetNotFound = 0
    NetAlreadyRetreived = 1
    NetNotFoundBetweenIntervals = 2

    #v4 non global unicast space
    V4_MULTICAST_RESERVED = IPAddr.new( "224.0.0.0/3" )
    V4_PRIVATE_10 = IPAddr.new( "10.0.0.0/8" )
    V4_PRIVATE_192 = IPAddr.new( "192.168.0.0/16" )
    V4_LOOPBACK = IPAddr.new( "127.0.0.0/8" )
    V4_PRIVATE_172 = IPAddr.new( "172.16.0.0/12" )
    V4_LINK_LOCAL = IPAddr.new( "169.254.0.0/16" )

    #v6 global unicast space
    V6_GLOBAL_UNICAST = IPAddr.new( "2000::/3" )

    TopScores = Struct.new( :observations, :obsvnspersecond, :magnitude )
    Statistics = Struct.new( :observations, :observed_period, :magnitude_ceiling, :magnitude_floor,
                             :shortest_interval, :longest_interval, :interval_count, :shortest_run, :longest_run, :run_count )
    Percentiles = Struct.new( :magnitudes, :intervals, :runs )
    Rank = Struct.new( :low, :high, :percentile )

    def initialize( appctx )
      @appctx = appctx
      @do_sampling = false
      @top_scores = 100
      @overall_block_stats = NicInfo::BulkIPObservation::OverallStats.new( NicInfo::Stat.new, NicInfo::Stat.new, NicInfo::Stat.new )
      @overall_network_stats = NicInfo::BulkIPObservation::OverallStats.new( NicInfo::Stat.new, NicInfo::Stat.new, NicInfo::Stat.new )
      @overall_listedname_stats = NicInfo::BulkIPObservation::OverallStats.new( NicInfo::Stat.new, NicInfo::Stat.new, NicInfo::Stat.new )
      @block_data = NicInfo::NetTree.new
      @listed_data = Hash.new
      @net_data = Array.new
      @v4_1918 = 0
      @v4_link_local = 0
      @v4_loopback = 0
      @v4_multicast = 0
      @v6_unallocated = 0
      @non_global_unicast = 0
      @network_lookups = 0
      @total_observations = 0
      @total_fetch_errors = 0
      @total_ip_errors = 0
      @total_time_errors = 0
    end

    def new_statistics
      Statistics.new( NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new,
                      NicInfo::Stat.new )
    end

    def sort_array_by_top( array, top_number )
      retval = array.sort_by do |i|
        i[0] * -1
      end
      return retval.first( top_number )
    end

    def sort_tops( tops )
      tops.observations = sort_array_by_top( tops.observations, @top_scores )
      tops.obsvnspersecond = sort_array_by_top( tops.obsvnspersecond, @top_scores )
      tops.magnitude = sort_array_by_top( tops.magnitude, @top_scores )
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
      @do_sampling = true
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
      retval = true
      if V4_MULTICAST_RESERVED.include?( ipaddr )
        @v4_multicast += 1
        retval = false
      elsif V4_PRIVATE_10.include?( ipaddr ) || V4_PRIVATE_172.include?( ipaddr ) || V4_PRIVATE_192.include?( ipaddr )
        @v4_1918 += 1
        retval = false
      elsif V4_LOOPBACK.include?( ipaddr )
        @v4_loopback +=1
        retval = false
      elsif V4_LINK_LOCAL.include?( ipaddr )
        @v4_link_local += 1
        retval = false
      elsif ipaddr.ipv6? && !( V6_GLOBAL_UNICAST.include?( ipaddr ) )
        @v6_unallocated += 1
        retval = false
      end
      @non_global_unicast = @non_global_unicast + 1 unless retval
      return retval
    end


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
      end

      @total_observations = @total_observations + 1 if retval
      observed_time( time )

      # if doing sampling, note that
      if retval == NetNotFound && @do_sampling && time.to_i != @second_to_sample.to_i
        @appctx.logger.trace( "retreival unnecessary outside of sampling time" )
        retval = NetNotFoundBetweenIntervals
      end
      return retval

    end

    def observe_network( ipnetwork, time, requested_url = nil )


      found = false
      cidrs = ipnetwork.summary_data[ NicInfo::CommonSummary::CIDRS ]
      cidrs.each do |cidr|
        b = @block_data.lookup_net( cidr )
        if b
          b.observed( time )
          @appctx.logger.trace( "double observation with #{cidr} block")
          found = true
        end
      end

      unless found
        if requested_url && !ipnetwork.summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ]
          l = NicInfo.service_operator_from_link( requested_url )
          ipnetwork.summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ] = l if l
        end

        bulkipnetwork = BulkIPNetwork.new( ipnetwork, time, @overall_network_stats )
        @net_data << bulkipnetwork

        listed_name = ipnetwork.summary_data[ NicInfo::CommonSummary::LISTED_NAME ]
        listed_name = NotApplicable unless listed_name
        bulkiplisted = @listed_data[ listed_name ]
        unless bulkiplisted
          bulkiplisted = BulkIPListed.new( ipnetwork, time, @overall_listedname_stats )
          @listed_data[ listed_name ] = bulkiplisted
        end

        cidrs = ipnetwork.summary_data[ NicInfo::CommonSummary::CIDRS ]
        cidrs.each do |cidr|
          b = @block_data.lookup_net( cidr )
          b = BulkIPBlock.new( cidr, time, bulkipnetwork, bulkiplisted, @overall_block_stats )
          @block_data.insert( cidr, b )
          @appctx.logger.trace( "inserting #{cidr} block")
        end

        @network_lookups = @network_lookups + 1

      end

      @total_observations = @total_observations + 1
      observed_time( time )

    end

    def observe_unknown_network( ipaddr, time )
      if ipaddr.ipv6?
        cidr = "#{ipaddr.mask(56).to_s}/56"
      else
        cidr = "#{ipaddr.mask(24).to_s}/24"
      end
      b = @block_data.lookup_net( cidr )
      if b
        b.observed( time )
        @appctx.logger.trace( "double observation with unknown #{cidr} block")
      else
        b = BulkIPBlock.new( cidr, time, nil, nil, @overall_block_stats )
        @block_data.insert( cidr, b )
        @appctx.logger.trace( "inserting unknown #{cidr} block")
      end
      @total_observations = @total_observations + 1
      @total_fetch_errors = @total_fetch_errors + 1
    end

    def ip_error( ip )
      @total_ip_errors = @total_ip_errors + 1
    end

    def time_error( time )
      @total_time_errors = @total_time_errors + 1
    end

    def gather_service_operator( hash, summary_data )
      if summary_data
        hash[ summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ] ] += 1
      end
    end

    def gather_percentiles( collection )
      interval_averages = Array.new
      magnitude_averages = Array.new
      run_averages = Array.new
      collection.each do |datum|
        datum.finish_calculations
        a = datum.get_interval_average
        interval_averages << a if a
        magnitude_averages << datum.get_magnitude_average
        run_averages << datum.get_run_average
      end
      interval_averages.sort!
      magnitude_averages.sort!
      run_averages.sort!
      interval_ranks = gather_ranks( interval_averages )
      magnitude_ranks = gather_ranks( magnitude_averages )
      run_ranks = gather_ranks( run_averages )
      return Percentiles.new( magnitude_ranks, interval_ranks, run_ranks )
    end

    def gather_ranks( array )
      ranks = Array.new
      tenth = array.length / 10
      counter = 0
      10.times do |i|
        low = array[ counter ]
        counter += tenth
        if i == 9
          high = array[ array.length - 1 ]
        else
          high = array[ counter - 1 ]
        end
        rank = ( i ) * 10
        ranks << Rank.new( low, high, rank )
      end
      return ranks
    end

    def output_tsv( file_name )
      output_column_sv( file_name, ".tsv", "\t" )
    end

    def output_csv( file_name )
      output_column_sv( file_name, ".csv", "," )
    end

    def output_column_sv( file_name, extension, seperator )

      # prelim values
      @appctx.logger.mesg( "Preparing Data")
      if @first_observed_time != nil && @last_observed_time != nil
        @observation_period_seconds = @last_observed_time.to_i - @first_observed_time.to_i + 1
      else
        @observation_period_seconds = nil
      end
      block_so_count = Hash.new( 0 )
      network_so_count = Hash.new( 0 )
      listedname_so_count = Hash.new( 0 )
      # NOTE -----------------------
      # NOTE: gather statistics also calls datum.finish_calculations
      # NOTE -----------------------
      if @do_time_statistics
        block_percentiles = gather_percentiles( @block_data )
        network_percentiles = gather_percentiles( @net_data )
        listedname_percentiles = gather_percentiles( @listed_data.values )
      end

      n = file_name+"-blocks"+extension
      @appctx.logger.mesg( "writing file #{n}")
      top_blocks = TopScores.new( Array.new, Array.new, Array.new )
      block_stats = new_statistics
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      @block_data.each do |datum|
        f.puts( output_block_columns(datum, seperator, block_percentiles, top_blocks, block_stats ) )
        sort_tops( top_blocks )
        gather_service_operator( block_so_count, datum.bulkipnetwork.summary_data ) if datum.bulkipnetwork
      end
      puts_signature( f )
      f.close

      n = file_name+"-networks"+extension
      @appctx.logger.mesg( "writing file #{n}")
      top_networks = TopScores.new( Array.new, Array.new, Array.new )
      network_stats = new_statistics
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      @net_data.each do |datum|
        f.puts( output_network_columns( datum, seperator, network_percentiles, top_networks, network_stats ) )
        sort_tops( top_networks )
        gather_service_operator( network_so_count, datum.summary_data )
      end
      puts_signature( f )
      f.close

      n = file_name+"-listednames"+extension
      @appctx.logger.mesg( "writing file #{n}")
      top_listednames = TopScores.new( Array.new, Array.new, Array.new )
      listedname_stats = new_statistics
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      @listed_data.values.each do |datum |
        f.puts( output_listed_columns( datum, seperator, listedname_percentiles, top_listednames, listedname_stats ) )
        sort_tops( top_listednames )
        gather_service_operator( listedname_so_count, datum.summary_data )
      end
      puts_signature( f )
      f.close

      # top observations
      n = "#{file_name}-blocks-top#{@top_scores}-observations#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      top_blocks.observations.each do |item|
        f.puts( output_block_columns(item[1], seperator, block_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-networks-top#{@top_scores}-observations#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      top_networks.observations.each do |item|
        f.puts( output_network_columns( item[1], seperator, network_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-listednames-top#{@top_scores}-observations#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      top_listednames.observations.each do |item |
        f.puts( output_listed_columns( item[1], seperator, listedname_percentiles,nil, nil ) )
      end
      puts_signature( f )
      f.close


      # top observations per second
      n = "#{file_name}-blocks-top#{@top_scores}-obsvnspersecond#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      top_blocks.obsvnspersecond.each do |item|
        f.puts( output_block_columns(item[1], seperator, block_percentiles,  nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-networks-top#{@top_scores}-obsvnspersecond#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      top_networks.obsvnspersecond.each do |item|
        f.puts( output_network_columns( item[1], seperator, network_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-listednames-top#{@top_scores}-obsvnspersecond#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      top_listednames.obsvnspersecond.each do |item |
        f.puts( output_listed_columns( item[1], seperator, listedname_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      # top magnitude
      n = "#{file_name}-blocks-top#{@top_scores}-magnitude#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_block_column_headers(seperator ) )
      top_blocks.magnitude.each do |item|
        f.puts( output_block_columns(item[1], seperator, block_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-networks-top#{@top_scores}-magnitude#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_network_column_headers( seperator ) )
      top_networks.magnitude.each do |item|
        f.puts( output_network_columns( item[1], seperator, network_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      n = "#{file_name}-listednames-top#{@top_scores}-magnitude#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      f.puts( output_listed_column_headers( seperator ) )
      top_listednames.magnitude.each do |item |
        f.puts( output_listed_columns( item[1], seperator, listedname_percentiles, nil, nil ) )
      end
      puts_signature( f )
      f.close

      # block statistics
      n = "#{file_name}-blocks-statistics#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      output_statistics( f, block_stats, seperator )
      output_overall_stats( f, @overall_block_stats, seperator )
      f.puts
      output_percentiles( f, block_percentiles, seperator )
      puts_signature( f )
      f.close

      # network statistics
      n = "#{file_name}-networks-statistics#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      output_statistics( f, network_stats, seperator )
      output_overall_stats( f, @overall_network_stats, seperator )
      f.puts
      output_percentiles( f, network_percentiles, seperator )
      puts_signature( f )
      f.close

      # listedname statistics
      n = "#{file_name}-listednames-statistics#{extension}"
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      output_statistics( f,listedname_stats , seperator )
      output_overall_stats( f, @overall_listedname_stats, seperator )
      f.puts
      output_percentiles( f, listedname_percentiles, seperator )
      puts_signature( f )
      f.close

      # meta
      n = file_name+"-meta"+extension
      @appctx.logger.mesg( "writing file #{n}")
      f = File.open( n, "w" );
      service_operators = block_so_count.keys | network_so_count.keys | listedname_so_count.keys
      so_headers = [ "Service Operator" ] + service_operators
      f.puts( so_headers.join( seperator ))
      so_columns = [ "Blocks" ]
      service_operators.each do |so|
        so_columns << block_so_count[ so ]
      end
      f.puts( so_columns.join( seperator ) )
      so_columns = [ "Networks" ]
      service_operators.each do |so|
        so_columns << network_so_count[ so ]
      end
      f.puts( so_columns.join( seperator ) )
      so_columns = [ "Listed Names" ]
      service_operators.each do |so|
        so_columns << listedname_so_count[ so ]
      end
      f.puts( so_columns.join( seperator ) )


      unless @appctx.tracked_hosts.empty?
        f.puts
        response_type_keys = []
        @appctx.tracked_hosts.each_value do |tracker|
          response_type_keys = response_type_keys | tracker.response_types.keys
        end
        host_headers = HostColumnHeaders + response_type_keys
        f.puts( host_headers.join( seperator ) )
        @appctx.tracked_hosts.each_value do |tracker|
          f.puts( output_tracked_hosts( tracker, response_type_keys, seperator ) )
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
      f.puts( output_total_row( "IPv4 Link Local IPs", @v4_link_local, seperator ) )
      f.puts( output_total_row( "IPv4 Loopback IPs", @v4_loopback, seperator ) )
      f.puts( output_total_row( "IPv4 Multicast IPs", @v4_multicast, seperator ) )
      f.puts( output_total_row( "IPv4 RFC 1918 IPs", @v4_1918, seperator ) )
      f.puts( output_total_row( "IPv6 Unallocated IPs", @v6_unallocated, seperator ) )
      f.puts( output_total_row( "Network Lookups", @network_lookups, seperator ) )
      f.puts( output_total_row( "Total Fetch Errors", @total_fetch_errors, seperator ) )
      f.puts( output_total_row( "Total IP Address Parse Errors", @total_ip_errors, seperator ) )
      f.puts( output_total_row( "Total Time Parse Errors", @total_time_errors, seperator ) )
      f.puts( output_total_row( "Analysis Start Time", @start_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Analysis End Time", @end_time.strftime('%d %b %Y %H:%M:%S'), seperator ) )
      f.puts( output_total_row( "Total Sampling Intervals", @total_intervals, seperator ) ) if @do_sampling

      unless @appctx.errored_uris.empty?
        f.puts
        f.puts( ["Error", "URI" ].join( seperator ))
        @appctx.errored_uris.each do |item|
          f.puts( item.join( seperator ) )
        end
      end

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

    def output_block_columns(datum, seperator, percentiles, tops, stats )
      columns = Array.new
      columns << datum.cidrstring
      gather_query_and_timing_values( columns, datum, percentiles, tops, stats )
      if datum.bulkipnetwork
        summary_data = datum.bulkipnetwork.summary_data
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

    def output_network_columns( datum, seperator, percentiles, tops, stats )
      columns = Array.new
      columns << datum.cn
      gather_query_and_timing_values( columns, datum, percentiles,  tops, stats )
      summary_data = datum.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_listed_columns( datum, seperator, percentiles, tops, stats )
      columns = Array.new
      summary_data = datum.summary_data
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_NAME ], seperator )
      gather_query_and_timing_values( columns, datum, percentiles, tops, stats )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::LISTED_COUNTRY ], seperator )
      columns << to_columnar_string( summary_data[ NicInfo::CommonSummary::ABUSE_EMAIL ], seperator )
      return columns.join( seperator )
    end

    def output_percentiles( file, percentiles, seperator )
      headers = [ "Percentile" ]
      headers << "Magnitude Avg Low" << "Magnitude Avg High"
      headers << "Interval Avg Low" << "Interval Avg High"
      headers << "Run Avg Low" << "Run Avg High"
      file.puts( headers.join( seperator ))
      10.times do |i|
        columns = [ i ]
        columns << percentiles.magnitudes[ i ].low << percentiles.magnitudes[ i ].high
        columns << percentiles.intervals[ i ].low << percentiles.intervals[ i ].high
        columns << percentiles.runs[ i ].low << percentiles.runs[ i ].high
        file.puts( columns.join( seperator ) )
      end
    end

    def get_rank( ranks, value )
      retval = NotApplicable
      ranks.each do |rank|
        if value >= rank.low && value <= rank.high
          retval = rank.percentile
          break
        end
      end if value != nil
      return retval
    end

    def gather_query_and_timing_values( columns, datum, percentiles, tops = nil, stats = nil )

      # observations
      columns << datum.observations.to_s
      tops.observations << [ datum.observations, datum ] if tops
      stats.observations.datum( datum.observations ) if stats

      # percentage of total observations
      columns << datum.get_percentage_of_total_observations( @total_observations )
      if @do_time_statistics

        # averaged obsvns / obsvn period
        columns << datum.get_observations_per_observation_period( @observation_period_seconds )

        # averaged obsvns / observed period
        ops = datum.get_observations_per_observed_period
        columns << ops
        tops.obsvnspersecond << [ ops, datum ] if tops

        # observed period
        columns << datum.get_observed_period
        stats.observed_period.datum( datum.get_observed_period ) if stats

        # first observation time
        columns << datum.first_observed_time.strftime('%d %b %Y %H:%M:%S')

        # last observation time
        columns << datum.last_observed_time.strftime('%d %b %Y %H:%M:%S')

        # magnitude ceiling
        columns << datum.magnitude_ceiling
        tops.magnitude << [ datum.magnitude_ceiling, datum ] if tops
        stats.magnitude_ceiling.datum( datum.magnitude_ceiling ) if stats

        # magnitude floor
        columns << datum.magnitude_floor
        stats.magnitude_floor.datum( datum.magnitude_floor ) if stats

        # magnitude average
        magnitude_average = datum.get_magnitude_average
        columns << magnitude_average

        # magnitude average rank
        columns << get_rank( percentiles.magnitudes, magnitude_average)

        # magnitude standard deviation
        columns << to_columnar_data( datum.get_magnitude_standard_deviation( @do_sampling ) )

        # magnitude cv percentage
        columns << to_columnar_data( datum.get_magnitude_cv_percentage( @do_sampling ) )

        # longest interval
        columns << to_columnar_data( datum.longest_interval )
        stats.longest_interval.datum( datum.longest_interval ) if stats && datum.longest_interval

        # shortest interval
        columns << to_columnar_data( datum.shortest_interval )
        stats.shortest_interval.datum( datum.shortest_interval ) if stats && datum.shortest_interval

        # interval count
        columns << to_columnar_data( datum.interval_count )
        stats.interval_count.datum( datum.interval_count ) if stats && datum.interval_count

        # interval average
        interval_average = datum.get_interval_average
        columns << to_columnar_data( interval_average )

        # inteval average rank
        columns << get_rank( percentiles.intervals, interval_average )

        # interval standard deviation
        columns << to_columnar_data( datum.get_interval_standard_deviation( @do_sampling ) )

        # interval cv percentage
        columns << to_columnar_data( datum.get_interval_cv_percentage( @do_sampling ) )

        # longest run
        columns << datum.longest_run
        stats.longest_run.datum( datum.longest_run ) if stats

        # shortest run
        columns << datum.shortest_run
        stats.shortest_run.datum( datum.shortest_run ) if stats

        # run count
        columns << datum.run_count
        stats.run_count.datum( datum.run_count ) if stats

        # run average
        run_average = datum.get_run_average
        columns << run_average
        columns << get_rank( percentiles.runs, run_average )

        # run average rank

        # run standard deviation
        columns << to_columnar_data( datum.get_run_standard_deviation( @do_sampling ) )

        # run cv percentage
        columns << to_columnar_data( datum.get_run_cv_percentage( @do_sampling ) )
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
        headers << "Magnitude Avg Percentile"
        headers << "Magnitude Std Deviation"
        headers << "Magnitude CV %"
        headers << "Longest Interval"
        headers << "Shortest Interval"
        headers << "Interval Count"
        headers << "Interval Average"
        headers << "Interval Avg Percentile"
        headers << "Interval Std Deviation"
        headers << "Interval CV %"
        headers << "Longest Run"
        headers << "Shortest Run"
        headers << "Run Count"
        headers << "Run Average"
        headers << "Run Avg Percentile"
        headers << "Run Std Deviation"
        headers << "Run CV %"
      end
    end

    def output_statistics( file, statistics, seperator )
      file.puts( output_statistics_headers( seperator ))
      file.puts( output_stat_obj( "Observations", statistics.observations, seperator ) )
      if @do_time_statistics
        file.puts( output_stat_obj( "Observed Period", statistics.observed_period, seperator ) )
        file.puts( output_stat_obj( "Magnitude Ceiling", statistics.magnitude_ceiling, seperator ) )
        file.puts( output_stat_obj( "Magnitude Floor", statistics.magnitude_floor, seperator ) )
        file.puts( output_stat_obj( "Shortest Interval", statistics.shortest_interval, seperator ) )
        file.puts( output_stat_obj( "Longest Interval", statistics.longest_interval, seperator ) )
        file.puts( output_stat_obj( "Interval Count", statistics.interval_count, seperator ) )
        file.puts( output_stat_obj( "Shortest Run", statistics.shortest_run, seperator ) )
        file.puts( output_stat_obj( "Longest Run", statistics.longest_run, seperator ) )
        file.puts( output_stat_obj( "Run Count", statistics.run_count, seperator ) )
      end
    end

    def output_overall_stats( file, overall_stats, seperator )
      if @do_time_statistics
        file.puts( output_stat_obj( "Magnitude", overall_stats.magnitude, seperator ) )
        file.puts( output_stat_obj( "Interval", overall_stats.interval, seperator ) )
        file.puts( output_stat_obj( "Run", overall_stats.run, seperator ) )
      end
    end

    def output_stat_obj( data_type, stat, seperator )
      columns = Array.new
      columns << data_type
      columns << stat.get_average
      columns << stat.get_std_dev( @do_sampling )
      columns << stat.get_percentage( stat.get_cv( @do_sampling ) )
      return columns.join( seperator )
    end

    def output_statistics_headers( seperator )
      headers = Array.new
      headers << "Data Type"
      headers << "Average"
      headers << "Std. Deviation"
      headers << "CV Percentage"
      return headers.join( seperator )
    end

    def output_tracked_hosts( tracker, response_type_keys, seperator )
      columns = Array.new
      columns << tracker.host
      columns << tracker.total_queries
      columns << tracker.get_average_query_rate
      columns << tracker.get_average_response_time
      response_type_keys.each do |key|
        columns << tracker.response_types[ key ]
      end
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
