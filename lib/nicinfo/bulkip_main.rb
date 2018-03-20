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
require 'nicinfo/bulkip_infile'
require 'nicinfo/bulkip_data'

module NicInfo

  class BulkIPMain

    attr_accessor :appctx, :file_in_set, :tsv_output, :csv_output, :top_scores, :sampling_interval
    attr_accessor :sorted_line_buffer_size

    def initialize( appctx )
      @appctx = appctx
    end

    def configure( file_name )
      retval = false
      if File.exists?( file_name )
        @appctx.load_config( file_name, false )
        retval = true
      else
        @appctx.logger.mesg( "Writing Bulk IP template configuration #{file_name}")
        f = File.open( file_name, "w" )
        f.puts( @@bulkip_config )
        f.close
      end
      return retval
    end

    def setup

      # get the input files and figure out if they will work
      @file_in_set = NicInfo::BulkIPInFileSet.new( @appctx )
      list = @appctx.config[ NicInfo::BULKIP ][ NicInfo::INPUT_FILES ]
      if list == nil
        raise "No bulkip input files specified"
      elsif list.is_a?( Array )
        list.each do |item|
          @file_in_set.add_to_file_list( item )
        end
      else
        @file_in_set.add_to_file_list( list )
      end

      # verify that output has been specified
      @tsv_output = @appctx.config[ NicInfo::BULKIP ][ NicInfo::TSV_OUTPUT ]
      @csv_output = @appctx.config[ NicInfo::BULKIP ][ NicInfo::CSV_OUTPUT ]
      if @tsv_output == nil and @csv_output == nil
        raise "No TSV or CSV output has been specified"
      end

      @top_scores = @appctx.config[ NicInfo::BULKIP ][ NicInfo::TOP_SCORES ]
      @sampling_interval = @appctx.config[ NicInfo::BULKIP ][ NicInfo::SAMPLING_INTERVAL ]
      @sorted_line_buffer_size = @appctx.config[ NicInfo::BULKIP ][ NicInfo::SORTED_LINE_BUFFER_SIZE ]
      @file_in_set.line_buffer_size = @sorted_line_buffer_size if @sorted_line_buffer_size
    end

    def execute
      rdap_query = NicInfo::RDAPQuery.new( @appctx )
      bulkip_data = NicInfo::BulkIPData.new( @appctx )
      bulkip_data.top_scores = @top_scores if @top_scores
      bulkip_data.set_interval_seconds_to_increment( @sampling_interval ) if @sampling_interval
      bulkip_data.note_times_in_data if @file_in_set.timing_provided
      bulkip_data.note_start_time
      lines_processed = 0
      begin
        bulkip_data.note_new_file
        @file_in_set.foreach_by_time do |ip,time,lineno,file_name|
          @appctx.logger.trace( "time: #{time} bulk ip: #{ip} line no: #{lineno} file: #{file_name}")
          if lines_processed % 1000 == 0
            @appctx.logger.mesg( "Lines processed: #{lines_processed}. Time: #{time}. Network lookups: #{bulkip_data.network_lookups}. Currently on line #{lineno} of #{file_name}.")
          end
          lines_processed = lines_processed + 1
          if ( time != nil && @file_in_set.timing_provided ) || !@file_in_set.timing_provided
            begin
              ipaddr = IPAddr.new( ip )
              if !bulkip_data.valid_to_query?( ipaddr )
                @appctx.logger.trace( "skipping non-global-unicast address #{ip}")
              else
                if bulkip_data.query_for_net?(ipaddr, time ) == NicInfo::BulkIPData::NetNotFound
                  query_value = [ ip ]
                  qtype = QueryType::BY_IP4_ADDR
                  qtype = QueryType::BY_IP6_ADDR if ipaddr.ipv6?
                  rdap_response = rdap_query.do_rdap_query( query_value, qtype, nil )
                  if ! rdap_response.error_state
                    rtype = get_query_type_from_result( rdap_response.json_data )
                    if rtype == QueryType::BY_IP
                      ipnetwork = NicInfo::process_ip( rdap_response.json_data, @appctx )
                      bulkip_data.observe_network( ipnetwork, time, rdap_response.requested_url )
                    else
                      bulkip_data.observe_unknown_network( ipaddr, time )
                    end
                  else
                    bulkip_data.observe_unknown_network( ipaddr, time )
                  end
                end
              end
            rescue IPAddr::Error
              bulkip_data.ip_error( ip )
              @appctx.logger.mesg( "Invalid IP address '#{ip}'", NicInfo::AttentionType::ERROR )
            end
          else
            bulkip_data.time_error( time )
            @appctx.logger.mesg( "Invalid time value", NicInfo::AttentionType::ERROR )
          end
        end
      rescue Interrupt
        @appctx.logger.mesg( "Processing interrupted.")
      end
      bulkip_data.note_end_time
      bulkip_data.output_csv( @csv_output ) if @csv_output
      bulkip_data.output_tsv( @tsv_output ) if @tsv_output
      @file_in_set.done
      @appctx.logger.mesg( "Bulk IP Lookups Finished.")
    end

    @@bulkip_config = <<BULKIP_CONFIG
bulkip:

  # Specifies the input files containing IP addresses and
  # optional timing information. Each item can be an explicit
  # file, a file glob pattern (as in shell globs), or a directory.
  # All files are opened and read together, collated by the time
  # value in the lines of the file, if present.
  input_files:
    - logs/*.log
    - other_logs/

  # If time values are present, all input files are collated together
  # by ascending time value. Each file must have time values given in
  # ascending order. In cases where this cannot be completely assured,
  # each file is buffered and sorted as it is read. This value controls
  # the size of this line buffer. The default is 5 lines.
  #sorted_line_buffer_size: 5

  # The basename of the TSV files that will be generated. Each file
  # will have the .tsv extension added to it.
  # Both TSV and CSV may be specified, but atleast one is required.
  tsv_output: some_dir/some_base_name

  # The basename of the CSV files that will be generated. Each file
  # will have the .csv extension added to it.
  # Both TSV and CSV may be specified, but atleast one is required.
  csv_output: some_dir/some_base_name

  # Separate files are generated sorted by the top number of observatons,
  # observations per observed period, and magnitude. By default, the file
  # is limited to the top 100. This value can change the limitation value.
  #top_scores: 100

  # If looking up each line of the input files is not feasible, then
  # sampling can be done. This value specifies the number of seconds
  # to randomly skip according to the time values on the lines in the
  # input files.
  #sampling_interval: 60

output:

  # possible values are NONE, SOME, ALL
  messages: SOME

  # If specified, messages goes to this file
  # otherwise, leave it commented out to go to stderr
  #messages_file: /tmp/NicInfo.messages

  # Page output with system pager when appropriate.
  pager: false

cache:

  # The maximum age an item from the cache will be used.
  # This value is in seconds
  cache_expiry: 604800

  # The maximum age an item will be in the cache before it is evicted
  # when the cache is cleaned.
  # This value is in seconds
  cache_eviction: 604800

  # Controls the caching of objects inside of other objects.
  deep_object_caching: false

security:

  # if HTTPS cannot be established, try HTTP
  try_insecure: true

BULKIP_CONFIG

  end

end
