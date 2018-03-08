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

describe 'bulk_infile test', :performance => true do

  @networks_20k = nil
  @networks_50k = nil
  @networks_100k = nil

  @ips_1M = nil
  @ips_2M = nil
  @ips_4M = nil

  before( :all ) do

    @networks_20k = []
    (1..20000).each do |x|
      @networks_20k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
    end
    @networks_20k.uniq!

    @networks_50k = []
    (1..50000).each do |x|
      @networks_50k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
    end
    @networks_50k.uniq!

    @networks_100k = []
    (1..100000).each do |x|
      @networks_100k << "#{rand(255)}.#{rand(255)}.#{rand(255)}.0/24"
    end
    @networks_100k.uniq!

    @ips_100 = []
    (1..100).each do |x|
      @ips_100 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

    @ips_200 = []
    (1..200).each do |x|
      @ips_200 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

    @ips_400 = []
    (1..400).each do |x|
      @ips_400 << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

  end

  it 'should insert into hash' do

    puts "","","hash insertion benchmarks",""

    Benchmark.bmbm do |x|
      x.report("insert 20k") do
        blocks = {}
        @networks_20k.each do |x|
          blocks[ IPAddr.new( x ) ] = true
        end
      end
      x.report("insert 50k") do
        blocks = {}
        @networks_50k.each do |x|
          blocks[ IPAddr.new( x ) ] = true
        end
      end
      x.report("insert 100k") do
        blocks = {}
        @networks_100k.each do |x|
          blocks[ IPAddr.new( x ) ] = true
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
