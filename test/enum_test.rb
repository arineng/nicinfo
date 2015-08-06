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


require 'minitest/autorun'
require 'enum'

class EnumTest < Minitest::Test

  class Color < NicInfo::Enum

    Color.add_item :BLUE, 1
    Color.add_item :RED, 2
    Color.add_item :YELLOW, 3

  end

  class Level < NicInfo::Enum

    Level.add_item :HIGH, "HIGH"
    Level.add_item :LOW, "LOW"
    Level.add_item :INBETWEEN, "INBETWEEN"

  end

  def test_color_red

    my_color = Color::RED
    assert_equal( 2, my_color )

  end

  def test_color_green

    my_color = Color::GREEN
    assert_nil( my_color )

  end

  def test_color_each

    a = []
    Color.each { |key,value|
      a << value
    }
    assert_equal( true, a.include?( 1 ) )
    assert_equal( true, a.include?( 2 ) )
    assert_equal( true, a.include?( 3 ) )

  end

  def test_has_color_red
    assert( Color.has_value?( 2 ) )
  end

  def test_has_color_green
    assert( !Color.has_value?( 5 ) )
  end

  def test_level_high

    my_level = Level::HIGH
    assert_equal( "HIGH", my_level )

  end

  def test_level_bottom

    my_level = Level::BOTTOM
    assert_nil( my_level )

  end

  def test_level_each

    a = []
    Level.each { |key,value|
      a << value
    }
    assert_equal( true, a.include?( "HIGH" ) )
    assert_equal( true, a.include?( "LOW" ) )
    assert_equal( true, a.include?( "INBETWEEN" ) )

  end

  def test_has_level_high
    assert( Level.has_value?( "HIGH" ) )
  end

  def test_has_level_bottom
    assert( ! Level.has_value?( "BOTTOM" ) )
  end

end
