# Copyright (C) 2013 American Registry for Internet Numbers
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
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ], bootstrap.find_rir_url_by_ip( "128.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::APNIC_URL ], bootstrap.find_rir_url_by_ip( "133.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::RIPE_URL ], bootstrap.find_rir_url_by_ip( "151.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::LACNIC_URL ], bootstrap.find_rir_url_by_ip( "191.0.0.1" ) )
    assert_equal( c.config[ NicInfo::BOOTSTRAP ][ NicInfo::AFRINIC_URL ], bootstrap.find_rir_url_by_ip( "196.0.0.1" ) )
  end
end