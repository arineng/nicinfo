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
require 'data_tree'

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

  class Org
    attr_accessor :type, :names
    def initialize
      @type = Array.new
      @names = Array.new
    end
  end

  class Adr
    attr_accessor :structured, :label, :type
    attr_accessor :pobox, :extended, :street, :locality, :region, :postal, :country
    def initialize
      @structured = false
      @label = Array.new
      @type = Array.new
    end
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

    attr_accessor :fns, :phones, :emails, :adrs, :kind, :titles, :roles, :orgs

    def initialize
      @fns = Array.new
      @phones = Array.new
      @emails = Array.new
      @adrs = Array.new
      @titles = Array.new
      @roles = Array.new
      @orgs = Array.new
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
          if element[ 0 ] == "adr"
            adr = Adr.new
            if (type = element[ 1 ][ "type" ]) != nil
              adr.type << type if type.instance_of? String
              adr.type = type if type.instance_of? Array
            end
            if (label = element[ 1 ][ "label" ]) != nil
              adr.label = label.split( "\n" )
            else
              adr.pobox=element[ 3 ][ 0 ]
              adr.extended=element[ 3 ][ 1 ]
              adr.street=element[ 3 ][ 2 ]
              adr.locality=element[ 3 ][ 3 ]
              adr.region=element[ 3 ][ 4 ]
              adr.postal=element[ 3 ][ 5 ]
              adr.country=element[ 3 ][ 6 ]
              adr.structured=true
            end
            @adrs << adr
          end
          if element[ 0 ] == "kind"
            @kind = element[ 3 ]
          end
          if element[ 0 ] == "title"
            @titles << element[ 3 ]
          end
          if element[ 0 ] == "role"
            @roles << element[ 3 ]
          end
          if element[ 0 ] == "org"
            org = Org.new
            if (type = element[ 1 ][ "type" ]) != nil
              org.type << type if type.instance_of? String
              org.type = type if type.instance_of? Array
            end
            names = element[ 3 ]
            org.names << names if names.instance_of? String
            org.names = org.names + names if names.instance_of? Array
            @orgs << org
          end
        end
      end
      return self
    end

  end

  class EventActor
    attr_accessor :eventAction, :eventDate
  end

  # deals with RDAP entity structures
  class Entity

    attr_accessor :asEvents, :selfhref

    def initialize config
      @config = config
      @jcard = JCard.new
      @common = CommonJson.new config
      @entity = nil
      @asEvents = Array.new
      @selfhref = nil
    end

    def process json_data
      @objectclass = json_data
      @jcard.process json_data
      events = @objectclass[ "asEventActor" ]
      events.each do |event|
        eventActor = EventActor.new
        eventActor.eventAction=event[ "eventAction" ]
        eventActor.eventDate=event[ "eventDate" ]
        @asEvents << eventActor
      end if events
      @selfhref = NicInfo::get_self_link( NicInfo::get_links( @objectclass ) )
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.data_title "[ ENTITY ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass )
      @jcard.fns.each do |fn|
        @config.logger.terse "Name", fn
      end
      @jcard.orgs.each do |org|
        item_value = org.names.join( ", " )
        if !org.type.empty?
          item_value << " ( #{org.type.join( ", " )} )"
        end
        @config.logger.terse "Organization", item_value
      end
      @jcard.titles.each do |title|
        @config.logger.extra "Title", title
      end
      @jcard.roles.each do |role|
        @config.logger.extra "Organizational Role", role
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
      @common.display_string_array "roles", "Roles", @objectclass, DataAmount::TERSE_DATA
      @common.display_status @objectclass
      @common.display_port43 @objectclass
      @common.display_events @objectclass
      @jcard.adrs.each do |adr|
        if adr.type.empty?
          @config.logger.extra "Address", "-- for #{get_cn} --"
        else
          @config.logger.extra "Address", "( #{adr.type.join( ", " )} )"
        end
        if adr.structured
          @config.logger.extra "P.O. Box", adr.pobox
          @config.logger.extra "Apt/Suite", adr.extended
          @config.logger.extra "Street", adr.street
          @config.logger.extra "City", adr.locality
          @config.logger.extra "Region", adr.region
          @config.logger.extra "Postal Code", adr.postal
          @config.logger.extra "Country", adr.country
        else
          i = 1
          adr.label.each do |line|
            @config.logger.extra i.to_s, line
            i = i + 1
          end
        end
      end
      @config.logger.extra "Kind", @jcard.kind
      @common.display_remarks @objectclass
      @common.display_links( get_cn, @objectclass )
      @config.logger.end_data_item
    end

    def get_cn
      handle = NicInfo::get_handle @objectclass
      handle = "(unidentifiable entity #{object_id})" if !handle
      if !@jcard.fns.empty?
        return "#{@jcard.fns[ 0 ] } ( #{handle} )"
      end
      return handle
    end

    def to_node
      DataNode.new( get_cn, nil, @selfhref )
    end

  end

end