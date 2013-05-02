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
require 'config'
require 'test/unit'
require 'nicinfo_main'
require 'nicinfo_logger'

class NicInfoMainTest < Test::Unit::TestCase

  @work_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_guess_query

    dir = File.join( @work_dir, "test_guess_query" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )

    assert_equal( nicinfo.guess_query_value_type( [ "1.0.0.0" ] ), "IP4ADDR" )
    assert_equal( nicinfo.guess_query_value_type( [ "199.0.0.0" ] ), "IP4ADDR" )
    assert_equal( nicinfo.guess_query_value_type( [ "255.255.255.255" ] ), "IP4ADDR" )
    assert_equal( nicinfo.guess_query_value_type( [ "255.255.255.256" ] ), nil )
    assert_equal( nicinfo.guess_query_value_type( [ "256.255.255.255" ] ), nil )
    assert_equal( nicinfo.guess_query_value_type( [ "2001:500:13::" ] ), "IP6ADDR" )
    assert_equal( nicinfo.guess_query_value_type( [ "2001:500:13:FFFF:FFFF:FFFF:FFFF:FFFF" ] ), "IP6ADDR" )
    assert_equal( nicinfo.guess_query_value_type( [ "10745" ] ), "ASNUMBER" )
    assert_equal( nicinfo.guess_query_value_type( [ "11110745" ] ), "ASNUMBER" )
    assert_equal( nicinfo.guess_query_value_type( [ "AS10745" ] ), "ASNUMBER" )
    assert_equal( nicinfo.guess_query_value_type( [ "AS11110745" ] ), "ASNUMBER" )
    assert_equal( nicinfo.guess_query_value_type( [ "199.in-addr.arpa" ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "199.in-addr.arpa." ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "136.199.in-addr.arpa" ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "136.199.in-addr.arpa." ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa" ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa." ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "example.com" ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "example.com." ] ), "DOMAIN" )
    assert_equal( nicinfo.guess_query_value_type( [ "foo" ] ), "ENTITYNAME" )

  end

  #def test_create_query
  #
  #  dir = File.join( @work_dir, "test_create_query" )
  #
  #  logger = NicInfo::Logger.new
  #  logger.message_out = StringIO.new
  #  logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
  #  config = NicInfo::Config.new( dir )
  #  config.logger=logger
  #
  #  arinw = NicInfo::Main.new( [], config )
  #
  #  assert_equal( "rest/net/NET-192-136-136-1",
  #                arinw.create_resource_url(
  #                    [ "NET-192-136-136-1" ], NicInfo::QueryType::BY_NET_HANDLE ) )
  #  assert_equal( "rest/net/NET6-2001-500-13-1",
  #                arinw.create_resource_url(
  #                    [ "NET6-2001-500-13-1" ], NicInfo::QueryType::BY_NET_HANDLE ) )
  #  assert_equal( "rest/poc/ALN-ARIN",
  #                arinw.create_resource_url(
  #                    [ "ALN-ARIN" ], NicInfo::QueryType::BY_POC_HANDLE ) )
  #  assert_equal( "rest/ip/1.0.0.0",
  #                arinw.create_resource_url(
  #                    [ "1.0.0.0" ], NicInfo::QueryType::BY_IP4_ADDR ) )
  #  assert_equal( "rest/ip/2001:500:13::",
  #                arinw.create_resource_url(
  #                    [ "2001:500:13::" ], NicInfo::QueryType::BY_IP6_ADDR ) )
  #  assert_equal( "rest/rdns/8.f.4.0.1.0.0.2.ip6.arpa",
  #                arinw.create_resource_url(
  #                    [ "8.f.4.0.1.0.0.2.ip6.arpa" ], NicInfo::QueryType::BY_DELEGATION ) )
  #  assert_equal( "rest/rdns/199.in-addr.arpa",
  #                arinw.create_resource_url(
  #                    [ "199.in-addr.arpa" ], NicInfo::QueryType::BY_DELEGATION ) )
  #end

  def test_base_opts

    dir = File.join( @work_dir, "test_base_opts" )
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger

    args = [ "--messages", "ALL", "BAR" ]
    e = NicInfo::Main.new( args, config )

    assert_equal( "ALL", config.logger.message_level.to_s )
    assert_equal( [ "BAR" ], config.options.argv )

  end

  def test_help_option

    dir = File.join( @work_dir, "test_help_option" )
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger
    args = [ "-h" ]
    e = NicInfo::Main.new( args, config )

    assert_equal( [], config.options.argv )
    assert( config.options.help )

  end
end
