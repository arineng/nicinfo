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


# Code based on "Enumerations and Ruby"
#    http://www.rubyfleebie.com/enumerations-and-ruby/

module NicInfo

  # A base class for enumerations
  class Enum

    def Enum.add_item( key, value )
      @hash ||= {}
      @hash[ key ] = value
    end

    def Enum.const_missing( key )
      @hash[ key ]
    end

    def Enum.each
      @hash.each { |key,value| yield( key, value ) }
    end

    def Enum.has_value? value
      @hash.value?( value )
    end

    def Enum.values
      @hash.values
    end

  end

end
