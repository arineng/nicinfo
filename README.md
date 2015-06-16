# Overview

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


# Versions

* 0.2.0 - A pre-release to the first stable version. Considered feature complete and compatible
with the latest RDAP specifications.
* 1.0.0 - First production release.

# System Requirements

NicInfo requires Ruby 1.8.7 or higher and should run on any operating system that supports it. 
Some features such as the pager support and auto-detection of terminal width will only work on 
Unix style systems such as Linux and Mac OS X. 

Information on specific platforms are noted below:

* Ruby 1.8.7: This will require you install the Ruby JSON parser. Depending on your system, that
may be as simple as `gem install json`. You should probably moving away from Ruby 1.8.7.
* RedHat / CentOS 6: This will require Ruby's JSON parser, as noted above. This may require installing
multiple RPMs: `yum install gcc rubygems ruby-devel` before running `gem install json`.
You should probably be moving away from RedHat or CentOS 6.
* Docker ruby:2.0,2.1,2.2: This is a docker image based on a very scaled down Ubuntu Linux distribution.
The "less" pager is not installed, so you will need to install it or disable pager use in NicInfo.
Installing "less" can be done with `apt-get update` followed by `apt-get install less`.

# Getting and Installing

## As a Ruby Gem

Issue the following command: `gem install nicinfo`

Once it is installed, try `nicinfo -h`

## As an OS Package

OS-specific packages are also provided for RedHat/CentOS based systems, Debian based systems, and
Mac OS X. See [GitHub](https://github.com/arinlabs/nicinfo/releases). These packages are based on
the Ruby Gem using FPM.

## As Source from Git

To get the source, issue the following git command.

```
git clone https://github.com/arinlabs/nicinfo.git
```

Once cloned, place the bin directory in your shell's execution path or refer directly to "nicinfo" 
with a path when running the program.

Once installed, use the -h option to view the help: `nicinfo -h`

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

In addition to these cached queries, Afilias has made available a proto RDAP server for the .info 
domain along with many live demonstration queries.

    nicinfo -V ns1.ams1.afilias-nst.info

    nicinfo -V xn--114-vm7le44f.info

    nicinfo http://rdg.afilias.info/rdap/domain/dnssec.test


