# Copyright (C) 2013,2014 American Registry for Internet Numbers
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

require "test/unit"
require 'bootstrap'
require 'constants'

class BootStrapTest < Test::Unit::TestCase

  ARIN_URL = "https://rdappilot.arin.net/restfulwhois/rdap"
  APNIC_URL = "https://rdap.apnic.net"
  LACNIC_URL = "https://rdap.lacnic.net/rdap"
  AFRINIC_URL = "https://rdap.rd.me.afrinic.net/whois/AFRINIC"
  RIPE_URL = "https://rdap.db.ripe.net"

  @work_dir = nil

  def setup
    @work_dir = Dir.mktmpdir
  end

  def test_find_v6_addr
    dir = File.join( @work_dir, "test_find_v6_addr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( "IANA", bootstrap.find_rir_by_ip( "2001:0000::1") )
    assert_equal( "ARIN", bootstrap.find_rir_by_ip( "2001:0400::/23" ) )
    assert_equal( "APNIC", bootstrap.find_rir_by_ip( "2001:0200::/23" ) )
    assert_equal( "RIPE NCC", bootstrap.find_rir_by_ip( "2001:0600::/23" ) )
    assert_equal( "LACNIC", bootstrap.find_rir_by_ip( "2001:1200::/23" ) )
    assert_equal( "AFRINIC", bootstrap.find_rir_by_ip( "2001:4200::/23" ) )
  end

  def test_find_v6_url
    dir = File.join( @work_dir, "test_find_v6_url" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ], bootstrap.find_rir_url_by_ip( "2001:0000::1") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_rir_url_by_ip( "2001:0400::/23" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::APNIC_URL ], bootstrap.find_rir_url_by_ip( "2001:0200::/23" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_rir_url_by_ip( "2001:0600::/23" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::LACNIC_URL ], bootstrap.find_rir_url_by_ip( "2001:1200::/23" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AFRINIC_URL ], bootstrap.find_rir_url_by_ip( "2001:4200::/23" ) )
  end

  def test_find_v4_addr
    dir = File.join( @work_dir, "test_find_v4_addr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( "ARIN", bootstrap.find_rir_by_ip( "216.0.0.1" ) )
    assert_equal( "APNIC", bootstrap.find_rir_by_ip( "218.0.0.1" ) )
    assert_equal( "RIPE NCC", bootstrap.find_rir_by_ip( "212.0.0.1" ) )
    assert_equal( "LACNIC", bootstrap.find_rir_by_ip( "200.0.0.1" ) )
    assert_equal( "AFRINIC", bootstrap.find_rir_by_ip( "102.0.0.1" ) )
    assert_equal( "Administered by ARIN", bootstrap.find_rir_by_ip( "128.0.0.1" ) )
    assert_equal( "Administered by APNIC", bootstrap.find_rir_by_ip( "133.0.0.1" ) )
    assert_equal( "Administered by RIPE NCC", bootstrap.find_rir_by_ip( "151.0.0.1" ) )
    assert_equal( "Administered by LACNIC", bootstrap.find_rir_by_ip( "191.0.0.1" ) )
    assert_equal( "Administered by AFRINIC", bootstrap.find_rir_by_ip( "196.0.0.1" ) )
  end

  def test_find_v4_url
    dir = File.join( @work_dir, "test_find_v4_url" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_rir_url_by_ip( "216.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::APNIC_URL ], bootstrap.find_rir_url_by_ip( "218.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_rir_url_by_ip( "212.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::LACNIC_URL ], bootstrap.find_rir_url_by_ip( "200.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AFRINIC_URL ], bootstrap.find_rir_url_by_ip( "102.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_rir_url_by_ip( "128.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::APNIC_URL ], bootstrap.find_rir_url_by_ip( "133.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_rir_url_by_ip( "151.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::LACNIC_URL ], bootstrap.find_rir_url_by_ip( "191.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AFRINIC_URL ], bootstrap.find_rir_url_by_ip( "196.0.0.1" ) )
  end

=begin
  def test_find_rir_by_as
    dir = File.join( @work_dir, "test_find_v4_url" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( "Assigned by ARIN", bootstrap.find_rir_by_as( 26756 ) )
    assert_equal( "Assigned by ARIN", bootstrap.find_rir_by_as( 26755 ) )
    assert_equal( "Assigned by ARIN", bootstrap.find_rir_by_as( 27575 ) )
    assert_equal( "Assigned by APNIC", bootstrap.find_rir_by_as( 23552 ) )
    assert_equal( "Assigned by LACNIC", bootstrap.find_rir_by_as( 27648 ) )
    assert_equal( "Assigned by RIPE NCC", bootstrap.find_rir_by_as( 24735 ) )
    assert_equal( "Assigned by LACNIC", bootstrap.find_rir_by_as( 23541 ) )
    assert_equal( "Assigned by AFRINIC", bootstrap.find_rir_by_as( 23549 ) )
    assert_equal( "Assigned by ARIN", bootstrap.find_rir_by_as( 393216 ) )
  end
=end

  def test_find_url_by_as
    dir = File.join( @work_dir, "test_find_url_by_as" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( ARIN_URL, bootstrap.find_url_by_as( 26756 ) )
    assert_equal( ARIN_URL, bootstrap.find_url_by_as( 26755 ) )
    assert_equal( ARIN_URL, bootstrap.find_url_by_as( 27575 ) )
    assert_equal( APNIC_URL, bootstrap.find_url_by_as( 23552 ) )
    assert_equal( LACNIC_URL, bootstrap.find_url_by_as( 27648 ) )
    assert_equal( RIPE_URL, bootstrap.find_url_by_as( 24735 ) )
    assert_equal( LACNIC_URL, bootstrap.find_url_by_as( 23541 ) )
    assert_equal( AFRINIC_URL, bootstrap.find_url_by_as( 23549 ) )
    assert_equal( ARIN_URL, bootstrap.find_url_by_as( 393216 ) )
  end

  def test_get_ip4_from_inaddr
    dir = File.join( @work_dir, "test_find_ip4_from_inaddr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( IPAddr.new( "192.0.0.1" ), bootstrap.get_ip4_by_inaddr( "1.0.0.192.in-addr.arpa.") )
    assert_equal( IPAddr.new( "192.0.0.1" ), bootstrap.get_ip4_by_inaddr( "1.0.0.192.in-addr.arpa") )
    assert_equal( IPAddr.new( "192.0.0.0" ), bootstrap.get_ip4_by_inaddr( "0.0.192.in-addr.arpa") )
    assert_equal( IPAddr.new( "192.0.0.0" ), bootstrap.get_ip4_by_inaddr( "0.192.in-addr.arpa") )
    assert_equal( IPAddr.new( "192.0.0.0" ), bootstrap.get_ip4_by_inaddr( "192.in-addr.arpa") )
  end

  def test_get_ip6_from_inaddr
    dir = File.join( @work_dir, "test_find_ip6_from_inaddr" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( IPAddr.new( "2001:db8::567:89ab" ), bootstrap.get_ip6_by_inaddr( "b.a.9.8.7.6.5.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.") )
    assert_equal( IPAddr.new( "2001:db8::0" ), bootstrap.get_ip6_by_inaddr( "8.b.d.0.1.0.0.2.ip6.arpa.") )
  end

  def test_find_url_by_domain
    dir = File.join( @work_dir, "test_find_url_by_domain" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_url_by_domain( "0.0.4.0.1.0.0.2.ip6.arpa.") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_url_by_domain( "192.in-addr.arpa") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::COM_URL ], bootstrap.find_url_by_domain( "www.exmaple.com") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::COM_URL ], bootstrap.find_url_by_domain( "exmaple.com") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::BIZ_URL ], bootstrap.find_url_by_domain( "www.exmaple.biz") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ], bootstrap.find_url_by_domain( "www.exmaple.museuum") )
  end

  def test_find_url_by_entity_suffix
    dir = File.join( @work_dir, "test_find_url_by_entity_suffix" )
    c = NicInfo::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    bootstrap = NicInfo::Bootstrap.new c
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_url_by_entity_suffix( "XXX-ARIN") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::ARIN_URL ], bootstrap.find_url_by_entity_suffix( "xxx-arin") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AFRINIC_URL ], bootstrap.find_url_by_entity_suffix( "xxx-afrinic") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::APNIC_URL ], bootstrap.find_url_by_entity_suffix( "xxx-ap") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::LACNIC_URL ], bootstrap.find_url_by_entity_suffix( "xxx-lacnic") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_url_by_entity_suffix( "xxx-ripe") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_url_by_entity_suffix( "xxx-ripe") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::COM_URL ], bootstrap.find_url_by_entity_suffix( "xxx-com") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::BIZ_URL ], bootstrap.find_url_by_entity_suffix( "xxx-biz") )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ], bootstrap.find_url_by_entity_suffix( "xxx-museum") )
  end
end