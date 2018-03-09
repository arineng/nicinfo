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

  class NetNode

    attr_accessor :left, :right, :begin, :end, :data, :cidr_string, :ipaddr

    def initialize( cidr_string = nil, data = nil )
      @data = data
      if cidr_string
        @cidr_string = cidr_string
        @ipaddr = IPAddr.new( cidr_string )
        @begin = @ipaddr.to_range.begin.to_i
        @end = @ipaddr.to_range.end.to_i
      end
    end

    def include?( node )
      node.begin >= @begin && node.end <= @end
    end

    def contained_by?( node )
      node.begin <= @begin && node.end >= @end
    end

    def exactly_matches?( node )
      node.begin == @begin && node.end == @end
    end

    def overlaps?( node )
      ( node.begin >= @begin && node.end >= @end ) || ( node.begin <= @begin && node.end <= @end )
    end

    def right_of?( node )
      node.begin < @begin && node.end < @begin
    end

    def left_of?( node )
      node.begin > @end && node.end > @end
    end

    def to_s
      "#{@cidr_string}:#{@begin}-#{@end}"
    end

    def insert( node )
      if include?( node )
        if @left == nil
          @left = node
        elsif @left != nil
          if @left.exactly_matches?( node )
            if @left.data == nil && node.data != nil
              node.left = @left.left
              node.right = @left.right
              @left = node
            else
              raise "duplicate left node insertion. left: #{@left} node: #{node}"
            end
          elsif @left.contained_by?( node )
            node.insert( @left )
            @left = node
          elsif @left.include?( node )
            @left.insert( node )
          else
            if @right == nil
              @right = node
            elsif @right.exactly_matches?( node )
              if @right.data == nil && node.data != nil
                node.left = @right.left
                node.right = @right.right
                @right = node
              else
                raise "duplicate right node insertion. right: #{@right} node: #{node}"
              end
            elsif @right.contained_by?( node )
              node.insert( @right )
              @right = node
            elsif @right.include?( node )
              @right.insert( node )
            else
              inter = NetNode.new
              inter.begin = @left.begin > node.begin ? node.begin : @left.begin
              inter.end = @left.end < node.end ? node.end : @left.end
              inter.insert( @left )
              @left = inter
              inter.insert( node )
              if inter.include?( @right )
                inter.insert( @right )
                @right = nil
              end
            end
          end
        end
      else
        raise "insertion fit error. node: #{node} left: #{@left} right: #{@right}"
      end
    end

    def find( node )
      if @left != nil && @left.include?( node )
        return @left.find( node )
      elsif @right != nil && @right.include?( node )
        return @right.find( node )
      elsif include?( node )
        return self
      end
      #else
      return nil
    end

    def each
      yield( @data ) if @data
      @left.each if @left
      @right.each if @right
    end

    def print
      puts self
      puts "   left: #{@left}"
      puts "  right: #{@right}"
      puts "   data: #{@data}"
      @left.print if @left
      @right.print if @right
    end

    def print_pre
      puts self
      puts "   left: #{@left}"
      puts "  right: #{@right}"
      puts "   data: #{@data}"
      @left.print_pre if @left
      @right.print_pre if @right
    end

    def print_post
      puts self
      puts "   left: #{@left}"
      puts "  right: #{@right}"
      puts "   data: #{@data}"
      @left.print_post if @left
      @right.print_post if @right
    end

  end

  class NetTree

    attr_accessor :v4_root, :v6_root

    def initialize
      @v4_root = NicInfo::NetNode.new(  "0.0.0.0/0" )
      @v6_root = NicInfo::NetNode.new(  "::0/0" )
    end

    def find_by_ipaddr( ip )
      node = NicInfo::NetNode.new( ip )
      retval = nil
      found = nil
      if node.ipaddr.ipv4? && @v4_root
        found = @v4_root.find( node )
      else
        found = @v6_root.find( node )
      end
      if found && found.data
        retval = found.data
      end
      return retval
    end

    def insert( cidr_string, data )
      node = NicInfo::NetNode.new( cidr_string, data )
      if node.ipaddr.ipv4?
        @v4_root.insert( node )
      else
        @v6_root.insert( node )
      end
    end

    def each
      @v4_root.each if @v4_root
      @v6_root.each if @v6_root
    end

  end

end
