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


require 'tmpdir'
require 'fileutils'
require 'pp'
require 'spec_helper'
require 'rspec'
require_relative '../lib/nicinfo/appctx'
require_relative '../lib/nicinfo/common_meta'

describe 'common_meta' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_rf( @work_dir )

  end

  it 'should handle ex1' do

    dir = File.join( @work_dir, "test_common_meta_ex1" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new( dir )
    appctx.logger=logger

    json_data = JSON.load( File.read( "spec/other_resources/common_meta_ex1.json" ) )
    cj = NicInfo::CommonJson.new( appctx )
    entities = cj.process_entities( json_data )

    c = NicInfo::CommonMeta.new( json_data, entities, appctx )
    expect( c.meta_data[ NicInfo::CommonMeta::SERVICE_OPERATOR ] ).to eq( "apnic.net" )

    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_NAME ] ).to eq( "ARIN Operations ( ARIN-OPS )" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_COUNTRY ] ).to eq( "United States" )
    expect( c.meta_data[ NicInfo::CommonMeta::ABUSE_EMAIL ] ).to eq( "info@arin.net" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRATION_DATE ] ).to eq( "Mon, 31 Dec 1990 23:59:10 -0000" )
    expect( c.meta_data[ NicInfo::CommonMeta::EXPIRATION_DATE ] ).to eq( "Sun, 30 Nov 1997 23:59:10 -0000" )
    expect( c.meta_data[ NicInfo::CommonMeta::LAST_CHANGED_DATE ] ).to eq( "Thu, 30 Nov 1995 23:59:10 -0000" )
  end

  it 'should handle ex2' do

    dir = File.join( @work_dir, "test_common_meta_ex2" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new( dir )
    appctx.logger=logger

    json_data = JSON.load( File.read( "spec/other_resources/common_meta_ex2.json" ) )
    cj = NicInfo::CommonJson.new( appctx )
    entities = cj.process_entities( json_data )

    c = NicInfo::CommonMeta.new( json_data, entities, appctx )
    expect( c.meta_data[ NicInfo::CommonMeta::SERVICE_OPERATOR ] ).to eq( "registro.br" )

    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_NAME ] ).to eq( "TELEFÔNICA BRASIL S.A ( 02558157000162 )" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_COUNTRY ] ).to eq( "BR" )
    expect( c.meta_data[ NicInfo::CommonMeta::ABUSE_EMAIL ] ).to eq( "security@telesp.net.br" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRATION_DATE ] ).to eq( "Mon, 08 Dec 2003 12:00:00 -0000" )
    expect( c.meta_data[ NicInfo::CommonMeta::EXPIRATION_DATE ] ).to be_nil
    expect( c.meta_data[ NicInfo::CommonMeta::LAST_CHANGED_DATE ] ).to eq( "Wed, 23 Apr 2008 17:17:59 -0000" )
  end

  it 'should handle ex3' do

    dir = File.join( @work_dir, "test_common_meta_ex3" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new( dir )
    appctx.logger=logger

    json_data = JSON.load( File.read( "spec/other_resources/common_meta_ex3.json" ) )
    cj = NicInfo::CommonJson.new( appctx )
    entities = cj.process_entities( json_data )

    c = NicInfo::CommonMeta.new( json_data, entities, appctx )
    expect( c.meta_data[ NicInfo::CommonMeta::SERVICE_OPERATOR ] ).to eq( "ripe.net" )

    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_NAME ] ).to eq( "POLKOMTEL-MNT" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_COUNTRY ] ).to be_nil
    expect( c.meta_data[ NicInfo::CommonMeta::ABUSE_EMAIL ] ).to eq( "noc.ip@plus.pl" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRATION_DATE ] ).to be_nil
    expect( c.meta_data[ NicInfo::CommonMeta::EXPIRATION_DATE ] ).to be_nil
    expect( c.meta_data[ NicInfo::CommonMeta::LAST_CHANGED_DATE ] ).to eq( "Wed, 17 Apr 2013 09:03:21 -0000" )
  end

  it 'should handle ex4' do

    dir = File.join( @work_dir, "test_common_meta_ex4" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new( dir )
    appctx.logger=logger

    json_data = JSON.load( File.read( "spec/other_resources/common_meta_ex4.json" ) )
    cj = NicInfo::CommonJson.new( appctx )
    entities = cj.process_entities( json_data )

    c = NicInfo::CommonMeta.new( json_data, entities, appctx )
    expect( c.meta_data[ NicInfo::CommonMeta::SERVICE_OPERATOR ] ).to eq( "arin.net" )

    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_NAME ] ).to eq( "Comcast Cable Communications, LLC ( CCCS )" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRANT_COUNTRY ] ).to eq( "United States" )
    expect( c.meta_data[ NicInfo::CommonMeta::ABUSE_EMAIL ] ).to eq( "abuse@comcast.net" )
    expect( c.meta_data[ NicInfo::CommonMeta::REGISTRATION_DATE ] ).to eq( "Tue, 29 Jun 2010 11:36:51 -0400" )
    expect( c.meta_data[ NicInfo::CommonMeta::EXPIRATION_DATE ] ).to be_nil
    expect( c.meta_data[ NicInfo::CommonMeta::LAST_CHANGED_DATE ] ).to eq( "Wed, 31 Aug 2016 12:25:04 -0400" )
  end

end
