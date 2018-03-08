# Copyright (C) 2018 American Registry for Internet Numbers
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

require 'ipaddr'

module NicInfo

  class NetPrefixTree

    Node = Struct.new( :cidr_prefix, :cidr_length, :ipaddr, :data )

    attr_accessor :v4_tree, :v6_tree

    def initialize
      @v4_tree = {}
      @v6_tree = {}
    end

    def find_by_ipaddr( ip )
      ipaddr = IPAddr.new( ip )
      retval = nil
      if ipaddr.ipv4?
        segments = ipaddr.to_string.split( "." )
        tree = @v4_tree
      else
        segments = ipaddr.to_string.split( ":" )
        tree = @v6_tree
      end
      3.times.each do |depth|
        tree = tree[ segments[ depth ] ]
        break unless tree
      end
      if tree
        t = tree[ segments[ 4 ] ]
        if t
          if t.is_a?( Array )
            t.each do |n|
              if n[:ipaddr].include?( ipaddr )
                retval = n[:data]
                break
              end
            end
          else
            retval = t[:data]
          end
        end
      end
      return retval
    end

    def insert( cidr_string, data )
      ipaddr = IPAddr.new( cidr_string )
      if ipaddr.ipv4?
        segments = ipaddr.to_string.split( "." )
        cidr = cidr_string.split( "/" )
        cidr_prefix = cidr[ 0 ]
        cidr_length = cidr[ 1 ].to_i
        tree = @v4_tree
      else
        segments = ipaddr.to_string.split( ":" )
        cidr = cidr_string.split( "/" )
        cidr_prefix = cidr[ 0 ]
        cidr_length = cidr[ 1 ].to_i
        tree = @v6_tree
      end
      3.times.each do |depth|
        t = tree[ segments[ depth ] ]
        unless t
          t = {}
          tree[ segments[ depth] ] = t
        end
        tree = t
      end
      t = tree[ segments[ 4 ] ]
      if t == nil
        t = Node.new( cidr_prefix, cidr_length, ipaddr, data)
        tree[ segments[ 4 ] ] = t
      elsif t.is_a?( Array )
        t << Node.new( cidr_prefix, cidr_length, ipaddr, data )
        t.sort! do |x,y|
          y[:cidr_length] <=> x[:cidr_length]
        end
      else
        if t[:cidr_length] > cidr_length
          a = [ Node.new( cidr_prefix, cidr_length, ipaddr, data), t ]
        else
          a = [ t, Node.new( cidr_prefix, cidr_length, ipaddr, data) ]
        end
        tree[ segments[ 4 ] ] = a
      end
    end

    def each
    end

  end

end
