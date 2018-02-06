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
require 'pp'
require 'spec_helper'
require 'rspec'
require_relative '../lib/nicinfo/appctx'
require_relative '../lib/nicinfo/nicinfo_main'
require_relative '../lib/nicinfo/nicinfo_logger'

describe 'main entry tests' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_r( @work_dir )

  end

  it 'should guess queries right' do

    dir = File.join( @work_dir, "test_guess_query" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )

    expect( nicinfo.guess_query_value_type( [ "1.0.0.0" ] ) ).to eq( "IP4ADDR" )
    expect( nicinfo.guess_query_value_type( [ "199.0.0.0" ] ) ).to eq( "IP4ADDR" )
    expect( nicinfo.guess_query_value_type( [ "255.255.255.255" ] ) ).to eq( "IP4ADDR" )
    expect( nicinfo.guess_query_value_type( [ "255.255.255.256" ] ) ).to be_nil
    expect( nicinfo.guess_query_value_type( [ "256.255.255.255" ] ) ).to be_nil
    expect( nicinfo.guess_query_value_type( [ "2001:500:13::" ] ) ).to eq( "IP6ADDR" )
    expect( nicinfo.guess_query_value_type( [ "2001:500:13:FFFF:FFFF:FFFF:FFFF:FFFF" ] ) ).to eq( "IP6ADDR" )
    expect( nicinfo.guess_query_value_type( [ "10745" ] ) ).to eq( "ASNUMBER" )
    expect( nicinfo.guess_query_value_type( [ "11110745" ] ) ).to eq( "ASNUMBER" )
    expect( nicinfo.guess_query_value_type( [ "AS10745" ] ) ).to eq( "ASNUMBER" )
    expect( nicinfo.guess_query_value_type( [ "AS11110745" ] ) ).to eq( "ASNUMBER" )
    expect( nicinfo.guess_query_value_type( [ "199.in-addr.arpa" ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "199.in-addr.arpa." ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "136.199.in-addr.arpa" ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "136.199.in-addr.arpa." ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa" ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa." ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "example.com" ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "example.com." ] ) ).to eq( "DOMAIN" )
    expect( nicinfo.guess_query_value_type( [ "ns1.example.com." ] ) ).to eq( "NAMESERVER" )
    expect( nicinfo.guess_query_value_type( [ "1=" ] ) ).to eq( "RESULT" )
    expect( nicinfo.guess_query_value_type( [ "1.1=" ] ) ).to eq( "RESULT" )
    expect( nicinfo.guess_query_value_type( [ "1.1.1=" ] ) ).to eq( "RESULT" )
    expect( nicinfo.guess_query_value_type( [ "foo" ] ) ).to eq( "ESBYNAME" )
    expect( nicinfo.guess_query_value_type( [ "http://rdap.arin.net/ip/1.1.1.1" ] ) ).to eq( "URL" )

  end

  it 'should qet query from url' do

    dir = File.join( @work_dir, "test_get_query_type_from_url" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )

    expect( nicinfo.get_query_type_from_url( "http://example.com/rdap/ip/2001:db8:00" ) ).to eq( "IP" )
    expect( nicinfo.get_query_type_from_url( "http://example.com/rdap/ip/192.0.2.0/24" ) ).to eq( "IP" )
    expect( nicinfo.get_query_type_from_url( "http://example.com/rdap/autnum/21" ) ).to eq( "ASNUMBER" )
    expect( nicinfo.get_query_type_from_url( "http://example.com/rdap/domain/example.com" ) ).to eq( "DOMAIN" )
    expect( nicinfo.get_query_type_from_url( "http://example.com/rdap/entity/CE12" ) ).to eq( "ENTITYHANDLE" )

  end

  it 'should evaluate json values' do

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
    config = NicInfo::AppContext.new(dir )
    config.logger=logger

    nicinfo = NicInfo::Main.new( [], config )
    json_data = JSON::load( data )

    expect( nicinfo.eval_json_value( "startAddress", json_data ) ).to eq( "192.0.2.0" )
    expect( nicinfo.eval_json_value( "endAddress", json_data ) ).to eq( "192.0.2.255" )
    expect( nicinfo.eval_json_value( "rdapConformance.0", json_data ) ).to eq( "rdap_level_0" )
    expect( nicinfo.eval_json_value( "notices.0.description.1", json_data ) ).to eq( "Sorry, dude!" )
  end

  it 'should understand command line options' do

    dir = File.join( @work_dir, "test_base_opts" )
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger

    args = [ "--messages", "ALL", "BAR" ]
    e = NicInfo::Main.new( args, config )

    expect( config.logger.message_level.to_s ).to eq( "ALL" )
    expect( config.options.argv ).to eq( [ "BAR" ] )

  end

  it 'should understand help option' do

    dir = File.join( @work_dir, "test_help_option" )
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    args = [ "-h" ]
    e = NicInfo::Main.new( args, config )

    expect( config.options.argv ).to eq( [] )
    expect( config.options.help ).to be_truthy

  end

  it 'should understand a bunch of parameters' do

    dir = File.join( @work_dir, "test_a_bunch_of_parameters" )
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    args = [ "-r", "-b", "https://rdap.example" ]
    e = NicInfo::Main.new( args, config )

    expect( config.options.argv ).to eq( [] )
    expect( config.options.reverse_ip ).to be_truthy
    expect( config.config[NicInfo::BOOTSTRAP][NicInfo::BOOTSTRAP_URL] ).to eq( "https://rdap.example" )

  end
end
