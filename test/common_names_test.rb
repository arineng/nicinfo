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


require 'test/unit'
require 'common_names'

class CommonNamesTest < Test::Unit::TestCase

  def test_last_names

    assert_equal( true, ARINcli::is_last_name( "JOHNSON") )
    assert_equal( true, ARINcli::is_last_name( "NEWTON") )
    assert_equal( true, ARINcli::is_last_name( "KOSTERS") )
    assert_equal( true, ARINcli::is_last_name( "AALDERINK") )
    assert_equal( false, ARINcli::is_last_name( "..........") )

  end

  def test_male_names

    assert_equal( true, ARINcli::is_male_name( "JOHN" ) )
    assert_equal( true, ARINcli::is_male_name( "JAMES" ) )
    assert_equal( true, ARINcli::is_male_name( "ANDREW" ) )
    assert_equal( true, ARINcli::is_male_name( "MARK" ) )
    assert_equal( false, ARINcli::is_male_name( ".........." ) )

  end

  def test_female_names

    assert_equal( true, ARINcli::is_female_name( "LINDA" ) )
    assert_equal( true, ARINcli::is_female_name( "MARY" ) )
    assert_equal( true, ARINcli::is_female_name( "GAIL" ) )
    assert_equal( true, ARINcli::is_female_name( "ALLYN" ) )
    assert_equal( false, ARINcli::is_female_name( "........" ) )

  end

end
