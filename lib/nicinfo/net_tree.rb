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

  class NetBTree

    BNode = Struct.new( :left, :right, :number, :data, :cidr_string, :cidr_prefix, :cidr_length, :ipaddr )

    def new_bnode( cidr_string, data )
      ipaddr = IPAddr.new( cidr_string )
      number = ipaddr.to_range.begin.to_i
      cidr = cidr_string.split( "/" )
      return BNode.new( nil, nil, number, data, cidr_string, cidr[0], cidr[1].to_i, ipaddr )
    end

    def put( node, cidr_string, data )
      new_node = new_bnode( cidr_string, data )
      return insert( node, new_node)
    end

    def insert( node, new_node )
      if node == nil
        return new_node
      else
        if new_node.number <= node.number
          node.left = insert( node.left, new_node )
        else
          node.right = insert( node.right, new_node )
        end
        return node
      end
    end

    def get( node, ip )
      target = IPAddr.new( ip ).to_i
      return lookup( node, target )
    end

    def lookup( node, target )
      if node == nil
        return nil
      else
        if target == node.number
          return node
        else
          if target < node.number
            return lookup( node.left, target )
          else
            return lookup( node.right, target )
          end
        end
      end
    end

    def get_floor( node, ip )
      target = IPAddr.new( ip ).to_i
      return floor( node, target )
    end

    def floor( node, target )
      if node == nil
        return nil
      else
        if target == node.number
          return node
        else
          if target < node.number
            return floor( node.left, target )
          else
            f = floor( node.right, target )
            if f
              return f
            else
              return node
            end
          end
        end
      end
    end

  end

  class NetTree

    attr_accessor :v4_root, :v6_root

    def initialize
      @btree = NicInfo::NetBTree.new
    end

    def append_to( l, n )
      unless l.is_a?( Array )
        l = [ l ]
      end
      l << n
      return l.sort! do |x,y|
        y.cidr_length <=> x.cidr_length
      end
    end

    def insert( cidr_string, data )

      n = @btree.new_bnode( cidr_string, data )
      if n.ipaddr.ipv4?
        if @v4_root
          s = @btree.lookup( @v4_root, n.number )
          if s
            if s.ipaddr.eql?( n.ipaddr )
              raise "collision. s: #{s} n: #{n}"
            else
              s.data = append_to( s, n )
            end
          else
            @btree.insert( @v4_root, n )
          end
        else
          @v4_root = n
        end
      else
        if @v6_root
          s = @btree.lookup( @v6_root, n.number )
          if s
            if s.ipaddr.eql?( n.ipaddr )
              raise "collision. s: #{s} n: #{n}"
            else
              s.data = append_to( s, n )
            end
          else
            @btree.insert( @v6_root, n )
          end
        else
          @v6_root = n
        end
      end

    end

    def find_by_ipaddr( ip )
      retval = nil
      ipaddr = IPAddr.new( ip )
      if ipaddr.ipv4?
        n = @btree.floor( @v4_root, ipaddr.to_i )
        if n
          if n.is_a?( Array )
            n.each do |i|
              if i.ipaddr.include?( ipaddr )
                retval = i.data
                break
              end
            end
          else
            retval = n.data
          end
        end
      else
        n = @btree.floor( @v6_root, ipaddr.to_i )
        if n
          if n.is_a?( Array )
            n.each do |i|
              if i.ipaddr.include?( ipaddr )
                retval = i.data
                break
              end
            end
          else
            retval = n.data
          end
        end
      end
      return retval
    end

  end

end
