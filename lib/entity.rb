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

require 'config'
require 'nicinfo_logger'
require 'utils'
require 'common_json'

module NicInfo

  def NicInfo.display_entity json_data, config
    Entity.new( config ).process( json_data ).display
  end

  def NicInfo.display_entities json_data, config
    entities = NicInfo::get_entitites json_data
    entities.each do |json_entity|
      NicInfo::display_entity( json_entity, config )
    end if entities
  end

  class Email
    attr_accessor :type, :addr
    def initialize
      @type = Array.new
    end
  end

  class Tel
    attr_accessor :type, :number, :ext
    def initialize
      @type = Array.new
    end
  end

  class JCard

    attr_accessor :fns, :phones, :emails

    def initialize
      @fns = Array.new
      @phones = Array.new
      @emails = Array.new
    end

    def get_vcard entity
      return entity[ "vcardArray" ]
    end

    def process entity
      if ( vcard = get_vcard( entity ) ) != nil
        vcardElements = vcard[ 1 ]
        vcardElements.each do |element|
          if element[ 0 ] == "fn"
            @fns << element[ 3 ]
          end
          if element[ 0 ] == "tel"
            tel = Tel.new
            if (type = element[ 1 ][ "type" ]) != nil
              tel.type << type if type.instance_of? String
              tel.type = type if type.instance_of? Array
            end
            if (str = element[ 3 ] ).start_with?( "tel:" )
              tel.number=str[ /^tel\:([^;]*)/,1 ]
              tel.ext=str[ /[^;]*ext=(.*)/,1 ]
            else
              tel.number=str
            end
            @phones << tel
          end
          if element[ 0 ] == "email"
            email = Email.new
            if (type = element[ 1 ][ "type" ]) != nil
              email.type << type if type.instance_of? String
              email.type = type if type.instance_of? Array
            end
            email.addr=element[ 3 ]
            @emails << email
          end
        end
      end
      return self
    end

  end

  # deals with RDAP entity structures
  class Entity

    def initialize config
      @config = config
      @jcard = JCard.new
      @common = CommonJson.new config
      @entity = nil
    end

    def process json_data
      @objectclass = json_data
      @jcard.process json_data
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass )
      @jcard.fns.each do |fn|
        @config.logger.terse "Name", fn
      end
      @jcard.emails.each do |email|
        item_value = email.addr
        if !email.type.empty?
          item_value << " ( #{email.type.join( ", " )} )"
        end
        @config.logger.terse "Email", item_value
      end
      @jcard.phones.each do |phone|
        item_value = phone.number
        if phone.ext
          item_value << " Ext. #{phone.ext}"
        end
        if !phone.type.empty?
          item_value << " ( #{phone.type.join( ", " )} )"
        end
        @config.logger.terse "Phone", item_value
      end
      @common.display_string_array DataAmount::TERSE_DATA, "roles", "Roles", @objectclass
      @common.display_status @objectclass
      @common.display_remarks @objectclass
      @common.display_port43 @objectclass
      @common.display_links( get_cn, @objectclass )
      @common.display_events @objectclass
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      if !@jcard.fns.empty?
        return "#{@jcard.fns[ 0 ] } ( #{handle} )"
      end
      return handle if handle
      return "(unidentifiable entity)"
    end

  end

end