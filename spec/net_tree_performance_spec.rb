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

    @ips_1M = []
    (1..1000000).each do |x|
      @ips_1M << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

    @ips_2M = []
    (1..2000000).each do |x|
      @ips_2M << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

    @ips_4M = []
    (1..4000000).each do |x|
      @ips_4M << "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
    end

  end

  it 'should insert into tree' do


    Benchmark.bmbm do |x|
      x.report("insert 20k") do
        t = NicInfo::NetTree.new
        @networks_20k.each do |n|
          t.insert( n, true )
        end
      end
      x.report("insert 50k") do
        t = NicInfo::NetTree.new
        @networks_50k.each do |n|
          t.insert( n, true )
        end
      end
      x.report("insert 100k") do
        t = NicInfo::NetTree.new
        @networks_100k.each do |n|
          t.insert( n, true )
        end
      end
    end

  end

end
