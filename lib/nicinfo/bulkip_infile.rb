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

    InLine = Struct.new( :ip, :time, :lineno )

    attr_accessor :file_name, :strategy, :lineno, :eol

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
        begin
          case @strategy[DateTimeType]
            when DateTimeRubyType
              retval = Time.parse( time_field )
            when DateTimeApacheType
              retval = Time.strptime( time_field, ApacheTimeFormat )
            when DateTimeApacheNoTZType
              retval = Time.strptime( time_field, ApacheNoTZTimeFormat )
          end
        rescue => e
          retval = nil
        end
      end
      return retval
    end

    def foreach
      if @strategy == nil
        raise RuntimeError unless has_strategy
      end
      i = 0
      File.foreach( @file_name ) do |line|
        fields = line.split( /\s/ )
        ip = get_ip( fields )
        time = get_time( fields )
        yield( ip, time, i )
        i = i + 1
      end
    end

    def next_line
      if @file == nil
        @file = File.open( file_name, "r" )
        @lineno = 0
      end
      retval = nil
      if !@eol
        line = @file.gets
        if line
          fields = line.split ( /\s/ )
          ip = get_ip( fields )
          time = get_time( fields )
          @lineno = @lineno + 1
          retval = InLine.new( ip, time, @lineno )
        else
          @eol = true
        end
      end
      return retval
    end

    def done
      if @file
        @file.close
        @file = nil
      end
    end

  end

  class BulkIPInFileSet

    attr_accessor :appctx, :timing_provided, :file_list


    def initialize( appctx )
      @appctx = appctx
    end

    def set_file_list( file_list )

      # if we have been given a directory, turn it into a glob pattern
      if File.directory?( file_list )
        file_list = file_list + File::SEPARATOR unless file_list.end_with?( File::SEPARATOR )
        file_list = file_list + "*"
      end
      @file_list = file_list

      # make sure all files have a strategy
      # and make sure that all files either have timing information or don't, no mixtures
      files_with_time = 0
      files_without_time = 0
      Dir.glob( file_list ).each do |file|
        b = BulkIPInFile.new( file )
        if !b.has_strategy
          raise ArgumentError.new( "cannot determine parsing strategy for #{file}")
        end
        if b.strategy[ NicInfo::BulkIPInFile::DateTimeType ] == NicInfo::BulkIPInFile::DateTimeNoneType
          files_without_time = files_without_time + 1
        else
          files_with_time = files_with_time + 1
        end
        @appctx.logger.trace( "file #{file} strategry is #{b.strategy}")
      end
      if files_with_time != 0 && files_without_time != 0
        raise ArgumentError.new( "Some files have times and some do not. All files must either have time values or no time values.")
      end
      @timing_provided = false
      @timing_provided = true if files_with_time != 0

    end

    def foreach_by_time
      # setup all the files and get first line
      @inlines = {}
      Dir.glob( @file_list ).each do |file|
        b = BulkIPInFile.new( file )
        if b.strategy == nil
          raise RuntimeError unless b.has_strategy
        end
        inline = b.next_line
        @inlines[ b ] = inline
      end

      #iterate through until all done
      num_eol = 0
      while num_eol < @inlines.length do
        lowest_line = nil
        lowest_file = nil
        num_eol = 0
        @inlines.each do |b,l|
          if b.eol || l == nil
            num_eol = num_eol + 1
          else
            if l[:time] == nil
              lowest_line = l
              lowest_file = b
            elsif lowest_line == nil || lowest_line[:time] == nil
              lowest_line = l
              lowest_file = b
            elsif l[:time] < lowest_line[:time]
              lowest_line = l
              lowest_file = b
            end
          end
        end
        if lowest_line
          yield( lowest_line[ :ip ], lowest_line[ :time ], lowest_line[ :lineno ], lowest_file.file_name )
          @inlines[ lowest_file ] = lowest_file.next_line
        end
      end

      @inlines.keys.each do |b|
        b.done
      end

    end

    def done
      @inlines.keys.each do |b|
        b.done
      end if @inlines
    end

  end

end
