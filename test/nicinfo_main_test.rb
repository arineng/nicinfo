# Copyright (C) 2011,2012,2013,2014 American Registry for Internet Numbers
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
require 'pp'

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
    assert_equal( nicinfo.guess_query_value_type( [ "ns1.example.com." ] ), "NAMESERVER" )
    assert_equal( nicinfo.guess_query_value_type( [ "1=" ] ), "RESULT" )
    assert_equal( nicinfo.guess_query_value_type( [ "1.1=" ] ), "RESULT" )
    assert_equal( nicinfo.guess_query_value_type( [ "1.1.1=" ] ), "RESULT" )
    assert_equal( nicinfo.guess_query_value_type( [ "foo" ] ), "ESBYNAME" )
    assert_equal( nicinfo.guess_query_value_type( [ "http://rdap.arin.net/ip/1.1.1.1" ] ), "URL" )

  end

  def test_get_query_type_from_url

    dir = File.join( @work_dir, "test_get_query_type_from_url" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )

    assert_equal( "IP", nicinfo.get_query_type_from_url( "http://example.com/rdap/ip/2001:db8:00" ) )
    assert_equal( "IP", nicinfo.get_query_type_from_url( "http://example.com/rdap/ip/192.0.2.0/24" ) )
    assert_equal( "ASNUMBER", nicinfo.get_query_type_from_url( "http://example.com/rdap/autnum/21" ) )
    assert_equal( "DOMAIN", nicinfo.get_query_type_from_url( "http://example.com/rdap/domain/example.com" ) )
    assert_equal( "ENTITYHANDLE", nicinfo.get_query_type_from_url( "http://example.com/rdap/entity/CE12" ) )

  end

  def test_eval_json_value

    data = <<JSON_DATA
{
    "rdapConformance":[
        "rdap_level_0"
    ],
    "notices":[
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        }
    ],
    "lang":"en",
    "startAddress":"192.0.2.0",
    "endAddress":"192.0.2.255",
    "remarks":[
        {
            "description":[
                "She sells sea shells down by the sea shore.",
                "Originally written by Terry Sullivan."
            ]
        }
    ]
}
JSON_DATA

    dir = File.join( @work_dir, "test_get_query_type_from_url" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )
    json_data = JSON::load( data )

    assert_equal( "192.0.2.0", nicinfo.eval_json_value( "startAddress", json_data ) )
    assert_equal( "192.0.2.255", nicinfo.eval_json_value( "endAddress", json_data ) )
    assert_equal( "rdap_level_0", nicinfo.eval_json_value( "rdapConformance.0", json_data ) )
    assert_equal( "Sorry, dude!", nicinfo.eval_json_value( "notices.0.description.1", json_data ) )
  end

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
