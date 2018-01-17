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

require 'jcr'

module NicInfo

  def NicInfo.do_jcr( json_data, config, root_name )

    if config.options.jcr == JcrMode::STANDARD_VALIDATION
      config.logger.mesg( "Standard JSON Content Rules validation mode enabled.")
    elsif config.options.jcr == JcrMode::STRICT_VALIDATION
      config.logger.mesg( "Strict JSON Content Rules validation mode enabled.")
    else
      return
    end

    # Create a JCR context.
    ruleset = File.join( File.dirname( __FILE__ ), NicInfo::JCR_DIR, NicInfo::RDAP_JCR )
    ctx = JCR::Context.new( ruleset, false )

    if config.options.jcr == JcrMode::STRICT_VALIDATION
      strict = File.join( File.dirname( __FILE__ ), NicInfo::JCR_DIR, NicInfo::STRICT_RDAP_JCR )
      ctx.override!( strict, root_name )
    end

    e1 = ctx.evaluate( json_data )

    unless e1.success
      ctx.failure_report.each do |line|
        config.conf_msgs << line
      end
    end

  end

end
