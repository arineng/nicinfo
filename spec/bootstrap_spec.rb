# Copyright (C) 2013-2017 American Registry for Internet Numbers
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
require 'pp'
require_relative '../lib/nicinfo/bootstrap'
require_relative '../lib/nicinfo/appctx'

describe 'bootstrap rspec tests' do

  CZ_URL = "https://rdap.nic.cz"
  IANA_URL = "https://rdap.iana.org"
  ARIN_URL = "https://rdap.arin.net/registry"
  APNIC_URL = "https://rdap.apnic.net/"
  LACNIC_URL = "https://rdap.lacnic.net/rdap/"
  AFRINIC_URL = "https://rdap.afrinic.net/rdap/"
  RIPE_URL = "https://rdap.db.ripe.net/"

  @work_dir = nil

  before(:all) do
    @work_dir = Dir.mktmpdir
  end

  after(:all) do
    FileUtils.rm_r( @work_dir )
  end

  it 'should test find urls by ipv4' do
    dir = File.join( @work_dir, "test_find_url_by_v4" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_ip( "216.0.0.1" ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_ip( "218.0.0.1" ) ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_ip( "1.1.1.1" ) ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_ip( "212.0.0.1" ) ).to eq( RIPE_URL )
    expect( bootstrap.find_url_by_ip( "200.0.0.1" ) ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_ip( "102.0.0.1" ) ).to eq( AFRINIC_URL )
    expect( bootstrap.find_url_by_ip( "128.0.0.1" ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_ip( "133.0.0.1" ) ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_ip( "151.0.0.1" ) ).to eq( RIPE_URL )
    expect( bootstrap.find_url_by_ip( "191.0.0.1" ) ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_ip( "196.0.0.1" ) ).to eq( AFRINIC_URL )
  end

  it 'should find urls by ipv6' do
    dir = File.join( @work_dir, "test_find_url_by_v6" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_ip( "1001:0000::1") ).to eq( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ] )
    expect( bootstrap.find_url_by_ip( "2001:0400::/23" ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_ip( "2001:0200::/23" ) ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_ip( "2001:0600::/23" ) ).to eq( RIPE_URL )
    expect( bootstrap.find_url_by_ip( "2001:1200::/23" ) ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_ip( "2001:4200::/23" ) ).to eq( AFRINIC_URL )
  end

  it 'should find url by as' do
    dir = File.join( @work_dir, "test_find_url_by_as" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_as( 26756 ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_as( 26755 ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_as( 27575 ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_as( 23552 ) ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_as( 27648 ) ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_as( 24735 ) ).to eq( RIPE_URL )
    expect( bootstrap.find_url_by_as( 23541 ) ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_as( 23549 ) ).to eq( AFRINIC_URL )
    expect( bootstrap.find_url_by_as( 393216 ) ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_as( 0 ) ).to eq( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AS_ROOT_URL ] )
  end

  it 'should get ipv4 from inaddr' do
    dir = File.join( @work_dir, "test_find_ip4_from_inaddr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.get_ip4_by_inaddr( "1.0.0.192.in-addr.arpa.") ).to eq( IPAddr.new( "192.0.0.1" ) )
    expect( bootstrap.get_ip4_by_inaddr( "1.0.0.192.in-addr.arpa") ).to eq( IPAddr.new( "192.0.0.1" ) )
    expect( bootstrap.get_ip4_by_inaddr( "0.0.192.in-addr.arpa") ).to eq( IPAddr.new( "192.0.0.0" ) )
    expect( bootstrap.get_ip4_by_inaddr( "0.192.in-addr.arpa") ).to eq( IPAddr.new( "192.0.0.0" ) )
    expect( bootstrap.get_ip4_by_inaddr( "192.in-addr.arpa") ).to eq( IPAddr.new( "192.0.0.0" ) )
  end

  it 'should get ip6 from inaddr' do
    dir = File.join( @work_dir, "test_find_ip6_from_inaddr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.get_ip6_by_inaddr( "b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.") ).to eq( IPAddr.new( "2001:db8::567:89ab" ) )
    expect( bootstrap.get_ip6_by_inaddr( "8.b.d.0.1.0.0.2.ip6.arpa.") ).to eq( IPAddr.new( "2001:db8::0" ) )
  end

  it 'should find url by domain' do
    dir = File.join( @work_dir, "test_find_url_by_domain" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_domain( "0.0.4.0.1.0.0.2.ip6.arpa.") ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_domain( "192.in-addr.arpa") ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_domain( "www.exmaple.cz") ).to eq( CZ_URL )
    expect( bootstrap.find_url_by_domain( "www.exmaple.museuum") ).to eq( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ] )
  end

  it 'should find url by forward domain' do
    dir = File.join( @work_dir, "test_find_url_by_forward_domain" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_forward_domain( "www.exmaple.cz") ).to eq( CZ_URL )
    expect( bootstrap.find_url_by_forward_domain( "www.exmaple.museuum") ).to eq( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ] )
  end

  it 'should find url by entity' do
    dir = File.join( @work_dir, "test_find_url_by_entity" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    expect( bootstrap.find_url_by_entity( "XXX-ARIN") ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_entity( "xxx-arin") ).to eq( ARIN_URL )
    expect( bootstrap.find_url_by_entity( "xxx-afrinic") ).to eq( AFRINIC_URL )
    expect( bootstrap.find_url_by_entity( "xxx-ap") ).to eq( APNIC_URL )
    expect( bootstrap.find_url_by_entity( "xxx-lacnic") ).to eq( LACNIC_URL )
    expect( bootstrap.find_url_by_entity( "xxx-ripe") ).to eq( RIPE_URL )
    expect( bootstrap.find_url_by_entity( "xxx-museum") ).to eq( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ] )
  end
end
