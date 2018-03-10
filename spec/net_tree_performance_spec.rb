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
require 'benchmark'
require_relative '../lib/nicinfo/net_tree'
require_relative '../lib/nicinfo/binary_search_tree'

describe 'bulk_infile test', :performance => true do

  @networks_20k = nil
  @networks_50k = nil
  @networks_100k = nil

  @ips_100 = nil
  @ips_200 = nil
  @ips_400 = nil

  before( :all ) do

    @networks_20k = []
    (1..20000).each do |x|
      @networks_20k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
    end
    @networks_20k.uniq!

    @networks_50k = []
    (1..50000).each do |x|
      if x < 20000 && x % 2 == 0
        @networks_50k << @networks_20k[ x / 2 ]
      else
        @networks_50k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
      end
    end
    @networks_50k.uniq!

    @networks_100k = []
    (1..100000).each do |x|
      if x < 20000 && x % 3 == 0
        @networks_100k << @networks_20k[ x / 3 ]
      else
        @networks_100k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
      end
    end
    @networks_100k.uniq!

    @ips_100 = []
    (1..100).each do |x|
      if x % 2 == 0
        @ips_100 << @networks_20k[ rand( 10000 ) ].split( "/" )[ 0 ]
      else
        @ips_100 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
      end
    end

    @ips_200 = []
    (1..200).each do |x|
      if x % 2 == 0
        @ips_200 << @networks_20k[ rand( 10000 ) ].split( "/" )[ 0 ]
      else
        @ips_200 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
      end
    end

    @ips_400 = []
    (1..400).each do |x|
      if x % 2 == 0
        @ips_400 << @networks_20k[ rand( 10000 ) ].split( "/" )[ 0 ]
      else
        @ips_400 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
      end
    end

  end

  def insert_into_btree( t, root, ip )
    ipaddr = IPAddr.new( ip )
    n = t.insert( root,  ipaddr.to_range.begin.to_i, ipaddr )
    return n unless root
    return root
  end

  it 'should insert into btree' do

    puts "","","btree insertion benchmarks",""

    Benchmark.bmbm do |x|
      x.report("insert 20k") do
        t = NicInfo::BinarySearchTree.new
        root = nil
        @networks_20k.each do |y|
          root = insert_into_btree(t,root,y)
        end
      end
      x.report("insert 50k") do
        t = NicInfo::BinarySearchTree.new
        root = nil
        @networks_50k.each do |y|
          root = insert_into_btree(t,root,y)
        end
      end
      x.report("insert 100k") do
        t = NicInfo::BinarySearchTree.new
        root = nil
        @networks_100k.each do |y|
          root = insert_into_btree(t,root,y)
        end
      end
    end

  end

  it 'should insert into hash' do

    puts "","","hash insertion benchmarks",""

    Benchmark.bmbm do |x|
      x.report("insert 20k") do
        blocks = {}
        @networks_20k.each do |y|
          blocks[ IPAddr.new( y ) ] = true
        end
      end
      x.report("insert 50k") do
        blocks = {}
        @networks_50k.each do |y|
          blocks[ IPAddr.new( y ) ] = true
        end
      end
      x.report("insert 100k") do
        blocks = {}
        @networks_100k.each do |y|
          blocks[ IPAddr.new( y ) ] = true
        end
      end
    end

  end

  it 'should do IPAddr include?' do

    puts "","","ipaddr include? benchmarks",""

    ipaddr = IPAddr.new( "192.168.0.0/16" )

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 20k") do
        @ips_100.each do |ip|
          ipaddr.include?( IPAddr.new( ip ) )
        end
      end
      x.report("lookup 200 of 20k") do
        @ips_200.each do |ip|
          ipaddr.include?( IPAddr.new( ip ) )
        end
      end
      x.report("lookup 400 of 20k") do
        @ips_400.each do |ip|
          ipaddr.include?( IPAddr.new( ip ) )
        end
      end
    end

  end

  def floor_include?(t,root,ip)
    ipaddr = IPAddr.new( ip )
    n = t.floor( root, ipaddr.to_i )
    return n.data.include?( ipaddr ) if n
    return false
  end

  it 'should floor into 20k btree' do

    puts "","","floor into 20k benchmarks",""

    t = NicInfo::BinarySearchTree.new
    root = nil
    @networks_20k.each do |y|
      root = insert_into_btree(t,root,y)
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 20k") do
        @ips_100.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 200 of 20k") do
        @ips_200.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 400 of 20k") do
        @ips_400.each do |ip|
          floor_include?(t,root,ip)
        end
      end
    end

  end

  it 'should floor into 50k btree' do

    puts "","","floor into 50k benchmarks",""

    t = NicInfo::BinarySearchTree.new
    root = nil
    @networks_50k.each do |y|
      root = insert_into_btree(t,root,y)
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 50k") do
        @ips_100.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 200 of 50k") do
        @ips_200.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 400 of 50k") do
        @ips_400.each do |ip|
          floor_include?(t,root,ip)
        end
      end
    end

  end

  it 'should floor into 100k btree' do

    puts "","","floor into 100k benchmarks",""

    t = NicInfo::BinarySearchTree.new
    root = nil
    @networks_100k.each do |y|
      root = insert_into_btree(t,root,y)
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 100k") do
        @ips_100.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 200 of 100k") do
        @ips_200.each do |ip|
          floor_include?(t,root,ip)
        end
      end
      x.report("lookup 400 of 100k") do
        @ips_400.each do |ip|
          floor_include?(t,root,ip)
        end
      end
    end

  end

  def hash_lookup( blocks, ip )
    ipaddr = IPAddr.new( ip )
    n = blocks[ ipaddr.to_string ]
    n.include?( ipaddr ) if n
  end

  it 'should do 20k hash lookups' do

    puts "","","hash lookup into 20k benchmarks",""

    blocks = {}
    @networks_20k.each do |y|
      net = IPAddr.new( y )
      blocks[ net.to_string ] = net
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 20k") do
        @ips_100.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 200 of 20k") do
        @ips_200.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 400 of 20k") do
        @ips_400.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
    end

  end

  it 'should do 50k hash lookups' do

    puts "","","hash lookup into 50k benchmarks",""

    blocks = {}
    @networks_50k.each do |y|
      net = IPAddr.new( y )
      blocks[ net.to_string ] = net
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 50k") do
        @ips_100.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 200 of 50k") do
        @ips_200.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 400 of 50k") do
        @ips_400.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
    end

  end

  it 'should do 100k hash lookups' do

    puts "","","hash lookup into 100k benchmarks",""

    blocks = {}
    @networks_100k.each do |y|
      net = IPAddr.new( y )
      blocks[ net.to_string ] = net
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 100k") do
        @ips_100.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 200 of 100k") do
        @ips_200.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
      x.report("lookup 400 of 100k") do
        @ips_400.each do |ip|
          hash_lookup( blocks, ip )
        end
      end
    end

  end

  it 'should iterate over 20k hash to find net' do

    puts "","","iterate over 20k hash benchmarks",""

    blocks = {}
    @networks_20k.each do |x|
      blocks[ IPAddr.new( x ) ] = true
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 20k") do
        @ips_100.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 200 of 20k") do
        @ips_200.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 400 of 20k") do
        @ips_400.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
    end

  end

  it 'should iterate over 50k hash to find net' do

    puts "","","iterate over 50k hash benchmarks",""

    blocks = {}
    @networks_50k.each do |x|
      blocks[ IPAddr.new( x ) ] = true
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 50k") do
        @ips_100.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 200 of 50k") do
        @ips_200.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 400 of 50k") do
        @ips_400.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
    end

  end

  it 'should iterate over 100k hash to find net' do

    puts "","","iterate over 100k hash benchmarks",""

    blocks = {}
    @networks_100k.each do |x|
      blocks[ IPAddr.new( x ) ] = true
    end

    Benchmark.bmbm do |x|
      x.report("lookup 100 of 100k") do
        @ips_100.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 200 of 100k") do
        @ips_200.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
      x.report("lookup 400 of 100k") do
        @ips_400.each do |ip|
          blocks.each do |ipaddr,v|
            break if ipaddr.include?( IPAddr.new( ip ) )
          end
        end
      end
    end

  end

end
