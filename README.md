# Overview
[![Gem Version](https://badge.fury.io/rb/nicinfo.svg)](https://badge.fury.io/rb/nicinfo)
[![Build Status](https://travis-ci.org/arineng/nicinfo.svg?branch=master)](https://travis-ci.org/arineng/nicinfo)
[![Build status](https://ci.appveyor.com/api/projects/status/8rr7uqn7gscq9dm2?svg=true)](https://ci.appveyor.com/project/anewton1998/nicinfo)
[![Dependency Status](https://gemnasium.com/badges/github.com/arineng/nicinfo.svg)](https://gemnasium.com/github.com/arineng/nicinfo)
[![Coverage Status](https://coveralls.io/repos/github/arineng/nicinfo/badge.svg?branch=master)](https://coveralls.io/github/arineng/nicinfo?branch=master)

> This branch is being kept for historical purposes.  We will be reverting an incomplete feature
> that is currently in master.  If anyone has forked the repository after this feature, you may
> use this branch as a basis.  At some point, we may return to this branch as a starting point
> to complete this feature.

NicInfo is a general purpose, command line Registry Data Access Protocol (RDAP) client released under 
an open source, ISC derivative BSD style license. RDAP is an HTTP-based RESTful protocol defined by 
the IETF as a replacement for Whois. 

The general usage of this software from the command line is "nicinfo QUERY_VALE" where the 
QUERY_VALUE is an IP address, domain name, autonomous system number, name server host name, 
or entity identifier. NicInfo will attempt to determine the most appropriate RDAP server to query 
and follow redirects to other RDAP servers as needed.

## Features

NicInfo has the following features:

* Query type detection: it will attempt to determine what type of query is needed based on the supplied query value.
* Plain text output: default output is a text version of the RDAP results.
* JSON output: the RDAP JSON can be passed directly to a calling program for intergration with scripts with
the ability to select specific JSON values.
* Multiple output controls: the amount of text detail and process execution can be varied and sent to different files.
* A Built-in cache: RDAP queries are cached.
* Bootstrapping using the IANA bootstrap files or by using a
bootstrap server.
* Demonstration queries: a set of built-in queries and results are provided for demonstration purposes.

The following is an example of using NicInfo:

    $ bin/nicinfo --pager no 1.1.1.1
    # NicInfo v.0.1.0-snapshot
    
    [ NOTICE ] Source
             1 Objects returned came from source
             2 APNIC
    
    [ NOTICE ] Terms and Conditions
             1 This is the APNIC WHOIS Database query service. The objects are in RDAP format.
           TOS http://www.apnic.net/db/dbcopyright.html
    
    [ RESPONSE DATA ]
      1= 1.1.1.0 - 1.1.1.255
         |--- 1= APNIC RESEARCH ( AR302-AP )
         `--- 2= IRT-APNICRANDNET-AU ( IRT-APNICRANDNET-AU )
    
               [ IP NETWORK ]
                       Handle:  1.1.1.0 - 1.1.1.255
                Start Address:  1.1.1.0
                  End Address:  1.1.1.255
                   IP Version:  v4
                      Country:  AU
                         Type:  ASSIGNED PORTABLE
                 Last Changed:  Mon, 12 May 2014 04:16:03 -0000
                      Remarks:  -- description --
                            1:  Research prefix for APNIC Labs
                            2:  APNIC
    
                   [ ENTITY ]
                       Handle:  AR302-AP
                         Name:  APNIC RESEARCH
                        Email:  research@apnic.net
                        Phone:  +61-7-3858-3188 ( voice )
                        Phone:  +61-7-3858-3199 ( fax )
                        Roles:  Technical, Administrative
            Excessive Remarks:  Use "-V" or "--data extra" to see them.
    
                   [ ENTITY ]
                       Handle:  IRT-APNICRANDNET-AU
                         Name:  IRT-APNICRANDNET-AU
                        Email:  abuse@apnic.net
                        Email:  abuse@apnic.net
                        Roles:  Abuse
    
    # Use "nicinfo -r 1.1.1.1" to see reverse DNS information.
    # Use "nicinfo 1=" to show 1.1.1.0 - 1.1.1.255
    # Use "nicinfo 1.1=" to show APNIC RESEARCH ( AR302-AP )
    # Use "nicinfo 1.2=" to show IRT-APNICRANDNET-AU ( IRT-APNICRANDNET-AU )
    # Use "nicinfo http://rdap.apnic.net/ip/1.1.1.0/24" to directly query this resource in the future.
    # Use "nicinfo -h" for help.


# Live examples

```bash
nicinfo -V .
nicinfo nic.br
nicinfo nic.cz
```

# Versions

Information about the various versions of NicInfo can be found in the [CHANGE LOG](https://github.com/arineng/nicinfo/wiki/CHANGELOG)
on the [project wiki](https://github.com/arineng/nicinfo/wiki).

# Getting and Installing

Getting and installing NicInfo is easily accomplished as a Ruby Gem using the command `gem install nicinfo`.
If that does not work for you, follow the instructions and advice for your platform on the project Wiki
[here](https://github.com/arineng/nicinfo/wiki/Installing).

If you wish to build and test this software from source, it follows the typical Ruby development process.
More information may be found [here](https://github.com/arineng/nicinfo/wiki/Building-and-Testing).

## Getting Help

Helpful information about NicInfo (and RDAP) may be found on the [project wiki](https://github.com/arineng/nicinfo/wiki).

If you have questions or need help with this software, you may use the issue tracker on
[GitHub](https://github.com/arinlabs/nicinfo/issues) or you may use the
[ARIN Technical Discussions ](http://lists.arin.net/mailman/listinfo/arin-tech-discuss)
mailing list (it is a very low volume list).


# Demonstration Queries

Demonstration queries are available with the --demo option, which will seed the cache with 
results and list the available demonstration queries.

```
nicinfo --demo
```

After the cache has been seeded, you will be presented with a list of example queries which will 
pull information from the cache.

