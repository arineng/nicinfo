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
require_relative '../lib/nicinfo/nicinfo_main'
require_relative '../lib/nicinfo/nicinfo_logger'

describe 'demos' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_rf( @work_dir )

  end

  it 'populate the cache with demo' do

    dir = File.join( @work_dir, "populate_cache_with_demo" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "--demo" ]

    main = NicInfo::Main.new( args, config )
    main.run
    expect( main.appctx.cache.count).to eq( 16 )

  end

  it 'autnum.json' do

    dir = File.join( @work_dir, "autnum_json" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "--demo" ]
    main = NicInfo::Main.new( args, config )
    main.run
    expect( main.appctx.cache.count).to eq( 16 )

    args = [ "as10" ]
    main = NicInfo::Main.new( args, config )
    allow( config.factory ).to receive(:new_autnum).and_call_original
    main.run
    expect( config.factory ).to have_received(:new_autnum).once

  end

  it 'error-code.json' do

    dir = File.join( @work_dir, "error_code_json" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "--demo" ]
    main = NicInfo::Main.new( args, config )
    main.run
    expect( main.appctx.cache.count).to eq( 16 )

    args = [ "--type", "entityhandle", "restricted" ]
    main = NicInfo::Main.new( args, config )
    allow( config.factory ).to receive(:new_error_code).and_call_original
    main.run
    expect( config.factory ).to have_received(:new_error_code).once

  end

  it 'domain-dnr.json' do

    dir = File.join( @work_dir, "domain-dnr_json" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "--demo" ]
    main = NicInfo::Main.new( args, config )
    main.run
    expect( main.appctx.cache.count).to eq( 16 )

    args = [ "--jcr", "standard", "xn--fo-5ja.example" ]
    main = NicInfo::Main.new( args, config )
    allow( main.jcr_context ).to receive( :evaluate ).and_call_original
    allow( config.factory ).to receive(:new_domain).and_call_original
    main.run
    expect( config.factory ).to have_received(:new_domain).once
    expect( main.jcr_context ).to have_received( :evaluate ).once

  end

  # TODO look at JCR checking status values properly
  # TODO tell LACNIC they are doing status values wrong
  # TODO tell RIPE they are doing IP addresses wrong
  # TODO tell APNIC that they are escaping newlines in unstructured addresses
  # TODO look into jcr strict checking for roles
  # TODO ask RIPE about spaces in addresses nicinfo -V --json --pretty 109.1.1.1
  # TODO ask LACNIC why 201.127.1.1 info shows in Whois but now RDAP
  # TODO ask AFRINIC about self links
  # TODO ask RIPE about 400 for 94.142.200.20
  # TODO ask LACNIC about redirect for 148.0.86.4
  # TODO ask APNIC about producing a 404
  # TODO tell AFRINIC about remarks that are multiple lines
  # TODO tell AFRINIC about countries in the wrong place in vcard
  # TODO it would seem LACNIC is not properly escaping quotation marks in JSON for https://rdap.lacnic.net/rdap/ip/200.9.4.4

  it 'domain-rir.json' do

    dir = File.join( @work_dir, "domain-rir_json" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    config = NicInfo::AppContext.new(dir )
    config.logger=logger
    config.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    args = [ "--demo" ]
    main = NicInfo::Main.new( args, config )
    main.run
    expect( main.appctx.cache.count).to eq( 16 )

    args = [ "--jcr", "strict", "192.in-addr.arpa" ]
    main = NicInfo::Main.new( args, config )
    allow( main.jcr_strict_context ).to receive( :evaluate ).and_call_original
    allow( config.factory ).to receive(:new_domain).and_call_original
    main.run
    expect( config.factory ).to have_received(:new_domain).once
    expect( main.jcr_strict_context ).to have_received( :evaluate ).once

  end

end