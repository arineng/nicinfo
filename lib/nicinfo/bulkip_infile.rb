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

    attr_accessor :file_name, :column, :strip_column

    def initialize file_name
      @file_name = file_name
      @regex = /^([^\h.:]*)([\h.:]*)([^\h.:]*)$/
    end

    def has_strategy
      retval = true
      i = 0
      File.foreach( @file_name ) do |line|
        column, strip_column = guess_line( line )
        if i == 0
          @column = column
          @strip_column = strip_column
        elsif i > 3
          break
        elsif column != @column || strip_column != @strip_column
          retval = false
          break
        end
      end
      return retval
    end

    def guess_line line
      column = -1
      strip_column = false
      fields = line.split(/\s/)
      fields.each_with_index do |field, i|
        if is_ipaddr( field )
          column = i
          break
        else
          m = @regex.match(field)
          if m != nil && m[2] != nil && is_ipaddr( m[2] )
            column = i
            strip_column = true
            break
          end
        end
      end
      return column, strip_column
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

  end

end
