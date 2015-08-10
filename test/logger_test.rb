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


require 'minitest/autorun'
require 'nicinfo/nicinfo_logger'
require 'stringio'

# Tests the logger
class LoggerTest < Minitest::Test

  def test_unknown_data_amount
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::FOO
    assert_raises( ArgumentError ) { logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }
  end

  def test_fake_data_amount
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = "FAKE"
    assert_raises( ArgumentError ) { logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }
  end

  def test_log_extra_at_default
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_normal
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_terse
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_extra
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_default
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_normal
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_terse
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_extra
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_default
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_normal
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_terse
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::TERSE_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_normal_at_extra
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_unknown_message_level
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_SUCH_LEVEL
    assert_raises( ArgumentError ) { logger.mesg( "Network Handle" ) }
  end

  def test_fake_message_level
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = "FAKE"
    assert_raises( ArgumentError ) { logger.mesg( "Network Handle" ) }
  end

  def test_log_some_at_default
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_some
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::SOME_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_trace
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_none
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_default
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_some
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::SOME_MESSAGES
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_trace
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
    logger.trace( "blah" )
    assert_equal( "## blah\n", logger.message_out.string )
  end

  def test_log_trace_at_none
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_messages_and_data
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.data_out = logger.message_out
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "# blah\n           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_messages_vs_data
    logger = NicInfo::Logger.new
    messages = StringIO.new
    logger.message_out = messages
    data = StringIO.new
    logger.data_out = data
    logger.mesg( "blah" )
    assert_equal( "# blah\n", messages.string )
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", data.string )
  end

  def test_log_ljust_item_name
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.item_name_rjust = false
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "Network Handle           :  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_empty_datum
    logger = NicInfo::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = NicInfo::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "" )
    assert_equal( "", logger.data_out.string )
  end

  def test_get_terminal_columns

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

    assert_equal( 157, logger.get_terminal_columns( text1, 80 ))
    assert_equal( 110, logger.get_terminal_columns( text2, 80 ))
    assert_equal( 135, logger.get_terminal_columns( text3, 80 ))
    assert_equal( 80, logger.get_terminal_columns( "blah", 80 ))
  end

  def test_break_up_line
    logger = NicInfo::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = NicInfo::MessageLevel::NO_MESSAGES

    line = "this is a test of the emergency broadcast system"
    lines = logger.break_up_line( line, 20 )
    assert_equal( 3, lines.length )
    line = "0123456789012345678 0123456789012345678 01234567 0123 0123"
    lines = logger.break_up_line( line, 20 )
    assert_equal( 3, lines.length )
    line = "0123456789012345678012345678901234567801234567 0123 0123"
    lines = logger.break_up_line( line, 20 )
    assert_equal( 2, lines.length )
    line = "012345678901234567801234567890123456780123456701230123"
    lines = logger.break_up_line( line, 20 )
    assert_equal( 1, lines.length )
    line = "0123 012345678901234567801234567890123456780123456701230123"
    lines = logger.break_up_line( line, 20 )
    assert_equal( 2, lines.length )

  end

end

