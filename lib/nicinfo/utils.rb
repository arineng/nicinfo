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


require 'stringio'
require 'uri'
require 'nicinfo/config'

module NicInfo

  def NicInfo.make_safe( url )
    p = URI::Parser.new
    safe = p.escape( url )
    safe = p.escape( safe, "!*'();:@&=+$,/?#[]" )
    return safe
  end

  def NicInfo.get_secure_dns json_data
    return json_data[ "secureDNS" ]
  end

  def NicInfo.get_ds_data_objs json_data
    secure_dns = NicInfo::get_secure_dns json_data
    if secure_dns.instance_of? Array
      secure_dns = secure_dns[ 0 ]
    end
    return secure_dns[ "dsData" ] if secure_dns
    return nil
  end

  def NicInfo.get_key_data_objs json_data
    secure_dns = NicInfo::get_secure_dns json_data
    if secure_dns.instance_of? Array
      secure_dns = secure_dns[ 0 ]
    end
    return secure_dns[ "keyData" ] if secure_dns
    return nil
  end

  def NicInfo.get_algorithm json_data
    return json_data[ "algorithm" ]
  end

  def NicInfo.get_handle json_data
    return json_data[ "handle" ]
  end

  def NicInfo.get_object_class_name json_data, expected, config
    objectClassName =  json_data[ "objectClassName" ]
    if objectClassName == nil
      config.conf_msgs << "Expected 'objectClassName' is not present."
    elsif objectClassName != expected
      config.conf_msgs << "Expected 'objectClassName' to be '#{expected}' but it is '#{objectClassName}'."
    end
    return objectClassName
  end

  def NicInfo.get_ldhName json_data
    return json_data[ "ldhName" ]
  end

  def NicInfo.get_unicodeName json_data
    return json_data[ "unicodeName" ]
  end

  def NicInfo.get_descriptions json_data, config
    return if !json_data
    if json_data.instance_of?( Hash )
      retval = json_data[ "description" ]
      unless retval.instance_of?( Array )
        config.conf_msgs << "'description' is not an array."
        retval = nil
      end
    else
      config.conf_msgs << "expected object for 'remarks' or 'notices'."
      retval = nil
    end
    return retval
  end

  def NicInfo.get_entitites json_data
    return json_data[ "entities" ]
  end

  def NicInfo.get_networks json_data
    return json_data[ "networks" ]
  end

  def NicInfo.get_network json_data
    return json_data[ "network" ]
  end

  def NicInfo.get_autnums json_data
    return json_data[ "autnums" ]
  end

  def NicInfo.get_nameservers json_data
    return json_data[ "nameservers" ]
  end

  def NicInfo.get_startAddress json_data
    return json_data[ "startAddress" ]
  end

  def NicInfo.get_endAddress json_data
    return json_data[ "endAddress" ]
  end

  def NicInfo.get_startAutnum json_data
    return json_data[ "startAutnum" ]
  end

  def NicInfo.get_endAutnum json_data
    return json_data[ "endAutnum" ]
  end

  def NicInfo.get_name json_data
    return json_data[ "name" ]
  end

  def NicInfo.get_type json_data
    return json_data[ "type" ]
  end

  def NicInfo.get_country json_data
    return json_data[ "country" ]
  end

  def NicInfo.get_links json_data, config
    retval = json_data[ "links" ]
    return nil unless retval
    if !retval.instance_of?( Array )
      config.conf_msgs << "'links' is not an array."
      retval = nil
    end
    return retval
  end

  def NicInfo.get_related_link links
    get_link "related", links
  end

  def NicInfo.get_alternate_link links
    get_link "alternate", links
  end

  def NicInfo.get_tos_link links
    get_link "terms-of-service", links
  end

  def NicInfo.get_license_link links
    get_link "license", links
  end

  def NicInfo.get_copyright_link links
    get_link "copyright", links
  end

  def NicInfo.get_about_link links
    get_link "about", links
  end

  def NicInfo.get_self_link links
    get_link "self", links
  end

  def NicInfo.get_link rel, links
    return nil if !links
    links.each do |link|
      if link[ "rel" ] == rel
        return link[ "href" ]
      end
    end
    return nil
  end

  def NicInfo.capitalize str
    words = str.split( /\s/ )
    words.each do |word|
      word.capitalize!
    end
    return words.join( " " )
  end

end
