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
require_relative '../lib/nicinfo/common_names'

describe 'common names test' do

  it 'should test last names' do

    expect( NicInfo::is_last_name( "JOHNSON") ).to be_truthy
    expect( NicInfo::is_last_name( "NEWTON") ).to be_truthy
    expect( NicInfo::is_last_name( "KOSTERS") ).to be_truthy
    expect( NicInfo::is_last_name( "AALDERINK") ).to be_truthy
    expect( NicInfo::is_last_name( "..........") ).to be_falsey

  end

  it 'should test male names' do

    expect( NicInfo::is_male_name( "JOHN" ) ).to be_truthy
    expect( NicInfo::is_male_name( "JAMES" ) ).to be_truthy
    expect( NicInfo::is_male_name( "ANDREW" ) ).to be_truthy
    expect( NicInfo::is_male_name( "MARK" ) ).to be_truthy
    expect( NicInfo::is_male_name( ".........." ) ).to be_falsey

  end

  it 'should test female names' do

    expect( NicInfo::is_female_name( "LINDA" ) ).to be_truthy
    expect( NicInfo::is_female_name( "MARY" ) ).to be_truthy
    expect( NicInfo::is_female_name( "GAIL" ) ).to be_truthy
    expect( NicInfo::is_female_name( "ALLYN" ) ).to be_truthy
    expect( NicInfo::is_female_name( "........" ) ).to be_falsey

  end

end
