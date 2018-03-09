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

  it 'should btree basics' do

    t = NicInfo::NetBTree.new
    root = t.insert( nil, NicInfo::NetBTree::BNode.new( nil, nil, 5, "a", nil, nil ) )
    t.insert( root, NicInfo::NetBTree::BNode.new( nil, nil, 3, "b", nil, nil ) )
    t.insert( root, NicInfo::NetBTree::BNode.new( nil, nil, 1, "c", nil, nil ) )
    t.insert( root, NicInfo::NetBTree::BNode.new( nil, nil, 4, "d", nil, nil ) )
    t.insert( root, NicInfo::NetBTree::BNode.new( nil, nil, 9, "e", nil, nil ) )
    t.insert( root, NicInfo::NetBTree::BNode.new( nil, nil, 6, "f", nil, nil ) )
    expect( t.lookup( root, 1 ).data ).to eq( "c" )
    expect( t.lookup( root, 3 ).data ).to eq( "b" )
    expect( t.lookup( root, 4 ).data ).to eq( "d" )
    expect( t.lookup( root, 5 ).data ).to eq( "a" )
    expect( t.lookup( root, 6 ).data ).to eq( "f" )
    expect( t.lookup( root, 9 ).data ).to eq( "e" )
    expect( t.floor( root, 1 ).data ).to eq( "c" )
    expect( t.floor( root, 2 ).data ).to eq( "c" )
    expect( t.floor( root, 3 ).data ).to eq( "b" )
    expect( t.floor( root, 4 ).data ).to eq( "d" )
    expect( t.floor( root, 5 ).data ).to eq( "a" )
    expect( t.floor( root, 6 ).data ).to eq( "f" )
    expect( t.floor( root, 7 ).data ).to eq( "f" )
    expect( t.floor( root, 8 ).data ).to eq( "f" )
    expect( t.floor( root, 9 ).data ).to eq( "e" )
    expect( t.floor( root, 10 ).data ).to eq( "e" )

  end

  it 'should do net btree stuff' do

    t = NicInfo::NetBTree.new
    root = t.new_bnode( "0.0.0.0/0", "a" )
    t.put( root, "10.0.0.0/16", "b")
    t.put( root, "9.0.0.0/16", "c")
    t.put( root, "8.0.0.0/16", "d")
    t.put( root, "11.0.0.0/16", "e")
    expect( t.get( root, "10.0.0.0" ).data ).to eq( "b" )
    expect( t.get( root, "9.0.0.0" ).data ).to eq( "c" )
    expect( t.get( root, "8.0.0.0" ).data ).to eq( "d" )
    expect( t.get( root, "11.0.0.0" ).data ).to eq( "e" )
    expect( t.get_floor( root, "11.0.0.0" ).data ).to eq( "e" )
    expect( t.get_floor( root, "11.0.0.1" ).data ).to eq( "e" )
    expect( t.get_floor( root, "8.0.0.0" ).data ).to eq( "d" )
    expect( t.get_floor( root, "8.0.0.1" ).data ).to eq( "d" )
    expect( t.get_floor( root, "9.0.0.0" ).data ).to eq( "c" )
    expect( t.get_floor( root, "9.0.0.1" ).data ).to eq( "c" )
    expect( t.get_floor( root, "10.0.0.0" ).data ).to eq( "b" )
    expect( t.get_floor( root, "10.0.0.1" ).data ).to eq( "b" )
    expect( t.get_floor( root, "10.0.0.2" ).data ).to eq( "b" )
    expect( t.get_floor( root, "10.0.0.255" ).data ).to eq( "b" )
    expect( t.get_floor( root, "10.255.255.255" ).data ).to eq( "b" )

  end

  xit 'should insert' do

    t = NicInfo::NetBTree.new
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
