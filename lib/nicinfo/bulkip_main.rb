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

module NicInfo

  class BulkIPMain

    attr_accessor :appctx

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
