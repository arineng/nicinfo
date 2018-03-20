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

require 'time'
require 'ipaddr'
require 'spec_helper'
require 'rspec'
require 'pp'
require_relative '../lib/nicinfo/bulkip_main'

describe 'bulk_main test' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_rf( @work_dir )

  end

  it 'should create template file' do

    dir = File.join( @work_dir, "create_template" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new(dir )
    appctx.logger=logger
    appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    appctx.setup_workspace
    bm = NicInfo::BulkIPMain.new( appctx )
    fn = File.join( dir, "new_bulkip_config.yaml" )
    bm.configure( fn )
    expect( File.exists?( fn ) ).to be_truthy

  end

end
