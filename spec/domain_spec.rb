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
require_relative '../lib/nicinfo/domain'

describe 'ip spec' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_rf( @work_dir )

  end

  it 'should handle ex1' do

    dir = File.join( @work_dir, "test_domain_ex1" )

    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new( dir )
    appctx.logger=logger

    json_data = JSON.load( File.read( "spec/other_resources/domain_ex1.json" ) )
    domain = NicInfo::Domain.new( appctx )
    domain.process( json_data )

    meta_data = domain.objectclass[ NicInfo::CommonSummary::SUMMARY_DATA_NAME ]

    expect( meta_data[ NicInfo::CommonSummary::SERVICE_OPERATOR ] ).to eq( "verisignlabs.com" )

    expect( meta_data[ NicInfo::CommonSummary::REGISTRATION_DATE ] ).to eq( "Mon, 24 Jan 2000 17:23:52 -0000" )
    expect( meta_data[ NicInfo::CommonSummary::EXPIRATION_DATE ] ).to eq( "Thu, 24 Jan 2019 17:23:52 -0000" )
    expect( meta_data[ NicInfo::CommonSummary::LAST_CHANGED_DATE ] ).to eq("Sat, 25 Nov 2017 02:44:20 -0000" )

    expect( meta_data[ NicInfo::CommonSummary::REGISTRAR ] ).to eq("Network Solutions, LLC.~VRSN ( 2~VRSN )" )
    expect( meta_data[ NicInfo::CommonSummary::NAMESERVERS ].length ).to eq( 2 )
    expect( meta_data[ NicInfo::CommonSummary::NAMESERVERS ][0] ).to eq( "ZEKE.ECOTROPH.NET" )
    expect( meta_data[ NicInfo::CommonSummary::NAMESERVERS ][1] ).to eq( "NS.OGUD.COM" )
  end

end
