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


require 'spec_helper'
require 'rspec'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/nicinfo/config'
require_relative '../lib/nicinfo/nicinfo_logger'
require_relative '../lib/nicinfo/constants'

describe 'configuration tests' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_r( @work_dir )

  end

  it 'test initialization with not config files' do

    dir = File.join( @work_dir, "test_init_no_config_file" )

    c = NicInfo::Config.new( dir )
    expect( c.config[ "output" ][ "messages" ] ).to eq( "SOME" )
    expect( c.config[ "output" ][ "data" ] ).to eq( "NORMAL" )
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::MESSAGES_FILE ] ).to be_nil
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::DATA_FILE ] ).to be_nil
    expect( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ] ).to eq( "https://rdap.arin.net/registry" )

    expect( c.logger.data_amount ).to eq( "NORMAL" )
    expect( c.logger.message_level ).to eq( "SOME" )

  end

  it 'should test an init config file' do

    dir = File.join( @work_dir, "test_init_config_file" )
    Dir.mkdir( dir )
    not_default_config = <<NOT_DEFAULT_CONFIG
output:
  messages: NONE
  #messages_file: /tmp/NicInfo.messages
  data: TERSE
  #data_file: /tmp/NicInfo.data
bootstrap:
  ip_root_url: https://rdap.arin.net/bootstrap
NOT_DEFAULT_CONFIG
    f = File.open( File.join( dir, "config.yaml" ), "w" )
    f.puts( not_default_config )
    f.close

    c = NicInfo::Config.new( dir )
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::MESSAGES ] ).to eq( "NONE" )
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::DATA ] ).to eq( "TERSE" )
    expect( c.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ] ).to be_truthy
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::MESSAGES_FILE ] ).to be_nil
    expect( c.config[ NicInfo::OUTPUT ][ NicInfo::DATA_FILE ] ).to be_nil
    expect( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ] ).to eq( "https://rdap.arin.net/bootstrap" )

    expect( c.logger.data_amount ).to eq( "TERSE" )
    expect( c.logger.message_level ).to eq( "NONE" )

  end

  it 'should setup the workspace' do

    dir = File.join( @work_dir, "test_setup_workspace" )

    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    expect( File.exist?( File.join( dir, "config.yaml" ) ) ).to be_truthy
    expect( File.exist?( File.join( dir, "rdap_cache" ) ) ).to be_truthy
    expect( File.join( dir, "rdap_cache" ) ).to eq( c.rdap_cache_dir )

  end

end
