# Copyright (C) 2017 American Registry for Internet Numbers
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

module NicInfo

  # Creates objects we want to mock
  class Factory

    attr_accessor :appctx

    def initialize( appctx )
      @appctx = appctx
    end

    def new_error_code
      return ErrorCode.new( appctx )
    end

    def new_autnum
      return Autnum.new( appctx )
    end

    def new_domain
      return Domain.new( appctx )
    end

    def new_entity
      return Entity.new( appctx )
    end

    def new_ip
      return Ip.new( appctx )
    end

    def new_notices
      return Notices.new( appctx )
    end

    def new_ns
      return Ns.new( appctx )
    end

  end

end
