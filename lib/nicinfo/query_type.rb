# Copyright (C) 2011-2018 American Registry for Internet Numbers
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

require 'nicinfo/enum'

module NicInfo

  class QueryType < NicInfo::Enum

    QueryType.add_item :BY_IP4_ADDR, "IP4ADDR"
    QueryType.add_item :BY_IP6_ADDR, "IP6ADDR"
    QueryType.add_item :BY_IP4_CIDR, "IP4CIDR"
    QueryType.add_item :BY_IP6_CIDR, "IP6CIDR"
    QueryType.add_item :BY_IP, "IP"
    QueryType.add_item :BY_AS_NUMBER, "ASNUMBER"
    QueryType.add_item :BY_DOMAIN, "DOMAIN"
    QueryType.add_item :BY_RESULT, "RESULT"
    QueryType.add_item :BY_ENTITY_HANDLE, "ENTITYHANDLE"
    QueryType.add_item :BY_NAMESERVER, "NAMESERVER"
    QueryType.add_item :SRCH_ENTITY_BY_NAME, "ESBYNAME"
    QueryType.add_item :SRCH_DOMAINS, "DOMAINS"
    QueryType.add_item :SRCH_DOMAIN_BY_NAME, "DSBYNAME"
    QueryType.add_item :SRCH_DOMAIN_BY_NSNAME, "DSBYNSNAME"
    QueryType.add_item :SRCH_DOMAIN_BY_NSIP, "DSBYNSIP"
    QueryType.add_item :SRCH_NS, "NAMESERVERS"
    QueryType.add_item :SRCH_NS_BY_NAME, "NSBYNAME"
    QueryType.add_item :SRCH_NS_BY_IP, "NSBYIP"
    QueryType.add_item :TRACE, "TRACE"
    QueryType.add_item :BY_SERVER_HELP, "HELP"
    QueryType.add_item :BY_URL, "URL"

  end

  # Looks at the returned JSON and attempts to match that
  # to a query type.
  def NicInfo.get_query_type_from_result( json_data )
    retval = nil
    object_class_name = json_data[ "objectClassName" ]
    if object_class_name != nil
      case object_class_name
        when "domain"
          retval = QueryType::BY_DOMAIN
        when "ip network"
          retval = QueryType::BY_IP
        when "entity"
          retval = QueryType::BY_ENTITY_HANDLE
        when "autnum"
          retval = QueryType::BY_AS_NUMBER
        when "nameserver"
          retval = QueryType::BY_NAMESERVER
      end
    end
    if json_data[ "domainSearchResults" ]
      retval = QueryType::SRCH_DOMAINS
    elsif json_data[ "nameserverSearchResults" ]
      retval = QueryType::SRCH_NS
    elsif json_data[ "entitySearchResults" ]
      retval = QueryType::SRCH_ENTITY_BY_NAME
    end
    return retval
  end

end