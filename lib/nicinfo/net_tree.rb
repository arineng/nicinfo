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


  class NetTree

    NetNode = Struct.new( :cidr_length, :ipaddr, :data )

    attr_accessor :v4_root, :v6_root

    def initialize
      @btree = NicInfo::BinarySearchTree.new
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

    def insert_into_root( root, cidr_length, start_addr, ipaddr, data )
      if root
        s = @btree.lookup( root, start_addr )
        if s
          if s.data.is_a?( Array )
            s.data.each do |i|
              if i.ipaddr.eql?( ipaddr )
                raise "collision. s: #{i} n: #{ipaddr}"
              end
            end
            #else
            net_node = NetNode.new( cidr_length, ipaddr, data )
            s.data = append_to( s.data, net_node )
          elsif s.data.ipaddr.eql?( ipaddr )
            raise "collision. s: #{s} n: #{ipaddr}"
          else
            net_node = NetNode.new( cidr_length, ipaddr, data )
            s.data = append_to( s.data, net_node )
          end
        else
          net_node = NetNode.new( cidr_length, ipaddr, data )
          @btree.insert( root, start_addr, net_node )
        end
      else
        net_node = NetNode.new( cidr_length, ipaddr, data )
        root = @btree.insert( root, start_addr, net_node )
      end
      return root
    end

    def insert( cidr_string, data )

      ipaddr = IPAddr.new( cidr_string )
      cidr_length = cidr_string.split( "/" )[1].to_i
      start_addr = ipaddr.to_range.begin.to_i
      if ipaddr.ipv4?
        r = insert_into_root( @v4_root, cidr_length, start_addr, ipaddr, data )
        @v4_root = r unless @v4_root
      else
        r = insert_into_root( @v6_root, cidr_length, start_addr, ipaddr, data )
        @v6_root = r unless @v6_root
      end

    end

    def find_by_root( root, ipaddr )
      retval = nil
      n = @btree.floor( root, ipaddr.to_i )
      if n
        if n.data.is_a?( Array )
          n.data.each do |i|
            if i.ipaddr.include?( ipaddr )
              retval = i.data
              break
            end
          end
        else
          retval = n.data.data if n.data.ipaddr.include?( ipaddr )
        end
      end
      return retval
    end

    def find_by_ipaddr( ip )
      ipaddr = IPAddr.new( ip )
      if ipaddr.ipv4?
        return find_by_root( @v4_root, ipaddr )
      else
        return find_by_root( @v6_root, ipaddr )
      end
    end

    def each( &block )
      @btree.each( @v4_root, &block )
      @btree.each( @v6_root, &block )
    end

  end

end
