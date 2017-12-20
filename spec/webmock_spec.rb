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
require 'webmock/rspec'
require_relative '../lib/nicinfo/config'
require_relative '../lib/nicinfo/nicinfo_main'
require_relative '../lib/nicinfo/nicinfo_logger'

describe 'web mocks' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_r( @work_dir )

  end

  it 'be able to query arin-o and not crash on 404' do
    arino = File.new( "spec/recorded_responses/arin-o.txt")
    stub_request(:get, "http://rdap.arin.net/registry/entity/arin-o").to_return(arino)

    dir = File.join( @work_dir, "test_query_404" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "http://rdap.arin.net/registry/entity/arin-o" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect( config.factory).to have_received(:new_error_code).once
    expect( config.factory).to have_received(:new_notices).once
    expect(a_request(:get, "http://rdap.arin.net/registry/entity/arin-o")).to have_been_made.once
  end

  it 'be able to search for the arin entity and process 200' do
    response = File.new( "spec/recorded_responses/arin-entity-search.txt")
    stub_request(:get, "https://rdap.arin.net/registry/entities?fn=arin").to_return(response)

    dir = File.join( @work_dir, "test_search_entity_200" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "arin" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 18 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 65 ).times
    expect(a_request(:get, "https://rdap.arin.net/registry/entities?fn=arin")).to have_been_made.once
  end

  it 'should process an IP lookup' do
    response = File.new( "spec/recorded_responses/ip_108_45_128_208.txt")
    stub_request(:get, "https://rdap.arin.net/registry/ip/108.45.128.208").to_return(response)

    dir = File.join( @work_dir, "test_search_entity_200" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "108.45.128.208" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_ip).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 4 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 7 ).times
    expect( config.factory).to have_received(:new_ip).once
    expect(a_request(:get, "https://rdap.arin.net/registry/ip/108.45.128.208")).to have_been_made.once
  end

  it 'should process an autnum lookup' do
    response = File.new( "spec/recorded_responses/autnum_703.txt")
    stub_request(:get, "https://rdap.arin.net/registry/autnum/703").to_return(response)

    dir = File.join( @work_dir, "test_search_entity_200" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "AS703" ]

    allow( config.factory ).to receive(:new_error_code).and_call_original
    allow( config.factory ).to receive(:new_notices).and_call_original
    allow( config.factory ).to receive(:new_entity).and_call_original
    allow( config.factory ).to receive(:new_autnum).and_call_original
    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect( config.factory).to_not have_received(:new_error_code)
    expect( config.factory).to have_received(:new_notices).exactly( 4 ).times
    expect( config.factory).to have_received(:new_entity).exactly( 6 ).times
    expect( config.factory).to have_received(:new_autnum).once
    expect(a_request(:get, "https://rdap.arin.net/registry/autnum/703")).to have_been_made.once
  end
end