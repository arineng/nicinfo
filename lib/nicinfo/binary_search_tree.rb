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

module NicInfo

  class BinarySearchTree

    Node = Struct.new( :left, :right, :number, :data )

    def new_treenode( number, data )
      return Node.new( nil, nil, number, data )
    end

    def insert( node, number, data )
      if node == nil
        return new_treenode( number, data )
      else
        if number <= node.number
          node.left = insert( node.left, number, data )
        else
          node.right = insert( node.right, number, data )
        end
        return node
      end
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

    def size( node )
      if node == nil
        return 0
      else
        size = 1
        size = size + size( node.left )
        size = size + size( node.right )
        return size
      end
    end

    def each( node, &block )
      if node == nil
        return
      else
        each( node.left, &block )
        yield( node )
        each( node.right, &block )
      end
    end

  end

end
