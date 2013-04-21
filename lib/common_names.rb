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


module ARINcli

  def ARINcli::is_last_name name
    is_name "last-names.txt", name
  end

  def ARINcli::is_male_name name
    is_name "male-first-names.txt", name
  end

  def ARINcli::is_female_name name
    is_name "female-first-names.txt", name
  end

  def ARINcli::is_name file_name, name
    retval = false

    file = File.new( File.join( File.dirname( __FILE__ ) , file_name ), "r" )
    file.lines.each do |line|
      if line.start_with?( name )
        retval = true
        break
      end
    end
    file.close

    return retval
  end

end
