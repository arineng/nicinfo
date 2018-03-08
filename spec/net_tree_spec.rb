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

require 'spec_helper'
require 'rspec'
require 'pp'
require_relative '../lib/nicinfo/net_tree'

describe 'bulk_infile test' do

  it 'should do boundary tests' do

    node = NicInfo::NetNode.new( IPAddr.new( "10.0.1.0/24" ) )

    expect( node.include?( NicInfo::NetNode.new( IPAddr.new( "10.0.1.1" ) ) ) ).to be_truthy
    expect( node.include?( NicInfo::NetNode.new( IPAddr.new( "9.0.0.1" ) ) ) ).to be_falsey
    expect( node.include?( NicInfo::NetNode.new( IPAddr.new( "10.0.0.1" ) ) ) ).to be_falsey

    expect( node.contained_by?( NicInfo::NetNode.new( IPAddr.new( "10.0.1.0/16" ) ) ) ).to be_truthy
    expect( node.contained_by?( NicInfo::NetNode.new( IPAddr.new( "10.0.0.0/16" ) ) ) ).to be_truthy
    expect( node.contained_by?( NicInfo::NetNode.new( IPAddr.new( "10.1.0.0/16" ) ) ) ).to be_falsey

    expect( node.left_of?( NicInfo::NetNode.new( IPAddr.new( "10.0.3.0/24" ) ) ) ).to be_truthy
    expect( node.left_of?( NicInfo::NetNode.new( IPAddr.new( "10.0.2.0/24" ) ) ) ).to be_truthy
    expect( node.right_of?( NicInfo::NetNode.new( IPAddr.new( "10.0.0.0/24" ) ) ) ).to be_truthy

    overlap = NicInfo::NetNode.new
    overlap.begin = IPAddr.new( "10.0.0.255" ).to_i
    overlap.end = IPAddr.new( "10.0.1.255" ).to_i
    expect( node.overlaps?( overlap ) ).to be_truthy
    overlap.begin = IPAddr.new( "10.0.1.0" ).to_i
    overlap.end = IPAddr.new( "10.0.2.1" ).to_i
    expect( node.overlaps?( overlap ) ).to be_truthy
    overlap.begin = IPAddr.new( "10.0.1.0" ).to_i
    overlap.end = IPAddr.new( "10.0.1.255" ).to_i
    expect( node.overlaps?( overlap ) ).to be_truthy
    overlap.begin = IPAddr.new( "10.0.1.1" ).to_i
    overlap.end = IPAddr.new( "10.0.1.254" ).to_i
    expect( node.overlaps?( overlap ) ).to be_falsey

  end

  it 'should insert' do

    t = NicInfo::NetTree.new
    #puts "1"
    t.insert( IPAddr.new( "10.0.0.0/24" ), 1 )
    #puts "2"
    t.insert( IPAddr.new( "10.0.0.0/16" ), 2 )
    #puts "3"
    t.insert( IPAddr.new( "10.0.0.0/25" ), 3 )
    #puts "4"
    t.insert( IPAddr.new( "9.0.0.0/24" ), 4 )
    #puts "5"
    t.insert( IPAddr.new( "11.0.0.0/24" ), 5 )
    expect( t.find_by_ipaddr( IPAddr.new( "10.0.0.1" ) ) ).to eq( 3 )
    expect( t.find_by_ipaddr( IPAddr.new( "10.0.1.1" ) ) ).to eq( 2 )
    expect( t.find_by_ipaddr( IPAddr.new( "9.0.1.1" ) ) ).to be_nil
    expect( t.find_by_ipaddr( IPAddr.new( "9.0.0.1" ) ) ).to eq( 4 )
    #t.v4_root.print

  end

end
