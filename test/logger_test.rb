# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
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


require 'test/unit'
require 'arinr_logger'
require 'stringio'

# Tests the logger
class LoggerTest < Test::Unit::TestCase

  def test_unknown_data_amount
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::FOO
    assert_raise( ArgumentError ) { logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }
  end

  def test_fake_data_amount
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = "FAKE"
    assert_raise( ArgumentError ) { logger.terse( "Network Handle", "NET-192-136-136-0-1" ) }
  end

  def test_log_extra_at_default
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_normal
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::NORMAL_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_terse
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::TERSE_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_extra_at_extra
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::EXTRA_DATA
    logger.extra( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_default
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_normal
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::NORMAL_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_terse
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::TERSE_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_terse_at_extra
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::EXTRA_DATA
    logger.terse( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_default
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_normal
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_normal_at_terse
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::TERSE_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "", logger.data_out.string )
  end

  def test_log_normal_at_extra
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::EXTRA_DATA
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_unknown_message_level
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::NO_SUCH_LEVEL
    assert_raise( ArgumentError ) { logger.mesg( "Network Handle" ) }
  end

  def test_fake_message_level
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = "FAKE"
    assert_raise( ArgumentError ) { logger.mesg( "Network Handle" ) }
  end

  def test_log_some_at_default
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_some
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::SOME_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_trace
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::ALL_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
  end

  def test_log_some_at_none
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::NO_MESSAGES
    logger.mesg( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_default
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_some
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::SOME_MESSAGES
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_log_trace_at_trace
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::ALL_MESSAGES
    logger.trace( "blah" )
    assert_equal( "## blah\n", logger.message_out.string )
  end

  def test_log_trace_at_none
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINcli::MessageLevel::NO_MESSAGES
    logger.trace( "blah" )
    assert_equal( "", logger.message_out.string )
  end

  def test_messages_and_data
    logger = ARINcli::Logger.new
    logger.message_out = StringIO.new
    logger.data_out = logger.message_out
    logger.mesg( "blah" )
    assert_equal( "# blah\n", logger.message_out.string )
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "# blah\n           Network Handle:  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_messages_vs_data
    logger = ARINcli::Logger.new
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
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::NORMAL_DATA
    logger.item_name_rjust = false
    logger.datum( "Network Handle", "NET-192-136-136-0-1" )
    assert_equal( "Network Handle           :  NET-192-136-136-0-1\n", logger.data_out.string )
  end

  def test_log_empty_datum
    logger = ARINcli::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINcli::DataAmount::NORMAL_DATA
    logger.datum( "Network Handle", "" )
    assert_equal( "", logger.data_out.string )
  end

end

