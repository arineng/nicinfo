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
require 'time'
require 'entity'

module NicInfo

  def NicInfo.display_object_with_entities object, config, data_node
    if !object.entities.empty?
      root = object.to_node
      data_node.add_root( root )
      object.entities.each do |entity|
        root.add_child( entity.to_node )
      end
      data_node.to_normal_log( config.logger, true )
    end
    object.display
    object.entities.each do |entity|
      entity.display
    end
  end

  # deals with common JSON RDAP structures
  class CommonJson

    def initialize config
      @config = config
    end

    def process_entities objectclass
      entities = Array.new
      json_entities = NicInfo::get_entitites( objectclass )
      json_entities.each do |json_entity|
        entity = Entity.new( @config )
        entity.process( json_entity )
        entities << entity
      end if json_entities
      return entities
    end

    def display_remarks objectclass
      remarks = objectclass[ "remarks" ]
      if (Notices::is_excessive_notice remarks) && (@config.logger.data_amount != NicInfo::DataAmount::EXTRA_DATA)
        @config.logger.datum "Excessive Remarks", "Use \"-V\" or \"--data extra\" to see them."
      else
        remarks.each do |remark|
          title = remark[ "title" ]
          @config.logger.datum "Remarks", "-- #{title} --" if title
          descriptions = NicInfo::get_descriptions remark
          i = 1
          descriptions.each do |line|
            if !title && i == 1
              @config.logger.datum "Remarks", line
            elsif i != 1 || title
              @config.logger.datum i.to_s, line
            end
            i = i + 1
          end
          links = NicInfo::get_links remark
          if links
            @config.logger.datum "More", NicInfo::get_alternate_link( links )
            @config.logger.datum "About", NicInfo::get_about_link( links )
            @config.logger.datum "TOS", NicInfo::get_tos_link( links )
            @config.logger.datum "(C)", NicInfo::get_copyright_link( links )
            @config.logger.datum "License", NicInfo::get_license_link( links )
          end
        end if remarks
      end
    end

    def display_string_array json_name, display_name, json_data, data_amount
      arr = json_data[ json_name ]
      if arr
        new_arr = Array.new
        arr.each do |str|
          new_arr << NicInfo::capitalize( str )
        end
        @config.logger.info data_amount, display_name, new_arr.join( ", " )
      end
    end

    def display_status objectclass
      display_string_array "status", "Status", objectclass, DataAmount::NORMAL_DATA
    end

    def display_port43 objectclass
      @config.logger.extra "Port 43 Whois", objectclass[ "port43" ]
    end

    def display_links cn, objectclass
      links = NicInfo::get_links objectclass
      if links
        @config.logger.extra "Links", "-- for #{cn} --"
        @config.logger.extra "Reference", NicInfo::get_self_link( links )
        @config.logger.extra "More", NicInfo::get_alternate_link( links )
        @config.logger.extra "About", NicInfo::get_about_link( links )
        @config.logger.extra "TOS", NicInfo::get_tos_link( links )
        @config.logger.extra "(C)", NicInfo::get_copyright_link( links )
        @config.logger.extra "License", NicInfo::get_license_link( links )
      end
    end

    def display_events objectclass
      events = objectclass[ "events" ]
      if events
        events.each do |event|
          item_name = NicInfo::capitalize( event[ "eventAction" ] )
          item_value = Time.parse( event[ "eventDate" ] ).rfc2822
          actor = event[ "eventActor" ]
          if actor
            item_value << " by #{actor}"
          end
          @config.logger.datum item_name, item_value
        end
      end
    end

    def display_entities_as_events entities
      entities.each do |entity|
        entity.asEvents.each do |asEvent|
          item_name = NicInfo::capitalize( asEvent.eventAction )
          item_value = Time.parse( asEvent.eventDate ).rfc2822
          item_value << " by #{entity.get_cn}"
          @config.logger.datum item_name, item_value
        end if entity.asEvents
      end if entities
    end

  end

end