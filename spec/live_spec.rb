# Copyright (C) 2017 American Registry for Internet Numbers
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
require_relative '../lib/nicinfo/config'
require_relative '../lib/nicinfo/nicinfo_main'
require_relative '../lib/nicinfo/nicinfo_logger'

describe 'live', :live => true do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir
    WebMock.disable!

  end

  after( :all ) do

    FileUtils.rm_r( @work_dir )
    WebMock.enable!

  end

  it 'should download IANA files automatically' do

    dir = File.join( @work_dir, "test_download_iana_files_auto" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger

    args = [ "http://rdap.arin.net/registry/entity/arin-o" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to have_received(:new_error_code).once
    expect( config.factory).to have_received(:new_notices).once
  end

  it 'be able to query arin-o and not crash on 404' do

    dir = File.join( @work_dir, "test_query_404" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "http://rdap.arin.net/registry/entity/arin-o" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to have_received(:new_error_code).once
    expect( config.factory).to have_received(:new_notices).once
  end

  it 'be able to query arin-hostmaster and process 200' do

    dir = File.join( @work_dir, "test_query_arin_hostmaster_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "http://rdap.arin.net/registry/entity/arin-hostmaster" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 1 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 1 ).times
  end

  it 'be able to query arin-hostmaster and process 200 and update iana files' do

    dir = File.join( @work_dir, "test_query_arin_hostmaster_200_update_iana" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger

    args = [ "http://rdap.arin.net/registry/entity/arin-hostmaster" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 1 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 1 ).times
  end

  it 'be able to search for the arin entity and process 200' do

    dir = File.join( @work_dir, "test_search_entity_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "arin" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 18 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 65 ).times
  end

  it 'should process an IP lookup' do

    dir = File.join( @work_dir, "test_lookup_ip_108_45_128_208_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "108.45.128.208" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_ip).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 4 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 7 ).times
    expect( config.factory).to have_received(:new_ip).once
  end

  it 'should process an autnum lookup' do

    dir = File.join( @work_dir, "test_lookup_autnum_703_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "AS703" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_autnum).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 4 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 6 ).times
    expect( config.factory).to have_received(:new_autnum).once
  end

  it 'should process an ns lookup' do

    dir = File.join( @work_dir, "test_lookup_ns1_arin_net_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "ns1.arin.net" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_ns).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).once
    expect( config.factory).to_not have_received(:new_entity)
    expect( config.factory).to have_received(:new_ns).once
  end

  it 'should process a domain lookup' do

    dir = File.join( @work_dir, "test_lookup_domain_arin_net_200" )
    logger = NicInfo::Logger.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.pager = false
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "arin.net" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_ns).and_call_original
    allow( config.factory ).to receive(:new_domain).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not raise_error
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).once
    expect( config.factory).to have_received(:new_entity).once
    expect( config.factory).to have_received(:new_ns).exactly( 4 ).times
    expect( config.factory).to have_received(:new_domain).once
  end

end