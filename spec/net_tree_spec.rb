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

describe 'net_tree test' do

  it 'append to array' do
    t = NicInfo::NetTree.new
    n1 = NicInfo::NetTree::NetNode.new( 24, IPAddr.new( "10.0.0.0/24" ), 1 )
    n2 = NicInfo::NetTree::NetNode.new( 16, IPAddr.new( "10.0.0.0/16" ), 2 )
    n3 = NicInfo::NetTree::NetNode.new( 8, IPAddr.new( "10.0.0.0/8" ), 3 )
    n4 = NicInfo::NetTree::NetNode.new( 25, IPAddr.new( "10.0.0.0/8" ), 4 )
    a = t.append_to( n3, n1 )
    expect( a[0].cidr_length ).to eq( 24 )
    expect( a[1].cidr_length ).to eq( 8 )
    a = t.append_to( a, n2 )
    expect( a[0].cidr_length ).to eq( 24 )
    expect( a[1].cidr_length ).to eq( 16 )
    expect( a[2].cidr_length ).to eq( 8 )
    a = t.append_to( a, n4 )
    expect( a[0].cidr_length ).to eq( 25 )
    expect( a[1].cidr_length ).to eq( 24 )
    expect( a[2].cidr_length ).to eq( 16 )
    expect( a[3].cidr_length ).to eq( 8 )
  end

  it 'should insert' do

    t = NicInfo::NetTree.new
    t.insert( "10.0.0.0/24", 1 )
    t.insert( "10.0.0.0/16", 2 )
    t.insert( "10.0.0.0/25", 3 )
    t.insert( "9.0.0.0/24", 4 )
    t.insert( "11.0.0.0/24", 5 )
    expect( t.find_by_ipaddr( "10.0.0.1" ) ).to eq( 3 )
    expect( t.find_by_ipaddr( "10.0.1.1" ) ).to eq( 2 )
    expect( t.find_by_ipaddr( "9.0.1.1" ) ).to be_nil
    expect( t.find_by_ipaddr( "9.0.0.1" ) ).to eq( 4 )
    expect( t.find_by_ipaddr( "11.0.0.1" ) ).to eq( 5 )
    expect( t.find_by_ipaddr( "11.0.1.1" ) ).to be_nil
    t.insert( "11.0.0.0/16", 6 )
    expect( t.find_by_ipaddr( "11.0.1.1" ) ).to eq( 6 )
    expect( t.find_by_ipaddr( "11.0.0.1" ) ).to eq( 5 )
    t.insert( "13.0.0.0/8", 7 )
    expect( t.find_by_ipaddr( "10.0.0.1" ) ).to eq( 3 )
    expect( t.find_by_ipaddr( "10.0.1.1" ) ).to eq( 2 )
    expect( t.find_by_ipaddr( "9.0.1.1" ) ).to be_nil
    expect( t.find_by_ipaddr( "9.0.0.1" ) ).to eq( 4 )
    expect( t.find_by_ipaddr( "11.0.1.1" ) ).to eq( 6 )
    expect( t.find_by_ipaddr( "11.0.0.1" ) ).to eq( 5 )
    expect( t.find_by_ipaddr( "13.0.0.1" ) ).to eq( 7 )
    expect( t.find_by_ipaddr( "12.0.0.0" ) ).to be_nil
    t.insert( "11.1.0.0/16", 8 )
    expect( t.find_by_ipaddr( "11.1.0.1" ) ).to eq( 8 )
    expect( t.find_by_ipaddr( "11.2.0.1" ) ).to be_nil
    expect( t.find_by_ipaddr( "10.0.0.1" ) ).to eq( 3 )
    expect( t.find_by_ipaddr( "10.0.1.1" ) ).to eq( 2 )
    expect( t.find_by_ipaddr( "9.0.1.1" ) ).to be_nil
    expect( t.find_by_ipaddr( "9.0.0.1" ) ).to eq( 4 )
    expect( t.find_by_ipaddr( "11.0.1.1" ) ).to eq( 6 )
    expect( t.find_by_ipaddr( "11.0.0.1" ) ).to eq( 5 )
    expect( t.find_by_ipaddr( "13.0.0.1" ) ).to eq( 7 )

  end

end
