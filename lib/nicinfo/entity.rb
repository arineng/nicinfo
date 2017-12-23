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
require 'nicinfo/common_json'
require 'nicinfo/data_tree'

module NicInfo

  def NicInfo.display_entity json_data, config, data_tree
    entity = config.factory.new_entity.process( json_data )

    respobjs = ResponseObjSet.new config
    root = entity.to_node
    data_tree.add_root( root )
    if !entity.entities.empty?
      NicInfo::add_entity_nodes( entity.entities, root )
    end
    entity.networks.each do |network|
      net_node = network.to_node
      root.add_child( net_node )
      NicInfo::add_entity_nodes( network.entities, net_node )
    end
    entity.autnums.each do |autnum|
      as_node = autnum.to_node
      root.add_child( as_node )
      NicInfo::add_entity_nodes( autnum.entities, as_node )
    end

    respobjs.add entity
    NicInfo::add_entity_respobjs( entity.entities, respobjs )
    respobjs.associateEntities entity.entities
    entity.networks.each do |network|
      respobjs.add network
      NicInfo::add_entity_respobjs( network.entities, respobjs )
      respobjs.associateEntities network.entities
    end
    entity.autnums.each do |autnum|
      respobjs.add autnum
      NicInfo::add_entity_respobjs( autnum.entities, respobjs )
      respobjs.associateEntities autnum.entities
    end

    data_tree.to_normal_log( config.logger, true )
    respobjs.display
  end

  def NicInfo.display_entities json_data, config, data_tree
    entity_array = json_data[ "entitySearchResults" ]
    if entity_array != nil
      if entity_array.instance_of? Array
        display_array = Array.new
        entity_array.each do |ea|
          entity = config.factory.new_entity.process( ea )
          display_array << entity
        end
        NicInfo.display_object_with_entities( display_array, config, data_tree )
      else
        config.conf_msgs << "'entitySearchResults' is not an array"
      end
    else
      config.conf_msgs << "'entitySearchResults' is not present"
    end
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

    attr_accessor :fns, :names, :phones, :emails, :adrs, :kind, :titles, :roles, :orgs

    def initialize
      @fns = Array.new
      @names = Array.new
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
          if element[ 0 ] == "n"
            name = ""
            if element[ 3 ][ -1 ].instance_of? Array
              name << element[ 3 ][ -1 ].join( ' ' )
            end
            name << ' ' if name[-1] != ' '
            name << element[ 3 ][ 1 ]
            if element[ 3 ][ 2 ] && !element[ 3 ][ 2 ].empty?
              name << " " << element[ 3 ][ 2 ]
            end
            if element[ 3 ][ 3 ] && !element[ 3 ][ 3 ].empty?
              name << " " << element[ 3 ][ 3 ]
            end
            name << " " << element[ 3 ][ 0 ]
            if element[ 3 ][ -2 ].instance_of? Array
              name << " " << element[ 3 ][ -2 ].join( ' ' )
            end
            @names << name
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

  # deals with RDAP entity structures
  class Entity

    attr_accessor :asEvents, :selfhref
    attr_accessor :entities, :objectclass, :asEventActors
    attr_accessor :networks, :autnums

    def initialize config
      @config = config
      @jcard = JCard.new
      @common = CommonJson.new config
      @entity = nil
      @asEvents = Array.new
      @asEventActors = Array.new
      @selfhref = nil
      @entities = Array.new
    end

    def process json_data
      @objectclass = json_data
      @jcard.process json_data
      events = @objectclass[ "asEventActor" ]
      events.each do |event|
        eventActor = EventActor.new
        eventActor.eventAction=event[ "eventAction" ]
        eventActor.eventDate=event[ "eventDate" ]
        eventActor.related=NicInfo.get_related_link( NicInfo.get_links( event, @config ) )
        @asEvents << eventActor
      end if events
      @selfhref = NicInfo::get_self_link( NicInfo::get_links( @objectclass, @config ) )
      @entities = @common.process_entities @objectclass
      @networks = Array.new
      json_networks = NicInfo::get_networks( @objectclass )
      json_networks.each do |json_network|
        if json_network.is_a?( Hash )
          network = @config.factory.new_ip
          network.process( json_network )
          @networks << network
        else
          @config.conf_msgs << "'networks' contains a string and not an object"
        end
      end if json_networks
      @autnums = Array.new
      json_autnums = NicInfo::get_autnums( @objectclass )
      json_autnums.each do |json_autnum|
        if json_autnum.is_a?( Hash )
          autnum = @config.factory.new_autnum
          autnum.process( json_autnum )
          @autnums << autnum
        else
          @config.conf_msgs << "'autnums' contains a string and not an object"
        end
      end if json_autnums
      return self
    end

    def display
      @config.logger.start_data_item
      @config.logger.data_title "[ ENTITY ]"
      @config.logger.terse "Handle", NicInfo::get_handle( @objectclass ), NicInfo::AttentionType::SUCCESS
      @config.logger.extra "Object Class Name", NicInfo::get_object_class_name( @objectclass )
      @jcard.fns.each do |fn|
        @config.logger.terse "Name", fn, NicInfo::AttentionType::SUCCESS
      end
      @jcard.names.each do |n|
        @config.logger.extra "Name", n, NicInfo::AttentionType::SUCCESS
      end
      @jcard.orgs.each do |org|
        item_value = org.names.join( ", " )
        if !org.type.empty?
          item_value << " ( #{org.type.join( ", " )} )"
        end
        @config.logger.terse "Organization", item_value, NicInfo::AttentionType::SUCCESS
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
      @common.display_public_ids @objectclass
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
      @common.display_as_events_actors @asEventActors
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
