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

  class NetNode

    attr_accessor :left, :right, :begin, :end, :data

    def initialize( ipaddr = nil, data = nil )
      @data = data
      if ipaddr
        @begin = ipaddr.to_range.begin.to_i
        @end = ipaddr.to_range.end.to_i
      end
    end

    def include?( node )
      node.begin >= @begin && node.end <= @end
    end

    def contained_by?( node )
      node.begin <= @begin && node.end >= @end
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
      "#{@begin}-#{@end}"
    end

    def insert( node )
      if include?( node )
        if @left == nil
          #puts "new left"
          @left = node
        elsif @left != nil && @left.contained_by?( node )
          #puts "replacing left"
          node.insert( @left )
          @left = node
        elsif @left != nil && @left.include?( node )
          #puts "inserting left"
          @left.insert( node )
        elsif @right != nil && @right.contained_by?( node )
          #puts "replacing right"
          node.insert( @right )
          @right = node
        elsif @right != nil && @right.include?( node )
          #puts "inserting right"
          @right.insert( node )
        elsif @left != nil && @right == nil && @left.right_of?( node )
          #puts "swapping left to right"
          @right = @left
          @left = node
        elsif @left != nil && @right == nil && @left.left_of?( node )
          #puts "new right"
          @right = node
        elsif @left != nil && @right !=nil && @left.left_of?( node ) && @right.right_of?( node )
          #puts "new middle"
          inter = NetNode.new
          inter.begin = @left.begin
          inter.end = @right.end
          inter.left = @left
          inter.right = @right
          @left = inter
          @right = nil
        elsif @left != nil && @right != nil && @left.overlaps?( node ) && @right.overlaps?( node )
          #puts "new center overlap"
          inter = NetNode.new
          inter.begin = @left.begin > node.begin ? node.begin : @left.begin
          inter.end = @right.end < node.end ? node.end : @right.end
          inter.left = @left
          inter.right = @right
          @left = inter
          @right = nil
        elsif @left != nil && @left.overlaps?( node )
          #puts "new left overlap"
          inter = NetNode.new
          inter.begin = @left.begin > node.begin ? node.begin : @left.begin
          inter.end = @left.end < node.end ? node.end : @left.end
          inter.left = @left
          inter.right = nil
          @left = inter
        elsif @right != nil && @right.overlaps?( node )
          #puts "new right overlap"
          inter = NetNode.new
          inter.begin = @right.begin > node.begin ? node.begin : @right.begin
          inter.end = @right.end < node.end ? node.end : @right.end
          inter.left = @right
          inter.right = nil
          @right = inter
        else
          raise "insertion error. node: #{node} left: #{@left} right: #{@right}"
        end
      else
        raise "inserting into node that cannot fit new node"
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

  end

  class NetTree

    attr_accessor :v4_root, :v6_root

    def initialize
      @v4_root = NicInfo::NetNode.new( IPAddr.new( "0.0.0.0/0" ) )
      @v6_root = NicInfo::NetNode.new( IPAddr.new( "::0/0" ) )
    end

    def find_by_ipaddr( ipaddr )
      node = NicInfo::NetNode.new( ipaddr )
      retval = nil
      found = nil
      if ipaddr.ipv4? && @v4_root
        found = @v4_root.find( node )
      else
        found = @v6_root.find( node )
      end
      if found && found.data
        retval = found.data
      end
      return retval
    end

    def insert( ipaddr, data )
      node = NicInfo::NetNode.new( ipaddr, data )
      if ipaddr.ipv4?
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
