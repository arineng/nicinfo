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

# The run_pager code came from http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
# and is credited to Nathan Weizenbaum

require 'rainbow'
require 'nicinfo/enum'

module NicInfo

  # Controls the type of informational messages that are about the function of the application.
  class MessageLevel < NicInfo::Enum

    # no messages
    MessageLevel.add_item(:NO_MESSAGES, "NONE")

    # some messages
    MessageLevel.add_item(:SOME_MESSAGES, "SOME")

    # all messages
    MessageLevel.add_item(:ALL_MESSAGES, "ALL")

  end

  # Controls the amount of data
  class DataAmount < NicInfo::Enum

    # a terse amount of data
    DataAmount.add_item(:TERSE_DATA, "TERSE")

    # a normal amount of data
    DataAmount.add_item(:NORMAL_DATA, "NORMAL")

    # an extra amount of data
    DataAmount.add_item(:EXTRA_DATA, "EXTRA")

  end

  class AttentionType < NicInfo::Enum

    AttentionType.add_item(:SUCCESS, "SUCCESS" )
    AttentionType.add_item(:INFO, "INFO" )
    AttentionType.add_item(:PRIMARY, "PRIMARY" )
    AttentionType.add_item(:SECONDARY, "SECONDARY" )
    AttentionType.add_item(:ERROR, "ERROR" )

  end

  class ColorScheme < NicInfo::Enum

    # dark background
    ColorScheme.add_item(:DARK, "DARK")

    # light background
    ColorScheme.add_item(:LIGHT, "LIGHT")

    # none
    ColorScheme.add_item(:NONE, "NONE")

  end

  # A logger for this application.
  class Logger

    attr_accessor :message_level, :data_amount, :message_out, :data_out, :item_name_length, :item_name_rjust, :pager
    attr_accessor :auto_wrap, :detect_width, :default_width, :prose_name_rjust, :prose_name_length
    attr_accessor :is_less_available, :color_scheme, :rainbow

    def initialize

      @message_level = MessageLevel::SOME_MESSAGES
      @data_amount = DataAmount::NORMAL_DATA
      @color_scheme = ColorScheme::DARK
      @message_out = $stdout
      @data_out = $stdout
      @rainbow = Rainbow.new
      @item_name_length = 25
      @item_name_rjust = true
      @prose_name_length = 10
      @prose_name_rjust = true

      @message_last_written_to = false
      @data_last_written_to = false

      return if Gem.win_platform?
      #else
      @columns = get_terminal_columns( `stty -a`, @default_width )
    end

    def get_width
      return @default_width if !@detect_width
      return @columns if @columns != nil
      return @default_width
    end

    def validate_message_level
      raise ArgumentError, "Message log level not defined" if @message_level == nil
      raise ArgumentError, "Unknown message log level '" + @message_level.to_s + "'" unless MessageLevel.has_value?(@message_level.to_s)
    end

    def validate_data_amount
      raise ArgumentError, "Data log level not defined" if @data_amount == nil
      raise ArgumentError, "Unknown data log level '" + @data_amount.to_s + "'" unless DataAmount.has_value?(@data_amount.to_s)
    end

    def validate_color_scheme
      raise ArgumentError, "Color scheme not defined" if @color_scheme == nil
      raise ArgumentError, "Unknown color scheme '" + @color_scheme.to_s + "'" unless ColorScheme.has_value?(@color_scheme.to_s)
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
    def mesg message, attention_type = nil
      validate_message_level()
      if (@message_level != MessageLevel::NO_MESSAGES)
        log_info("# " + message.to_s, attention_type )
        return true
      end
      return false
    end

    # Outputs at the :ALL_MESSAGES level
    def trace message, attention_type = nil
      validate_message_level()
      if (@message_level != MessageLevel::NO_MESSAGES && @message_level != MessageLevel::SOME_MESSAGES)
        log_info("## " + message.to_s, attention_type )
        return true
      end
      return false
    end

    # Outputs a datum at :TERSE_DATA level
    def terse item_name, item_value, attention_type = nil
      validate_data_amount()
      log_data(item_name, item_value, attention_type )
      return true
    end

    # Outputs a data at :NORMAL_DATA level
    def datum item_name, item_value, attention_type = nil
      validate_data_amount()
      if (@data_amount != DataAmount::TERSE_DATA)
        log_data(item_name, item_value, attention_type )
        return true
      end
      return false
    end

    def extra item_name, item_value, attention_type = nil
      validate_data_amount()
      if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
        log_data(item_name, item_value, attention_type )
        return true
      end
      return false
    end

    def data_title title, attention_type = nil
      validate_data_amount()
      log_just title, " ", @item_name_length, @item_name_rjust, "", attention_type
      return true
    end

    def info data_amount, item_name, item_value, attention_type = nil
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_data(item_name, item_value, attention_type )
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_data( item_name, item_value, attention_type )
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_data( item_name, item_value, attention_type )
            retval = true
          end
      end
      return retval
    end

    def raw data_amount, raw_data, wrap = true, attention_type = nil
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_raw(raw_data, wrap, attention_type )
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_raw(raw_data, wrap, attention_type )
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_raw(raw_data, wrap, attention_type )
            retval = true
          end
      end
      return retval
    end

    def prose data_amount, prose_name, prose_value, attention_type = nil
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_prose prose_name, prose_value, attention_type
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_prose prose_name, prose_value, attention_type
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_prose prose_name, prose_value, attention_type
            retval = true
          end
      end
      return retval
    end

    def log_tree_item data_amount, tree_item, attention_type = nil
      retval = false
      validate_data_amount()
      case data_amount
        when DataAmount::TERSE_DATA
          log_raw(tree_item, true, attention_type )
          retval = true
        when DataAmount::NORMAL_DATA
          if (@data_amount != DataAmount::TERSE_DATA)
            log_raw(tree_item, true, attention_type )
            retval = true
          end
        when DataAmount::EXTRA_DATA
          if (@data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA)
            log_raw(tree_item, true, attention_type )
            retval = true
          end
      end
      return retval
    end

    def is_less_available?
      if @is_less_available == nil
        avail = ENV['PATH'].split(File::PATH_SEPARATOR).any? do |dir|
          File.executable?(File.join(dir, "less"))
        end
        if avail
          @is_less_available = "less"
        else
          @is_less_available = false
        end
      end
      return @is_less_available
    end

    # This code came from http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
    def run_pager
      return unless @pager
      return if Gem.win_platform?
      return unless STDOUT.tty?

      @color_scheme = ColorScheme::NONE unless is_less_available?

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
      pager = ENV['PAGER'] || is_less_available? || 'more'
      exec pager rescue exec "/bin/sh", "-c", pager
    end

    def get_terminal_columns stty_output, default_columns
      rx1 = /\s*columns\s*=\s*(\d*);/
      m = rx1.match( stty_output )
      return m[ 1 ].to_i if m
      #else
      rx2 = /\s*(\d*)\s*columns;/
      m = rx2.match( stty_output )
      return m[ 1 ].to_i if m
      rx3 = /\s*columns\s*(\d*);/
      m = rx3.match( stty_output )
      return m[ 1 ].to_i if m
      return default_columns
    end

    def break_up_line line, width
      retval = Array.new
      i = line.rindex( /\s/, width )
      if i == nil
        i = line.rindex( /\s/ )
      end
      while i != nil do
        retval << line[ 0, i ]
        line = line[ i+1..-1 ]
        i = line.rindex( /\s/, width )
        if i == nil
          i = line.rindex( /\s/ )
        end
      end
      if line != nil
        if retval.length > 0 && retval.last.length + line.length + 1 <= width
          retval.last << " " + line
        else
          retval << line
        end
      end
      return retval
    end

    private

    def log_info message, attention_type
      if @data_last_written_to && @message_out == @data_out
        @data_out.puts
      end
      puts_color( @message_out, message, attention_type)
      @message_last_written_to = true
      @data_last_written_to = false
    end

    def log_data item_name, item_value, attention_type
      log_just item_name, item_value, @item_name_length, @item_name_rjust, ":  ", attention_type
    end

    def log_prose item_name, item_value, attention_type
      log_just item_name, item_value, @prose_name_length, @prose_name_rjust, " ", attention_type
    end

    def log_just item_name, item_value, name_length, name_rjust, separator, attention_type
      if (item_value != nil && !item_value.to_s.empty?)
        format_string = "%" + name_length.to_s + "s%s%s"
        if (!name_rjust)
          format_string = "%-" + name_length.to_s + "s%s%s"
        end
        if @auto_wrap
          lines = break_up_line item_value.to_s, get_width - ( name_length + separator.length )
          i = 0
          lines.each do |line|
            if i == 0
              puts_color( @data_out, format(format_string, item_name, separator, line), attention_type )
            else
              puts_color( @data_out, format(format_string, " ", separator, line), attention_type )
            end
            i = i + 1
          end
        else
          puts_color( @data_out, format(format_string, item_name, separator, item_value), attention_type )
        end
        @data_last_written_to = true
        @message_last_written_to = false
      end
    end

    def log_raw item_value, wrap, attention_type
      if @auto_wrap and wrap
        lines = break_up_line item_value, get_width
        lines.each do |line|
          puts_color( @data_out, line, attention_type )
        end
      else
        puts_color( @data_out, item_value, attention_type )
      end
      @data_last_written_to = true
      @message_last_written_to = false
    end

    def puts_color out, string, attention_type
      if !attention_type || @color_scheme == ColorScheme::NONE || attention_type == AttentionType::PRIMARY
        out.puts string
      else
        case attention_type
          when AttentionType::SUCCESS
            case @color_scheme
              when ColorScheme::DARK
                out.puts @rainbow.wrap(string).aqua
              when ColorScheme::LIGHT
                out.puts @rainbow.wrap(string).blue
              else
                out.puts string
            end
          when AttentionType::SECONDARY
            case @color_scheme
              when ColorScheme::DARK
                out.puts @rainbow.wrap(string).green
              when ColorScheme::LIGHT
                out.puts @rainbow.wrap(string).green
              else
                out.puts string
            end
          when AttentionType::INFO
            case @color_scheme
              when ColorScheme::DARK
                out.puts @rainbow.wrap(string).yellow.bright
              when ColorScheme::LIGHT
                out.puts @rainbow.wrap(string).blue.bright
              else
                out.puts string
            end
          when AttentionType::ERROR
            case @color_scheme
              when ColorScheme::DARK
                out.puts @rainbow.wrap(string).red.bright
              when ColorScheme::LIGHT
                out.puts @rainbow.wrap(string).red
              else
                out.puts string
            end
          else
            out.puts string
        end
      end
    end

  end

end
