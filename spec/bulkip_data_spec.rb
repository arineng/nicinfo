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
require_relative '../lib/nicinfo/bulkip_data'
require_relative '../lib/nicinfo/ip'
require_relative '../lib/nicinfo/common_summary'

describe 'bulk_data test' do

  @work_dir = nil

  before( :all ) do

    @work_dir = Dir.mktmpdir

  end

  after( :all ) do

    FileUtils.rm_r( @work_dir )

  end

  it 'should scan population' do

    dir = File.join( @work_dir, "scan_population" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new(dir )
    appctx.logger=logger
    appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    ip192 = NicInfo::Ip.new( appctx )
    ip192.summary_data = Hash.new
    ip192.summary_data[ NicInfo::CommonSummary::CIDRS ] = [ "192.168.0.0/16" ]

    ip10 = NicInfo::Ip.new( appctx )
    ip10.summary_data = Hash.new
    ip10.summary_data[ NicInfo::CommonSummary::CIDRS ] = [ "10.0.0.0/8" ]

    b = NicInfo::BulkIPData.new( appctx )
    b.note_new_file
    t = Time.new
    expect( b.hit_ipaddr( IPAddr.new( "192.168.0.1" ), t ) ).to be_falsey
    b.hit_network( ip192, t )
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), t ) ).to be_falsey
    expect( b.hit_ipaddr( IPAddr.new( "192.168.0.1" ), t ) ).to be_truthy
    t = t + 300
    expect( b.hit_ipaddr( IPAddr.new( "10.0.0.1" ), t ) ).to be_falsey
    b.hit_network( ip10, t )
    expect( b.hit_ipaddr( IPAddr.new( "10.0.0.1" ), t ) ).to be_truthy
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), t ) ).to be_falsey

  end

  it 'should sample population' do

    dir = File.join( @work_dir, "sample_population" )
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    appctx = NicInfo::AppContext.new(dir )
    appctx.logger=logger
    appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::UPDATE_BSFILES ]=false

    ip192 = NicInfo::Ip.new( appctx )
    ip192.summary_data = Hash.new
    ip192.summary_data[ NicInfo::CommonSummary::CIDRS ] = [ "192.168.0.0/16" ]

    b = NicInfo::BulkIPData.new( appctx )
    b.set_interval_seconds_to_increment( 100 )
    b.note_new_file
    t = Time.at( 100 )
    expect( b.hit_ipaddr( IPAddr.new( "192.168.0.1" ), t ) ).to be_falsey
    expect( b.second_to_sample.to_i ).to eq( t.to_i )
    expect( b.interval ).to eq( 0 )
    b.hit_network( ip192, t )
    t = t + 1
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), t ) ).to be_truthy
    expect( b.second_to_sample.to_i ).to be >= (t.to_i + 100 )
    expect( b.second_to_sample.to_i ).to be < (t.to_i + 200 )
    expect( b.interval ).to eq( 1 )
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), Time.at( b.second_to_sample ) ) ).to be_falsey
    expect( b.hit_ipaddr( IPAddr.new( "192.168.0.1" ), Time.at( b.second_to_sample ) ) ).to be_truthy
    t = t + 200
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), t ) ).to be_truthy
    expect( b.interval ).to eq( 2 )
    expect( b.second_to_sample.to_i ).to be >= (t.to_i + 100 )
    expect( b.second_to_sample.to_i ).to be < (t.to_i + 200 )
    t = t + 1
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), t ) ).to be_truthy
    expect( b.second_to_sample.to_i ).to be >= (t.to_i + 100 )
    expect( b.second_to_sample.to_i ).to be < (t.to_i + 200 )
    expect( b.hit_ipaddr( IPAddr.new( "192.0.0.1" ), Time.at( b.second_to_sample ) ) ).to be_falsey
    expect( b.hit_ipaddr( IPAddr.new( "192.168.0.1" ), Time.at( b.second_to_sample ) ) ).to be_truthy

  end

end
