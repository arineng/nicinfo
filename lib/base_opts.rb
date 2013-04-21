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


require 'optparse'

module NicInfo

  # A class to be inherited from for added the standard optons
  class BaseOpts

    # Adds base options for OptParser
    # opts is the OptionParser
    # config is the Config.rb object
    def add_base_opts( opts, config )

      opts.separator ""
      opts.separator "Output Options:"

      opts.on( "--messages MESSAGE_LEVEL",
        "Specify the message level",
        "  none - no messages are to be output",
        "  some - some messages but not all",
        "  all  - all messages to be outupt" ) do |m|
        config.logger.message_level = m.to_s.upcase
        begin
          config.logger.validate_message_level
        rescue
          raise OptionParser::InvalidArgument, m.to_s
        end
      end

      opts.on( "--messages-out FILE",
        "FILE where messages will be written." ) do |f|
        config.logger.messages_out = f
      end

      opts.on( "--data DATA_AMOUNT",
               "Specify the amount of data",
               "  terse  - enough data to identify the object",
               "  normal - normal view of data on objects",
               "  extra  - all data about the object" ) do |d|
        config.logger.data_amount = d.to_s.upcase
        begin
          config.logger.validate_data_amount
        rescue
          raise OptionParser::InvalidArgument, d.to_s
        end
      end

      opts.on( "--data-out FILE",
               "FILE where data will be written." ) do |f|
        config.logger.data_out = f
      end

      opts.on( "-V",
               "Equivalent to --messages all and --data extra" ) do |v|
        config.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
        config.logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
      end

      opts.separator ""
      opts.separator "General Options:"

      opts.on( "-h", "--help",
        "Show this message" ) do
        config.options.help = true
      end

      return opts
    end

  end


end

