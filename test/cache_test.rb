# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
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


require 'tmpdir'
require 'fileutils'
require 'test/unit'
require 'config'
require 'cache'


class CacheTests < Test::Unit::TestCase

  @work_dir = nil

  def setup

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

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_make_safe

    assert_equal( ARINcli::make_safe( "http://" ), "http%3A%2F%2F" )
    assert_equal( ARINcli::make_safe(
                          "http://whois.arin.net/rest/nets;q=192.136.136.1?showDetails=true&showARIN=false" ),
                  "http%3A%2F%2Fwhois.arin.net%2Frest%2Fnets%3Bq%3D192.136.136.1%3FshowDetails%3Dtrue%26showARIN%3Dfalse")
    assert_equal( ARINcli::make_safe( "marry had a little lamb!" ), "marry%20had%20a%20little%20lamb%21" )

  end

  def test_create_or_update

    dir = File.join( @work_dir, "test_create_or_update" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    safe = ARINcli::make_safe( url )
    file_name = File.join( c.whois_cache_dir, safe )
    assert( File.exist?( file_name ) )
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    assert_equal( @net_xml, data )

    # do it again
    new_xml = @net_xml + "\n**Second**Time**\n"
    cache.create_or_update( url, new_xml )
    assert( File.exist?( file_name ) )
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    assert_equal( new_xml, data )
  end

  def test_create

    dir = File.join( @work_dir, "test_create" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    c.config[ "whois" ][ "cache_expiry" ] = 9000 # really any number above 1 should be good

    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    safe = ARINcli::make_safe( url )
    file_name = File.join( c.whois_cache_dir, safe )
    assert( File.exist?( file_name ) )
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    assert_equal( @net_xml, data )

    # do it again, but the data should be the same as the first time when read back out
    new_xml = @net_xml + "\n**Second**Time**\n"
    cache.create( url, new_xml )
    assert( File.exist?( file_name ) )
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    assert_equal( @net_xml, data )
  end

  def test_get_hit

    dir = File.join( @work_dir, "test_get_hit" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ "whois" ][ "use_cache" ] = true
    c.config[ "whois" ][ "cache_expiry" ] = 9000 # really any number above 1 should be good
    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    assert_equal( @net_xml, data )

  end

  def test_get_no_hit

    dir = File.join( @work_dir, "test_get_no_hit" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ "whois" ][ "use_cache" ] = true
    c.config[ "whois" ][ "cache_expiry" ] = 9000 # really any number above 1 should be good
    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( "http://whois.arin.net/rest/net/NET-192-136-136-0-2" )
    assert_nil( data )

  end

  def test_get_expired_hit

    dir = File.join( @work_dir, "test_get_expired_hit" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ "whois" ][ "use_cache" ] = true
    c.config[ "whois" ][ "cache_expiry" ] = -19000 # really any number less than -1 should be good
    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    assert_nil( data )

  end

  def test_no_use_cache

    dir = File.join( @work_dir, "test_no_use_cache" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ "whois" ][ "use_cache" ] = false
    c.config[ "whois" ][ "cache_expiry" ] = 9000 # really any number above 1 should be good
    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.create_or_update( url, @net_xml )

    data = cache.get( url )
    assert_nil( data )

  end

  def test_clean

    dir = File.join( @work_dir, "test_clean" )
    c = ARINcli::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    c.config[ "whois" ][ "use_cache" ] = true
    c.config[ "whois" ][ "cache_eviction" ] = -19000 # really any number less than -1 should be good
    cache = ARINcli::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-"
    cache.create_or_update( url + "1", @net_xml )
    cache.create_or_update( url + "2", @net_xml )
    cache.create_or_update( url + "3", @net_xml )

    count = cache.clean
    assert_equal( 3, count )

  end

end

