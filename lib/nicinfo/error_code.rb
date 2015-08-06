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

require 'nicinfo/config'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'

module NicInfo

  # deals with RDAP error code structures
  class ErrorCode

    def display_error_code ec, config
      config.logger.start_data_item
      title = ec[ "title" ]
      if title == nil
        title = ""
      end
      config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "[ ERROR ]", title
      config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "Code", ec[ "errorCode" ]
      description = ec[ "description" ]
      i = 1
      description.each do |line|
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, i.to_s, line
        i = i + 1
      end
      links = ec[ "links" ]
      if links
        alternate = NicInfo.get_alternate_link links
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "More", alternate if alternate
        about = NicInfo.get_about_link links
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "About", about if about
        tos = NicInfo.get_tos_link links
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "TOS", tos if tos
        copyright = NicInfo.get_copyright_link links
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "(C)", copyright if copyright
        license = NicInfo.get_license_link links
        config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "License", license if license
      end
      config.logger.end_data_item
    end

  end

end
