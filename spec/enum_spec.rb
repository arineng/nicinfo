# Copyright (C) 2011-2017 American Registry for Internet Numbers
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


require 'spec_helper'
require 'rspec'
require_relative '../lib/nicinfo/enum'

describe 'enum tests' do

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

  it 'should test for red' do

    my_color = Color::RED
    expect( my_color ).to eq( 2 )

  end

  it 'should test for green' do

    my_color = Color::GREEN
    expect( my_color ).to be_nil

  end

  it 'should test iterating an enum' do

    a = []
    Color.each { |key,value|
      a << value
    }
    expect( a.include?( 1 ) ).to be_truthy
    expect( a.include?( 2 ) ).to be_truthy
    expect( a.include?( 3 ) ).to be_truthy

  end

  it 'should have the color red' do
    expect( Color.has_value?( 2 ) ).to be_truthy
  end

  it 'should not have the color green' do
    expect( Color.has_value?( 5 ) ).to be_falsey
  end

  it 'should be level high' do

    my_level = Level::HIGH
    expect( my_level ).to eq( "HIGH" )

  end

  it 'should not be bottom level' do

    my_level = Level::BOTTOM
    expect( my_level ).to be_nil

  end

  it 'should test each level' do

    a = []
    Level.each { |key,value|
      a << value
    }
    expect( a.include?( "HIGH" ) ).to be_truthy
    expect( a.include?( "LOW" ) ).to be_truthy
    expect( a.include?( "INBETWEEN" ) ).to be_truthy

  end

  it 'should have level high' do
    expect( Level.has_value?( "HIGH" ) ).to be_truthy
  end

  it 'should not have level bottom' do
    expect( Level.has_value?( "BOTTOM" ) ).to be_falsey
  end

end
