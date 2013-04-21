# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
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


require 'yaml'
require 'arinr_logger'

module ARINcli

  class DataNode

    attr_accessor :alert, :handle, :rest_ref, :data, :children

    def initialize name, handle = nil, rest_ref = nil, data = nil
      @name = name
      @children = []
      @data = data
      @handle = handle
      @rest_ref = rest_ref
    end

    def add_child node
      @children << node if node
    end

    def to_s
      @name
    end

    def empty?
      @children.empty?
    end

    def <=> x
      @name <=> x.to_s
    end

    def has_meta_info
      return true if @handle
      return true if @rest_ref
      return true if @data
      return false
    end

  end

  class DataTree

    def initialize
      @roots = []
    end

    def add_root node
      @roots << node if node
    end

    def add_children_as_root node
      node.children.each do |child|
        add_root( child )
      end if node
    end

    def roots
      @roots
    end

    def empty?
      @roots.empty?
    end

    def find_data data_address
      node = find_node data_address
      return node.data if node
      return nil
    end

    def find_handle data_address
      node = find_node data_address
      return node.handle if node
      return nil
    end

    def find_rest_ref data_address
      node = find_node data_address
      return node.rest_ref if node
      return nil
    end

    def find_node data_address
      node = ARINcli::DataNode.new( "fakeroot" )
      node.children=roots
      data_address.split( /\D/ ).each do |index_str|
        index = index_str.to_i - 1
        node = node.children[ index ] if node
      end
      if node != nil
        return node
      end
      #else
      return nil
    end

    def to_terse_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::TERSE_DATA
      to_log( annotate )
    end

    def to_normal_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::NORMAL_DATA
      to_log( annotate )
    end

    def to_extra_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::EXTRA_DATA
      to_log( annotate )
    end

    private

    def to_log annotate
      retval = false
      double_space_roots = false
      @roots.each do |root|
        double_space_roots = true unless root.children.empty?
      end
      num_count = 1
      @logger.start_data_item unless double_space_roots
      @roots.each do |root|
        @logger.start_data_item if double_space_roots
        if annotate
          if root.alert
            s = format( "   # %s", root.to_s )
          elsif root.has_meta_info
            s = format( "%3d= %s", num_count, root.to_s )
          else
            s = format( "%3d. %s", num_count, root.to_s )
          end
        else
          s = root.to_s
        end
        retval = @logger.log_tree_item( @data_amount, s )
        if annotate
          prefix = " "
          child_num = 1
        else
          prefix = ""
          child_num = 0
        end
        root.children.each do |child|
          rprint( child_num, root, child, prefix )
          child_num += 1 if child_num > 0
        end if root.children() != nil
        num_count += 1
        @logger.end_data_item if double_space_roots
      end
      @logger.end_data_item unless double_space_roots
      return retval
    end

    def rprint( num, parent, node, prefix )
      if( num > 0 )
        spacer = "    "
        if node.alert
          num_str = format( " # ", num )
        elsif node.has_meta_info
          num_str = format( " %d= ", num )
        else
          num_str = format( " %d. ", num )
        end
        num_str = num_str.rjust( 7, "-" )
        child_num = 1
      else
        spacer = "  "
        num_str = "- "
        child_num = 0
      end
      prefix = prefix.tr( "`", " ") + spacer + ( node == parent.children.last ? "`" : "|" )
      @logger.log_tree_item( @data_amount, prefix + num_str + node.to_s )
      node.children.each do |child|
        rprint( child_num, node, child, prefix )
        child_num += 1 if child_num > 0
      end if node.children() != nil
    end

  end

end
