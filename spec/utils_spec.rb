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
require_relative '../lib/nicinfo/utils'

describe 'tests for utility methods' do

  it 'should capitalize' do
    expect( NicInfo::capitalize( "my myself & i" ) ).to eq( "My Myself & I" )
    expect( NicInfo::capitalize( "me" ) ).to eq( "Me" )
  end

  it 'should know about non-global unicast address' do
    expect( NicInfo.is_global_unicast?( IPAddr.new( "::1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "0:0:0:0:0:0:0:1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "224.0.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "255.0.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "10.0.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "192.168.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "172.16.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "127.16.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "127.0.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "169.254.0.1" ) ) ).to be_falsey
    expect( NicInfo.is_global_unicast?( IPAddr.new( "fe80::67c9:f0ec:bac4:8e55" ) ) ).to be_falsey

    expect( NicInfo.is_global_unicast?( IPAddr.new( "139.226.146.173" ) ) ).to be_truthy
    expect( NicInfo.is_global_unicast?( IPAddr.new( "2a02:d8:0:0:250:56ff:fe95:ca7e" ) ) ).to be_truthy
    expect( NicInfo.is_global_unicast?( IPAddr.new( "2001:41d0:2:193d:0:0:0:5" ) ) ).to be_truthy
    expect( NicInfo.is_global_unicast?( IPAddr.new( "194.85.61.205" ) ) ).to be_truthy
  end
end
