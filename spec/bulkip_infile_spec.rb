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

require 'spec_helper'
require 'rspec'
require 'pp'
require_relative '../lib/nicinfo/bulkip_infile'

describe 'bulk_infile test' do

  it 'should guess lines' do
    b = NicInfo::BulkIPInFile.new( nil )

    column, strip_column = b.guess_line( "127.0.0.1" )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

    s = "2018-02-03 00:00:00,336 DEBUG rws[0:0:0:0:0:0:0:1] => [http://localhost:8080/whoisrws/seam/resource/rest/nets;q=153.92.0.2?showDetails=true&showARIN=false&showNonArinTopLevelNet=false&ext=netref2]"
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 3 )
    expect( strip_column ).to be_truthy

    s = "2018-02-03 00:00:00,529 DEBUG whois 101.127.230.241 => [n = + 66.249.95.255]"
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 4 )
    expect( strip_column ).to be_falsey

    s = "2018-02-03 00:00:00,723 DEBUG whois 2a01:7e00:0:0:f03c:91ff:fec8:5dd9 => [n 83.233.57.115]"
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 4 )
    expect( strip_column ).to be_falsey

    s = '108.45.120.114 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/172.217.8.3 HTTP/1.1" 200 5383 "-" "Python-urllib/3.5"'
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

    s = '2001:500:31::7 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/entity/ARIN HTTP/1.1" 200 4261 "-" "-"'
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

    s = '67.109.163.226 - - [03/Feb/2018:05:31:26 -0500] "GET /registry/ip/fe80::988c:94ff:a381:2ba7 HTTP/1.1" 404 574 "-" "NicInfo v.1.1.1"'
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

    s = '2001:4898:80e8:a::342 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/org/RIPE HTTP/1.1" 200 1418 "-" "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.16299.98"'
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

    s = '112.64.210.132 - - [03/Feb/2018:05:31:57 -0500] "GET /rest/nets;q=37.175.146.1?showDetails=true&showARIN=true HTTP/1.1" 200 2112 "-" "Python-urllib/2.7"'
    column, strip_column = b.guess_line( s )
    expect( column ).to eq( 0 )
    expect( strip_column ).to be_falsey

  end

end
