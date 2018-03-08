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
      depth = 0
      loop do
        n = tree[ segments[ depth ] ]
        if n
          if n.is_a?( Hash )
            tree = tree[ segments[ depth ] ]
            depth = depth + 1
          elsif n.is_a?( Array )
            n.each do |i|
              if i[:ipaddr].include?( ipaddr )
                retval = i
                break
              end
            end
            break
          elsif n[:ipaddr].include?( ipaddr )
            retval = n
            break
          end
        else
          break
        end
      end
      return retval
    end

    def insert( cidr_string, data )
      ipaddr = IPAddr.new( cidr_string )
      if ipaddr.ipaddr.ipv4?
        segments = ipaddr.to_string.split( "." )
        cidr = cidr_string.split( "/" )
        segment_depth = cidr[1].to_i / 8
        tree = @v4_tree
      else
        segments = ipaddr.to_string.split( ":" )
        cidr = cidr_string.split( "/" )
        segment_depth = cidr[1].to_i / 16
        tree = @v6_tree
      end
      depth = 0
      segment_depth = segment_depth - 1
      loop do
        n = tree[ segments[ depth ] ]
        if n
          if depth == segment_depth
            if n.is_a?( Hash )
              raise "hash found mistakenly. depth: #{depth} cidr: #{cidr_string}"
            elsif n.is_a?( Array )
              a = n.detect do |i|
                i[ :cidr_length ] == cidr[ 1 ]
              end
              if a
                raise "tree collision in array. cidr: #{cidr_string} node: #{a}"
              else
                n << Node.new( cidr[0], cidr[1], ipaddr, data )
                n.sort! do |x,y|
                  y[:cidr_length].to_i <=> x[:cidr_length].to_i
                end
              end
            else
              if n[:cidr_length] == cidr[ 1 ]
                raise "tree collision in array. cidr: #{cidr_string} node: #{a}"
              else
                if n[:cidr_length].to_i > cidr[1].to_i
                  a = [ Node.new( cidr[0], cidr[1], ipaddr, data), n ]
                else
                  a = [ n, Node.new( cidr[0], cidr[1], ipaddr, data) ]
                end
                tree[ segments[ depth ] ] = a
              end
            end
          end
          #else drop through and loop again
        else
          if depth != segment_depth
            tree[ segments[ depth ] ] = {}
          else
            tree[ segments[ depth ] ] = Node.new( cidr[0], cidr[1], ipaddr, data )
          end
        end
        break if depth == segment_depth
        tree = tree[ segments[ depth ] ]
        depth = depth + 1
      end
    end

    def each
    end

  end

end
