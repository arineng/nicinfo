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

    BNode = Struct.new( :left, :right, :number, :data, :cidr_string, :ipaddr )

    def new_bnode( cidr_string, data )
      ipaddr = IPAddr.new( cidr_string )
      number = ipaddr.to_range.begin.to_i
      return BNode.new( nil, nil, number, data, cidr_string, ipaddr )
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

end
