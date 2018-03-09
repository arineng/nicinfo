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
require_relative '../lib/nicinfo/binary_search_tree'

describe 'net_tree test' do

  it 'should btree basics' do

    t = NicInfo::BinarySearchTree.new
    root = t.insert( nil,  5, "a" )
    t.insert( root, 3, "b" )
    t.insert( root, 1, "c" )
    t.insert( root, 4, "d" )
    t.insert( root, 9, "e" )
    t.insert( root, 6, "f" )
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

end
