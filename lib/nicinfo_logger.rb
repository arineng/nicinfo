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

# The run_pager code came from http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
# and is credited to Nathan Weizenbaum

require 'enum'

module ARINcli

  # Controls the type of informational messages that are about the function of the application.
  class MessageLevel < ARINcli::Enum

    # no messages
    MessageLevel.add_item(:NO_MESSAGES, "NONE")

    # some messages
    MessageLevel.add_item(:SOME_MESSAGES, "SOME")

    # all messages
    MessageLevel.add_item(:ALL_MESSAGES, "ALL")

  end

  # Controls the amount of data
  class DataAmount < ARINcli::Enum

    # a terse amount of data
    DataAmount.add_item(:TERSE_DATA, "TERSE")

    # a normal amount of data
    DataAmount.add_item(:NORMAL_DATA, "NORMAL")

    # an extra amount of data
    DataAmount.add_item(:EXTRA_DATA, "EXTRA")

  end

  # A logger for this application.
  class Logger

    attr_accessor :message_level, :data_amount, :message_out, :data_out, :item_name_length, :item_name_rjust, :pager

    def initialize

      @message_level = MessageLevel::SOME_MESSAGES
      @data_amount = DataAmount::NORMAL_DATA
      @message_out = $stdout
      @data_out = $stdout
      @item_name_length = 25
      @item_name_rjust = true

      @message_last_written_to = false
      @data_last_written_to = false

    end

    def validate_message_level
      raise ArgumentError, "Message log level not defined" if @message_level == nil
      raise ArgumentError, "Unknown message log level '" + @message_level.to_s + "'" if !MessageLevel.has_value?(@message_level.to_s)
    end

    def validate_data_amount
      raise ArgumentError, "Data log level not defined" if @data_amount == nil
      raise ArgumentError, "Unknown data log level '" + @data_amount.to_s + "'" if !DataAmount.has_value?(@data_amount.to_s)
    end

    def start_data_item
      if (@data_last_written_to)
        @data_out.puts
      elsif (@data_out == $stdout && @message_out == $stderr && @message_last_written_to)
        @data_out.puts
      elsif (@data_out == @message_out && @message_last_written_to)
        @data_out.puts
      end
    end

    def end_data_item
      #do nothing for now
    end

    def end_run
      start_data_item
    end

    # Outputs at the :SOME_MESSAGES level
    def mesg message
      validate_message_level()
      if (@message_level != MessageLevel::NO_MESSAGES)
        log_info("# " + message.to_s)
        return true
      end
      return false
    end

    # Outputs at the :ALL_MESSAGES level
    def trace message
      validate_message_level()
      if (@message_level != MessageLevel::NO_MESSAGES && @message_level != MessageLevel::SOME_MESSAGES)
        log_info("## " + message.to_s)
        return true
      end
      return false
    end

    # Outputs a datum at :TERSE_DATA level
    def terse item_name, item_value
      validate_data_amount()
      log_data(item_name, item_value)
      return true
    end

    # Outputs a data at :NORMAL_DATA level
    def datum item_name, item_value
      validate_data_amount()
      if (@data_amount != DataAmount::TERSE_DATA)
        log_data(item_name, item_value)
        return true
      end
      return false
    end

    def extra item_name, item_value
      validate_data_amount()
      if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
        log_data(item_name, item_value)
        return true
      end
      return false
    end

    def raw data_amount, raw_data
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_raw(raw_data)
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_raw(raw_data)
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_raw(raw_data)
            retval = true
          end
      end
      return retval
    end

    def log_tree_item data_amount, tree_item
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_raw(tree_item)
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_raw(tree_item)
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_raw(tree_item)
            retval = true
          end
      end
      return retval
    end

    # This code came from http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
    def run_pager
      return unless @pager
      return if RUBY_PLATFORM =~ /win32/
      return unless STDOUT.tty?

      read, write = IO.pipe

      unless Kernel.fork # Child process
        STDOUT.reopen(write)
        STDERR.reopen(write) if STDERR.tty?
        read.close
        write.close
        return
      end

      # Parent process, become pager
      STDIN.reopen(read)
      read.close
      write.close

      ENV['LESS'] = 'FSRX' # Don't page if the input is short enough

      Kernel.select [STDIN] # Wait until we have input before we start the pager
      pager = ENV['PAGER'] || 'less'
      exec pager rescue exec "/bin/sh", "-c", pager
    end

    private

    def log_info message
      if @data_last_written_to && @message_out == @data_out
        @data_out.puts
      end
      @message_out.puts(message)
      @message_last_written_to = true
      @data_last_written_to = false
    end

    def log_data item_name, item_value
      if (item_value != nil && !item_value.to_s.empty?)
        format_string = "%" + @item_name_length.to_s + "s:  %s"
        if (!@item_name_rjust)
          format_string = "%-" + @item_name_length.to_s + "s:  %s"
        end
        @data_out.puts(format(format_string, item_name, item_value))
        @data_last_written_to = true
        @message_last_written_to = false
      end
    end

    def log_raw item_value
      @data_out.puts(item_value)
      @data_last_written_to = true
      @message_last_written_to = false
    end

  end

end
