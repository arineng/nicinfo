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

require 'config'
require 'nicinfo_logger'
require 'utils'
require 'time'
require 'entity'

module NicInfo

  def NicInfo.display_object_with_entities object, config, data_node
    obj_array = object
    unless object.instance_of? Array
      obj_array = Array.new
      obj_array << object
    end
    respobjs = ResponseObjSet.new config
    obj_array.each do |array_object|
      root = array_object.to_node
      data_node.add_root( root )
      if !array_object.entities.empty?
        NicInfo::add_entity_nodes( array_object.entities, root )
      end
      respobjs.add array_object
      NicInfo::add_entity_respobjs( array_object.entities, respobjs )
      respobjs.associateEntities array_object.entities
    end
    data_node.to_normal_log( config.logger, true )
    respobjs.display
  end

  def NicInfo.add_entity_nodes entities, node
    entities.each do |entity|
      entity_node = entity.to_node
      node.add_child( entity_node )
      NicInfo::add_entity_nodes( entity.entities, entity_node )
    end if entities
  end

  def NicInfo.add_entity_respobjs entities, respobjs
    entities.each do |entity|
      respobjs.add( entity )
      NicInfo::add_entity_respobjs( entity.entities, respobjs )
    end if entities
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
      if (Notices::is_excessive_notice(remarks, @config)) && (@config.logger.data_amount != NicInfo::DataAmount::EXTRA_DATA)
        @config.logger.datum "Excessive Remarks", "Use \"-V\" or \"--data extra\" to see them."
      else
        if remarks
          if remarks.instance_of?( Array )
            remarks.each do |remark|
              if remark.instance_of?( Hash )
                title = remark[ "title" ]
                @config.logger.datum "Remarks", "-- #{title} --" if title
                descriptions = NicInfo::get_descriptions remark, @config
                i = 1
                descriptions.each do |line|
                  if !title && i == 1
                    @config.logger.datum "Remarks", line
                  elsif i != 1 || title
                    @config.logger.datum i.to_s, line
                  end
                  i = i + 1
                end if descriptions
                links = NicInfo::get_links remark, @config
                if links
                  @config.logger.datum "More", NicInfo::get_alternate_link( links )
                  @config.logger.datum "About", NicInfo::get_about_link( links )
                  @config.logger.datum "TOS", NicInfo::get_tos_link( links )
                  @config.logger.datum "(C)", NicInfo::get_copyright_link( links )
                  @config.logger.datum "License", NicInfo::get_license_link( links )
                end
              else
                @config.conf_msgs << "remark is not an object."
              end
            end
          else
            @config.conf_msgs << "'remarks' is not an array."
          end
        end
      end
    end

    def display_string_array json_name, display_name, json_data, data_amount
      arr = json_data[ json_name ]
      if arr
        if arr.instance_of?( Array )
          new_arr = Array.new
          arr.each do |str|
            if str.instance_of?( String )
              new_arr << NicInfo::capitalize( str )
            else
              @config.conf_msgs << "value in string array is not a string."
            end
          end
          @config.logger.info data_amount, display_name, new_arr.join( ", " )
        else
          @config.conf_msgs << "'#{json_name}' is not an array."
        end
      end
    end

    def display_status objectclass
      display_string_array "status", "Status", objectclass, DataAmount::NORMAL_DATA
    end

    def display_port43 objectclass
      @config.logger.extra "Port 43 Whois", objectclass[ "port43" ]
    end

    def display_links cn, objectclass
      links = NicInfo::get_links objectclass, @config
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
        if events.instance_of?( Array )
          events.each do |event|
            item_name = NicInfo::capitalize( event[ "eventAction" ] )
            item_value = Time.parse( event[ "eventDate" ] ).rfc2822
            actor = event[ "eventActor" ]
            if actor
              item_value << " by #{actor}"
            end
            @config.logger.datum item_name, item_value
          end
        else
          @config.conf_msgs << "'events' is not an array."
        end
      end
    end

    def display_as_events_actors asEventActors
      asEventActors.each do |asEventActor|
        item_name = NicInfo::capitalize( asEventActor.eventAction )
        item_value = Time.parse( asEventActor.eventDate ).rfc2822
        item_value << " by #{asEventActor.entity_cn}"
        @config.logger.datum item_name, item_value
      end
    end

    def display_public_ids objectclass
      public_ids = objectclass[ "publicIds" ]
      if public_ids
        if public_ids.instance_of?( Array )
          public_ids.each do |public_id|
            if public_id.instance_of?( Hash )
              item_name = "Public ID"
              item_value = public_id[ "identifier" ]
              authority = public_id[ "type" ]
              item_value << " (#{authority})" if authority
              @config.logger.datum item_name, item_value
            else
              @config.conf_msgs << "public id in array 'publicIds' is not an object."
            end
          end
        else
          @config.conf_msgs << "'publicIds' is not an array."
        end
      end
    end

  end

  class EventActor
    attr_accessor :eventAction, :eventDate, :related, :entity_cn
  end

  # for keeping track of objects to display
  class ResponseObjSet

    def initialize config
      @config = config
      @arr = Array.new #for keeping track of insertion order
      @set = Hash.new
      @self_links = Hash.new
    end

    def add respObj
      if respObj.instance_of? Array
        respObj.each do |obj|
          add obj
        end
      else
        if !@set[ respObj.get_cn ]
          @set[ respObj.get_cn ] = respObj
          @arr << respObj
          self_link = NicInfo.get_self_link( NicInfo.get_links( respObj.objectclass, @config ) )
          @self_links[ self_link ] = respObj if self_link
        end
      end
    end

    def display
      @arr.each do |object|
        object.display
      end
    end

    def associateEventActor eventActor
      return if !eventActor or !eventActor.related
      associate = @self_links[ eventActor.related ]
      if associate
        associate.asEventActors << eventActor
      end
    end

    def associateEntities entities
      entities.each do |entity|
        associateEntities entity.entities if !entity.entities.empty?
        entity.asEvents.each do |asEvent|
          asEvent.entity_cn = entity.get_cn
          associateEventActor asEvent
        end
      end if entities
    end

  end

end