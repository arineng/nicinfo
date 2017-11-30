# Overview
[![Gem Version](https://badge.fury.io/rb/nicinfo.svg)](https://badge.fury.io/rb/nicinfo)
[![Build Status](https://travis-ci.org/arineng/nicinfo.svg?branch=master)](https://travis-ci.org/arineng/nicinfo)
[![Dependency Status](https://gemnasium.com/badges/github.com/arineng/nicinfo.svg)](https://gemnasium.com/github.com/arineng/nicinfo)
[![Coverage Status](https://coveralls.io/repos/github/arineng/nicinfo/badge.svg?branch=master)](https://coveralls.io/github/arineng/nicinfo?branch=master)

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

* 0.2.0 - A pre-release to the first stable version. Considered feature complete and compatible
with the latest RDAP specifications.
* 1.0.0 - First production release.
* 1.1.0 -
  * New Features
    * New --try-insecure option for those times with SSL/TLS negotiation just isn't gonna work
    * Now checks for older configs.
    * Changes in the way data is displayed to make searches easier to understand.
  * Bug Fixes
    * Now showing nameservers on domains.
    * Namespacing of library files to let NicInfo work in some Ruby environments
* 1.1.1
  * Bug Fixes
    * Bootstrap files were not being read properly
    * Some more trace logging with bootstrapping
    * Updated defaults to latest IANA file
    * Fixed failing unit tests with data tree.
    * Fix for running on cygwin
* 1.2.0
  * Dropped support for...
    * Ruby 1.8.7, 1.9.3, and 2.0.
    * OS specific packages (use Ruby gem install)
  * New Features
    * Look up network information based on your IP address.
    * Added calculated CIDR ranges to IP networks.
    * Added traceroute function (experimental)
  * Changed default pager to `more` from `less`
* 1.2.1
  * Updated asn.json and dns.json bootstrap files from IANA.
  * Fixed small bug in self IP lookup which incorrectly expected RIPE stat to be an RDAP server.

# System Requirements

NicInfo requires Ruby 2.1.3 or higher and should run on any operating system that supports it. 
Some features such as the pager support and auto-detection of terminal width will only work on 
Unix style systems such as Linux and Mac OS X. 

Information on specific platforms are noted below:

* RedHat / CentOS 6: Use [RVM](https://rvm.io/) to install a compatible version of Ruby.
* Docker ruby:2.1,2.2: This is a docker image based on a very scaled down Ubuntu Linux distribution.
The "less" pager is not installed, so you will need to install it or disable pager use in NicInfo.
Installing "less" can be done with `apt-get update` followed by `apt-get install less`.

# Getting and Installing

## As a Ruby Gem

Issue the following command: `gem install nicinfo`

Once it is installed, try `nicinfo -h`

NicInfo ships with a set of RDAP bootstrap files from the IANA. However, these files are always changing,
and you may wish to update them from time to time: `nicinfo --iana -V`

## As an OS Package

OS packages are no longer provided as they were troublesome and mostly broken. If you don't want to install from
source, install using the Ruby gem method above. If you're OS doesn't provide a modern, compatible version of Ruby
then use [Ruby Version Manager](https://rvm.io/) to install a newer version of Ruby and then install NicInfo as a
gem.

## As Source from Git

To get the source, issue the following git command.

```
git clone https://github.com/arinlabs/nicinfo.git
```

Once cloned, place the bin directory in your shell's execution path or refer directly to "nicinfo" 
with a path when running the program.

NicInfo requires the netaddr package in Ruby. Here's how to install it:

```
gem install netaddr --user-install
```

Once installed, use the -h option to view the help: `nicinfo -h`

NicInfo ships with a set of RDAP bootstrap files from the IANA. However, these files are always changing,
and you may wish to update them from time to time: `nicinfo --iana -V`

## Getting Help

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


# Building and Testing

To get the source, issue the following git command.

```
git clone https://github.com/arinlabs/nicinfo.git
```

To develop in isolation, use [Ruby Version Manager (RVM)](https://rvm.io/) and issue a command like

```bash
rvm use 2.3.1@nicinfo
```

Running and testing is best done with bundler. To install it `gem install bundler`.

Then use bundler to install NicInfo's dependencies: `bundle install`.

To run the tests: `bundle exec rake test`

To run Nicinfo: `bundle exec bin/nicinfo -V .`

