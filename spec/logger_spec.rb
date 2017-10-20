# Copyright (C) 2011,2012,2013,2014 American Registry for Internet Numbers
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


require 'stringio'
require 'spec_helper'
require 'rspec'
require_relative '../lib/nicinfo/nicinfo_logger'

# Tests the logger
describe 'logger tests' do

  it 'tests unknown data amount' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::FOO
    expect{ logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }.to raise_error( ArgumentError )
  end

  it 'tests fake data amount' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = "FAKE"
    expect{  logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }.to raise_error( ArgumentError )
  end

  it 'tests log extra at default' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "" )
  end

  it 'should log extra at normal' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "" )
  end

  it 'should log extra at terse' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "" )
  end

  it 'should log extra at extra' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log terse at default' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log terse at normal' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log terse at terse' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log terse at extra' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log normal at default' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log normal at normal' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should log normal at terse' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "" )
  end

  it 'should log normal at extra' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should error for an unknown message level' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_SUCH_LEVEL
    expect{ logger.mesg( "Network Handle" ) }.to raise_error( ArgumentError )
  end

  it 'should error at a fake message level' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = "FAKE"
    expect{ logger.mesg( "Network Handle" ) }.to raise_error( ArgumentError )
  end

  it 'should log some at default' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.mesg( "blah" )
    expect( logger.message_out.string ).to eq( "# blah\n" )
  end

  it 'should log some at some level' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::SOME_MESSAGES
    logger.mesg( "blah" )
    expect( logger.message_out.string ).to eq( "# blah\n" )
  end

  it 'should log some at trace' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.mesg( "blah" )
    expect( logger.message_out.string ).to eq( "# blah\n" )
  end

  it 'should log some at none' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    logger.mesg( "blah" )
    expect( logger.message_out.string ).to eq( "" )
  end

  it 'should log trace at default' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.trace( "blah" )
    expect( logger.message_out.string ).to eq( "" )
  end

  it 'should log trace at some' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::SOME_MESSAGES
    logger.trace( "blah" )
    expect( logger.message_out.string ).to eq( "" )
  end

  it 'should log trace at trace' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.trace( "blah" )
    expect( logger.message_out.string ).to eq( "## blah\n" )
  end

  it 'should log trace at non' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    logger.trace( "blah" )
    expect( logger.message_out.string ).to eq( "" )
  end

  it 'should log messages and data' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.data_out = logger.message_out
    logger.mesg( "blah" )
    expect( logger.message_out.string ).to eq( "# blah\n" )
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "# blah\n           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should test messages vs data' do
    logger = NicInfo::Logger.new
    messages = StringIO.new
    logger.message_out = messages
    data = StringIO.new
    logger.data_out = data
    logger.mesg( "blah" )
    expect( messages.string ).to eq( "# blah\n" )
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( data.string ).to eq( "           Network Handle:  NET-192-136-136-0-1\n" )
  end

  it 'should ljust item name' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.item_name_rjust = false
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    expect( logger.data_out.string ).to eq( "Network Handle           :  NET-192-136-136-0-1\n" )
  end

  it 'should log empty datum' do
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "" )
    expect( logger.data_out.string ).to eq( "" )
  end

  it 'should log terminal columns' do

    text1 = <<TEXT1
speed 38400 baud;
rows = 60; columns = 157; ypixels = 0; xpixels = 0;
csdata ?
eucw 1:0:0:0, scrw 1:0:0:0
intr = ^c; quit = ^\; erase = ^?; kill = ^u;
eof = ^d; eol = ; eol2 = ; swtch = ;
start = ^q; stop = ^s; susp = ^z; dsusp = ^y;
rprnt = ^r; flush = ^o; werase = ^w; lnext = ^v;
-parenb -parodd cs8 -cstopb -hupcl cread -clocal -loblk -crtscts -crtsxoff -parext
-ignbrk brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr icrnl -iuclc
ixon -ixany -ixoff imaxbel
isig icanon -xcase echo echoe echok -echonl -noflsh
-tostop echoctl -echoprt echoke -defecho -flusho -pendin iexten
opost -olcuc onlcr -ocrnl -onocr -onlret -ofill -ofdel tab3
TEXT1

    text2 = <<TEXT2
speed 9600 baud; 40 rows; 110 columns;
lflags: icanon isig iexten echo echoe -echok echoke -echonl echoctl
-echoprt -altwerase -noflsh -tostop -flusho pendin -nokerninfo
-extproc
iflags: -istrip icrnl -inlcr -igncr ixon -ixoff ixany imaxbel iutf8
-ignbrk brkint -inpck -ignpar -parmrk
oflags: opost onlcr -oxtabs -onocr -onlret
cflags: cread cs8 -parenb -parodd hupcl -clocal -cstopb -crtscts -dsrflow
-dtrflow -mdmbuf
cchars: discard = ^O; dsusp = ^Y; eof = ^D; eol = <undef>;
eol2 = <undef>; erase = ^?; intr = ^C; kill = ^U; lnext = ^V;
min = 1; quit = ^\; reprint = ^R; start = ^Q; status = ^T;
stop = ^S; susp = ^Z; time = 0; werase = ^W;
TEXT2

    text3 = <<TEXT3
speed 38400 baud; rows 48; columns 135; line = 0;
intr = ^C; quit = ^\; erase = ^?; kill = ^U; eof = ^D; eol = M-^?; eol2 = M-^?; swtch = M-^?; start = ^Q; stop = ^S; susp = ^Z;
rprnt = ^R; werase = ^W; lnext = ^V; flush = ^O; min = 1; time = 0;
-parenb -parodd cs8 hupcl -cstopb cread -clocal -crtscts
-ignbrk brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr icrnl ixon -ixoff -iuclc ixany imaxbel iutf8
opost -olcuc -ocrnl onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
isig icanon iexten echo echoe echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke
TEXT3

    logger = NicInfo::Logger.new

    expect( logger.get_terminal_columns( text1, 80 ) ).to eq( 157 )
    expect( logger.get_terminal_columns( text2, 80 ) ).to eq( 110 )
    expect( logger.get_terminal_columns( text3, 80 ) ).to eq( 135 )
    expect( logger.get_terminal_columns( "blah", 80 ) ).to eq( 80 )
  end

  it 'should break up line' do
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES

    line = "this is a test of the emergency broadcast system"
    lines = logger.break_up_line( line, 20 )
    expect( lines.length ).to eq( 3 )
    line = "0123456789012345678 0123456789012345678 01234567 0123 0123"
    lines = logger.break_up_line( line, 20 )
    expect( lines.length ).to eq( 3 )
    line = "0123456789012345678012345678901234567801234567 0123 0123"
    lines = logger.break_up_line( line, 20 )
    expect( lines.length ).to eq( 2 )
    line = "012345678901234567801234567890123456780123456701230123"
    lines = logger.break_up_line( line, 20 )
    expect( lines.length ).to eq( 1 )
    line = "0123 012345678901234567801234567890123456780123456701230123"
    lines = logger.break_up_line( line, 20 )
    expect( lines.length ).to eq( 2 )

  end

end

