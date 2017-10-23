# Copyright (C) 2011,2012,2013,2014,2015 American Registry for Internet Numbers
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

#
# IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
#   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx

module NicInfo

  VERSION = "1.2.0"
  VERSION_LABEL = "NicInfo v." + VERSION
  COPYRIGHT = "Copyright (c) 2011-2017 American Registry for Internet Numbers (ARIN)"
  CONFIG_VERSION = 3

  # regular expressions
  NET_HANDLE_REGEX = /^NET-.*/i
  NET6_HANDLE_REGEX = /^NET6-.*/i
  AS_REGEX = /^[0-9]{1,10}$/
  ASN_REGEX = /^AS[0-9]{1,20}$/i
  IP4_ARPA = /\.in-addr\.arpa[\.]?/i
  IP6_ARPA = /\.ip6\.arpa[\.]?/i
  DATA_TREE_ADDR_REGEX = /\d=$/
  DOMAIN_REGEX = /^([\S\-]+\.?)+\.([a-z][a-z0\-]+)\.?$/i
  DOMAIN_SRCH_REGEX = /^([\S\-]+\.?)+\.([a-z][a-z0\-\*]+)\.?$/i
  NS_REGEX = /^ns[0-9]\.([\S\-]+\.?)+\.([a-z][a-z0\-]+)\.?$/i
  URL_REGEX = /^(http|https):\/\/.*/
  ENTITY_REGEX = /^.*\-.*/

  # IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
  #   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx
  IPV4_REGEX = /\A(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}\z/
  IPV6_REGEX = /\A(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z/
  IPV6_HEXCOMPRESS_REGEX = /\A((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)\z/

  #File Name Constants
  LASTTREE_YAML          = "lasttree.yaml"
  DEMO_DIR               = "demo"
  BOOTSTRAP_FILE_DIR     = "bsfiles"
  ASN_BOOTSTRAP          = "asn.json"
  DNS_BOOTSTRAP          = "dns.json"
  ENTITY_BOOTSTRAP       = "entity.json"
  IPV4_BOOTSTRAP         = "ipv4.json"
  IPV6_BOOTSTRAP         = "ipv6.json"

  # Config constants
  OUTPUT = "output"
  MESSAGES = "messages"
  MESSAGES_FILE = "messages_file"
  DATA = "data"
  DATA_FILE = "data_file"
  PAGER = "pager"
  AUTO_WRAP = "auto_wrap"
  DETECT_WIDTH = "detect_width"
  DEFAULT_WIDTH = "default_width"
  CACHE = "cache"
  CACHE_EXPIRY = "cache_expiry"
  CACHE_EVICTION = "cache_eviction"
  USE_CACHE = "use_cache"
  CLEAN_CACHE = "clean_cache"
  BOOTSTRAP = "bootstrap"
  BOOTSTRAP_URL = "bootstrap_url"
  HELP_ROOT_URL = "help_root_url"
  ENTITY_ROOT_URL = "entity_root_url"
  IP_ROOT_URL = "ip_root_url"
  AS_ROOT_URL = "as_root_url"
  DOMAIN_ROOT_URL = "domain_root_url"
  SEARCH = "search"
  SUBSTRING = "substring"
  CONFIG = "config"
  VERSION_CONFIG = "version"
  SECURITY = "security"
  TRY_INSECURE = "try_insecure"

  # NicInfo values
  NICINFO_DEMO_URL = "nicInfo_demoUrl"
  NICINFO_DEMO_HINT = "nicInfo_demoHint"
  NICINFO_DEMO_ERROR = "nicInfo_demoError"

  # Other constants
  RDAP_CONTENT_TYPE = "application/rdap+json"
  JSON_CONTENT_TYPE = "application/json"

  DNSSEC_ALGORITHMS = {
       0 =>  "reserved",
       1 =>  "RSA/MD5",
       2 =>  "Diffie-Hellman",
       3 =>  "DSA/SHA-1",
       4 =>  "Elliptic Curve",
       5 =>  "RSA/SHA-1",
     252 =>  "Indirect",
     253 =>  "Private DNS",
     254 =>  "Private OID",
     255 =>  "reserved"
  }

end
