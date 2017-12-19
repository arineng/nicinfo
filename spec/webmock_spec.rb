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

    args = [ "http://rdap.arin.net/registry/entity/arin-o" ]

    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect(a_request(:get, "http://rdap.arin.net/registry/entity/arin-o")).to have_been_made.once
  end

  it 'be able to search for the arin entity and process 200' do
    response = File.new( "spec/recorded_responses/arin-entity-search.txt")
    stub_request(:get, "https://rdap.arin.net/registry/entities?fn=arin").to_return(response)

    dir = File.join( @work_dir, "test_search_200" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::Config.new( dir )
    config.logger=logger

    args = [ "arin" ]

    expect{ NicInfo::Main.new( args, config ).run }.to_not output.to_stdout
    expect(a_request(:get, "https://rdap.arin.net/registry/entities?fn=arin")).to have_been_made.once
  end
end