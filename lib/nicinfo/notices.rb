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

require 'nicinfo/config'
require 'nicinfo/nicinfo_logger'
require 'nicinfo/utils'
require 'nicinfo/common_json'

module NicInfo

  # deals with RDAP notices structures
  class Notices

    attr_accessor :config

    def initialize( config )
      @config = config
      @common = CommonJson.new( config )
    end

    def is_excessive_notice notices
      return false if !notices
      return false if notices.length == 0
      return true if notices.length > 2
      word_count = 0
      line_count = 0
      notices.each do |notice|
        descriptions = NicInfo::get_descriptions notice, @config
        descriptions.each do |line|
          line_count = line_count + 1
          word_count = word_count + line.length
        end if descriptions and descriptions.instance_of? Array
      end
      return true if line_count > 10
      return true if word_count > 700
      #otherwise
      return false
    end

    def display_notices json_response, ignore_excessive

      notices = json_response[ "notices" ]
      return if notices == nil
      if (is_excessive_notice(notices) ) && (@config.logger.data_amount != NicInfo::DataAmount::EXTRA_DATA) && !ignore_excessive
        @config.logger.start_data_item
        @config.logger.raw NicInfo::DataAmount::NORMAL_DATA, "Excessive Notices", NicInfo::AttentionType::INFO
        @config.logger.raw NicInfo::DataAmount::NORMAL_DATA, "-----------------", NicInfo::AttentionType::INFO
        @config.logger.raw NicInfo::DataAmount::NORMAL_DATA, "Response contains excessive notices.", NicInfo::AttentionType::INFO
        @config.logger.raw NicInfo::DataAmount::NORMAL_DATA, "Use the \"-V\" or \"--data extra\" options to see them.", NicInfo::AttentionType::INFO
        @config.logger.end_data_item
      else
        notices.each do |notice|
          display_single_notice notice
        end
      end

    end

    def display_single_notice notice
      @config.logger.start_data_item
      title = notice[ "title" ]
      if title == nil
        title = ""
      end
      @config.conf_msgs << "'title' in 'notice' is not a string." unless title.instance_of?( String )
      @config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "[ NOTICE ]", title, NicInfo::AttentionType::SECONDARY
      type = notice[ "type" ]
      if type != nil
        @config.logger.prose NicInfo::DataAmount::NORMAL_DATA, "Type", NicInfo.capitalize( type ), NicInfo::AttentionType::SECONDARY
      end
      description = notice[ "description" ]
      i = 1
      if description.instance_of?( Array )
        description.each do |line|
          if line.instance_of?( String )
            @config.logger.prose NicInfo::DataAmount::NORMAL_DATA, i.to_s, line, NicInfo::AttentionType::SECONDARY
            i = i + 1
          else
            @config.conf_msgs << "eleemnt of 'description' in 'notice' is not a string."
          end
        end
      else
        @config.conf_msgs << "'description' in 'notice' is not an array."
      end
      links = notice[ "links" ]
      @common.display_simple_links( links )
      @config.logger.end_data_item
    end

  end

end
