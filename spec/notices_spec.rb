# Copyright (C) 2011-2017 American Registry for Internet Numbers
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
require_relative '../lib/nicinfo/notices'
begin
  require 'json'
rescue LoadError
  require 'rubygems'
  require 'json'
end

describe 'notices tests' do

  before( :all) do

    @non_excessive = <<NONEXCESSIVE
{
    "rdapConformance":[
        "rdap_level_0"
    ],
    "notices":[
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        }
    ],
    "lang":"en",
    "startAddress":"192.0.2.0",
    "endAddress":"192.0.2.255",
    "remarks":[
        {
            "description":[
                "She sells sea shells down by the sea shore.",
                "Originally written by Terry Sullivan."
            ]
        }
    ]
}
NONEXCESSIVE

    @excessive1 = <<EXCESSIVE1
{
    "rdapConformance":[
        "rdap_level_0"
    ],
    "notices":[
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        },
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        },
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        },
        {
            "title":"Content Redacted",
            "description":[
                "Without full authorization, content has been redacted.",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        }
    ],
    "lang":"en",
    "startAddress":"192.0.2.0",
    "endAddress":"192.0.2.255",
    "remarks":[
        {
            "description":[
                "She sells sea shells down by the sea shore.",
                "Originally written by Terry Sullivan."
            ]
        }
    ]
}
EXCESSIVE1

    @excessive2 = <<EXCESSIVE2
{
    "rdapConformance":[
        "rdap_level_0"
    ],
    "notices":[
        {
            "title":"Content Redacted",
            "description":[
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "1234567890123456789012345678901234567890123456789012345678901234567890",
                "Sorry, dude!"
            ],
            "links":[
                {
                    "value":"http://example.net/ip/192.0.2.0/24",
                    "rel":"alternate",
                    "type":"text/html",
                    "href":"http://www.example.com/redaction_policy.html"
                }
            ]
        }
    ],
    "lang":"en",
    "startAddress":"192.0.2.0",
    "endAddress":"192.0.2.255",
    "remarks":[
        {
            "description":[
                "She sells sea shells down by the sea shore.",
                "Originally written by Terry Sullivan."
            ]
        }
    ]
}
EXCESSIVE2

  end

  it 'should test differenct versions of notice' do
    notices = NicInfo::Notices.new( nil )
    expect( notices.is_excessive_notice( JSON.load( @non_excessive )[ "notices" ] ) ).to be_falsey
    expect( notices.is_excessive_notice( JSON.load( @excessive1 )[ "notices" ] ) ).to be_truthy
    expect( notices.is_excessive_notice( JSON.load( @excessive2 )[ "notices" ] ) ).to be_truthy
  end

end
