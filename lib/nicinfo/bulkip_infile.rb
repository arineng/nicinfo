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

module NicInfo

  class BulkIPInFile
    IpColumn = "ip column"
    StripIp = "strip ip"
    DateTimeType = "datetime type"
    DateTimeColumn = "datetime column"
    StripDateTime = "strip datetime"

    DateTimeNoneType = "no datetime"
    DateTimeRubyType = "datetime ruby type"
    DateTimeApacheType = "datetime apache type"
    DateTimeApacheNoTZType = "datetime apache no timezone type"

    IpStripRegex = /^([^\h.:]*)([\h.:]*)([^\h.:]*)$/
    DateTimeStripRegex = /^([^\w\-\/:\s]*)([\w\-\/:\s]*)([^\w\-\/:\s]*)$/
    ApacheTimeFormat = '%d/%b/%Y:%H:%M:%S %z'
    ApacheNoTZTimeFormat = '%d/%b/%Y:%H:%M:%S'

    OopsTime = Time.now.to_date.to_time

    attr_accessor :file_name, :strategy

    def initialize file_name
      @file_name = file_name
    end

    def has_strategy
      retval = true
      i = 0
      File.foreach( @file_name ) do |line|
        strategy = guess_line( line )
        if strategy == nil
          retval = false
          break
        end
        if i == 0
          @strategy = strategy
        elsif i > 3
          break
        elsif strategy != @strategy
          retval = false
          break
        end
        i = i + 1
      end
      return retval
    end

    def guess_line line
      strategy = guess_ip( line )
      strategy.merge!( guess_time( line ) )
      return strategy
    end

    def guess_ip line
      column = -1
      strip_column = false
      fields = line.split(/\s/)
      fields.each_with_index do |field, i|
        if is_ipaddr( field )
          column = i
          break
        else
          m = IpStripRegex.match(field)
          if m != nil && m[2] != nil && is_ipaddr( m[2] )
            column = i
            strip_column = true
            break
          end
        end
      end
      strategy = { IpColumn => column, StripIp => strip_column }
      return strategy
    end

    def is_ipaddr s
      retval = false
      begin
        IPAddr.new( s )
        retval = true
      rescue IPAddr::InvalidAddressError => e
        retval = false
      end
      return retval
    end

    def guess_time line
      column = -1
      strip = false
      type = DateTimeNoneType
      fields = line.split(/\s/)
      for i in 0..fields.length do
        if i+1 < fields.length && is_time( fields[i] + " " + fields[i+1] )
          column = i
          strip = false
          type = DateTimeRubyType
          break
        elsif i+1 < fields.length && is_time( datetimestrip( fields[i] + " " + fields[i+1] ) )
          column = i
          strip = true
          type = DateTimeRubyType
          break
        elsif i+1 < fields.length && is_apache_time( fields[i] + " " + fields[i+1] )
          column = i
          strip = false
          type = DateTimeApacheType
          break
        elsif i+1 < fields.length && is_apache_time( datetimestrip( fields[i] + " " + fields[i+1] ) )
          column = i
          strip = true
          type = DateTimeApacheType
          break
        elsif is_apachenotz_time( fields[i] )
          column = i
          strip = false
          type = DateTimeApacheNoTZType
          break
        elsif is_apachenotz_time( datetimestrip( fields[i] ) )
          column = i
          strip = true
          type = DateTimeApacheNoTZType
          break
        end
      end
      strategy = { DateTimeType => type, DateTimeColumn => column, StripDateTime => strip }
      return strategy
    end

    def datetimestrip s
      retval = nil
      m = DateTimeStripRegex.match( s )
      if m != nil && m[2] != nil
        retval = m[2]
      end
      return retval
    end

    def is_time s
      retval = false
      begin
        t = Time.parse( s )
        retval = true if t != OopsTime
      rescue ArgumentError
        retval = false
      end if s != nil
      return retval
    end

    def is_apache_time s
      retval = false
      begin
        Time.strptime( s, ApacheTimeFormat )
        retval = true
      rescue ArgumentError
        retval = false
      end if s != nil
      return retval
    end

    def is_apachenotz_time s
      retval = false
      begin
        Time.strptime( s, ApacheNoTZTimeFormat )
        retval = true
      rescue ArgumentError
        retval = false
      end if s != nil
      return retval
    end

    def get_ip fields
      ip = fields[@strategy[IpColumn]]
      if @strategy[StripIp]
        ip = IpStripRegex.match( ip )[2]
      end
      return ip
    end

    def get_time fields
      retval = nil
      if @strategy[DateTimeType] != DateTimeNoneType
        column = @strategy[DateTimeColumn]
        if column+1 < fields.length &&
           ( @strategy[DateTimeType] == DateTimeRubyType || @strategy[DateTimeType] == DateTimeApacheType )
          time_field = fields[column] + " " + fields[column+1]
        else
          time_field = fields[column]
        end
        if @strategy[StripDateTime]
          time_field = DateTimeStripRegex.match( time_field )[2]
        end
        case @strategy[DateTimeType]
          when DateTimeRubyType
            retval = Time.parse( time_field )
          when DateTimeApacheType
            retval = Time.strptime( time_field, ApacheTimeFormat )
          when DateTimeApacheNoTZType
            retval = Time.strptime( time_field, ApacheNoTZTimeFormat )
        end
      end
      return retval
    end

    def foreach
      if @strategy == nil
        raise RuntimeError unless has_strategy
      end
      File.foreach( @file_name ) do |line|
        fields = line.split( /\s/ )
        ip = get_ip( fields )
        time = get_time( fields )
        yield( ip, time )
      end
    end

  end

end
