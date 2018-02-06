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
require 'pp'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/nicinfo/appctx'
require_relative '../lib/nicinfo/cache'
require_relative '../lib/nicinfo/constants'


describe 'cache rspec tests' do

  @work_dir = nil

  before(:all) do

    @work_dir = Dir.mktmpdir

    # the contents are important... just that it is an XML blob
    @net_xml = <<NET_XML
<net xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" termsOfUse="https://www.arin.net/whois_tou.html">
  <registrationDate>2002-04-17T00:00:00-04:00</registrationDate>
  <ref>http://whois.arin.net/rest/net/NET-192-136-136-0-1</ref>
  <endAddress>192.136.136.255</endAddress>
  <handle>NET-192-136-136-0-1</handle>
  <name>ARIN-BLK-2</name>
  <originASes>
    <originAS>AS10745</originAS>
    <originAS>AS107450</originAS>
  </originASes>
  <orgRef name="American Registry for Internet Numbers" handle="ARIN">http://whois.arin.net/rest/org/ARIN</orgRef>
  <parentNetRef name="NET192" handle="NET-192-0-0-0-0">http://whois.arin.net/rest/net/NET-192-0-0-0-0</parentNetRef>
  <startAddress>192.136.136.0</startAddress>
  <updateDate>2011-03-19T00:00:00-04:00</updateDate>
  <version>4</version>
</net>
NET_XML

  end

  after(:all) do

    FileUtils.rm_rf( @work_dir )

  end

  it 'should make_safe correctly' do

    expect( NicInfo::make_safe( "http://" ) ).to eq( "http%3A%2F%2F" )
    expect( NicInfo::make_safe( "http://whois.arin.net/rest/nets;q=192.136.136.1?showDetails=true&showARIN=false" ) ).to eq( "http%3A%2F%2Fwhois.arin.net%2Frest%2Fnets%3Bq%3D192.136.136.1%3FshowDetails%3Dtrue%26showARIN%3Dfalse" )
    expect( NicInfo::make_safe( "marry had a little lamb!" ) ).to eq( "marry%20had%20a%20little%20lamb%21" )

  end

  it 'should create or update the cache' do

    dir = File.join( @work_dir, "test_create_or_update" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    safe = NicInfo::make_safe( url )
    file_name = File.join( c.rdap_cache_dir, safe )
    expect( File.exist?( file_name ) ).to be_truthy
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    expect( data ).to eq( @net_xml )

    # do it again
    new_xml = @net_xml + "\n**Second**Time**\n"
    cache.create_or_update( url, new_xml )
    expect( File.exist?( file_name ) ).to be_truthy
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    expect( new_xml ).to eq( data )
  end

  it 'should create a cache' do

    dir = File.join( @work_dir, "test_create" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = 9000 # really any number above 1 should be good

    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    safe = NicInfo::make_safe( url )
    file_name = File.join( c.rdap_cache_dir, safe )
    expect( File.exist?( file_name ) ).to be_truthy
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    expect( data ).to eq( @net_xml )

    # do it again, but the data should be the same as the first time when read back out
    new_xml = @net_xml + "\n**Second**Time**\n"
    cache.create( url, new_xml )
    expect( File.exist?( file_name ) ).to be_truthy
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    expect( data ).to eq( @net_xml )
  end

  it 'should get a cache hit' do

    dir = File.join( @work_dir, "test_get_hit" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = 9000 # really any number above 1 should be good
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    expect( data ).to eq( @net_xml )

  end

  it 'should get no cache hit' do

    dir = File.join( @work_dir, "test_get_no_hit" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = 9000 # really any number above 1 should be good
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( "http://whois.arin.net/rest/net/NET-192-136-136-0-2" )
    expect( data ).to be_nil

  end

  it 'should get expired hit' do

    dir = File.join( @work_dir, "test_get_expired_hit" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = -19000 # really any number less than -1 should be good
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    expect( data ).to be_nil

  end

  it 'should not use the cache' do

    dir = File.join( @work_dir, "test_no_use_cache" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = false
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = 9000 # really any number above 1 should be good
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    expect( data ).to be_nil

  end

  it 'should clean out the cache' do

    dir = File.join( @work_dir, "test_clean" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true
    c.config[ NicInfo::CACHE ][ NicInfo::CACHE_EVICTION ] = -19000 # really any number less than -1 should be good
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-"
    cache.create_or_update( url + "1", @net_xml )
    cache.create_or_update( url + "2", @net_xml )
    cache.create_or_update( url + "3", @net_xml )

    count = cache.clean
    expect( count ).to eq( 3 )

  end

  it 'should empty the cache' do

    dir = File.join( @work_dir, "test_empty" )
    c = NicInfo::AppContext.new(dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true
    cache = NicInfo::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-"
    cache.create_or_update( url + "1", @net_xml )
    cache.create_or_update( url + "2", @net_xml )
    cache.create_or_update( url + "3", @net_xml )

    count = cache.empty
    expect( count ).to eq( 3 )
    expect( cache.count ).to eq( 0 )

  end

end

