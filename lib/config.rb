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


require 'fileutils'
require 'arinr_logger'
require 'yaml'
require 'ostruct'

module ARINcli

  # Handles configuration of the application
  class Config

    attr_accessor :logger, :config, :whois_cache_dir, :options, :tickets_dir

    # Intializes the configuration with a place to look for the config file
    # If the file doesn't exist, a default is used.
    # Main routines will do something like ARINcli::Config.new( ARINcli::Config.formulate_app_data_dir() )
    def initialize app_data

      @options = OpenStruct.new
      @app_data = app_data
      @logger = ARINcli::Logger.new

      config_file_name = Config.formulate_config_file_name( @app_data )
      if File.exist?( config_file_name )
        @config = YAML.load( File.open( config_file_name ) )
      else
        @config = YAML.load( @@yaml_config )
      end

      configure_logger()
    end

    # Setups work space for the application and lays down default config
    # If directory is nil, then it uses its own value
    def setup_workspace

      if ! File.exist?( @app_data )

        @logger.trace "Creating configuration in " + @app_data
        Dir.mkdir( @app_data )
        f = File.open( Config.formulate_config_file_name( @app_data ), "w" )
        f.puts @@yaml_config
        f.close

        @whois_cache_dir = File.join( @app_data, "whois_cache" )
        Dir.mkdir( @whois_cache_dir )

        @tickets_dir = File.join( @app_data, "tickets" )
        Dir.mkdir( @tickets_dir )

      else

        @logger.trace "Using configuration found in " + @app_data
        @whois_cache_dir = File.join( @app_data, "whois_cache" )
        @tickets_dir = File.join( @app_data, "tickets" )

      end

    end


    def save name, data
      data_file = File.open( File.join( @app_data, name ), "w" )
      data_file.write data
      data_file.close
    end

    def save_as_yaml name, obj
      data_file = File.open( File.join( @app_data, name ), "w" )
      data_file.puts YAML::dump(obj)
      data_file.close
    end

    def load name
      data_file = File.open( File.join( @app_data, name ), "r" )
      retval = data_file.read
      data_file.close
      return retval
    end

    def load_as_yaml name, default = nil
      file_name = make_file_name( name )
      retval = default
      if File.exists?( file_name )
        data_file = File.open( File.join( @app_data, name ), "r" )
        retval = YAML::load( data_file )
        data_file.close
      elsif default == nil
        raise "#{file_name} does not exist"
      end
      return retval
    end

    def make_file_name name
      File.join( @app_data, name )
    end

    # Configures the logger
    def configure_logger
      output = @config[ "output" ]
      return if output == nil

      @logger.message_level = output[ "messages" ]
      @logger.validate_message_level

      messages_file = output[ "messages_file" ]
      if messages_file != nil
        @logger.message_out = File.open( messages_file, "w+" )
      end

      @logger.data_amount = output[ "data" ]
      @logger.validate_data_amount

      data_file = output[ "data_file" ]
      if data_file != nil
        @logger.data_out= File.open( data_file, "w+" )
      end

      @logger.pager=output[ "pager" ]
    end

    def self.clean

      FileUtils::rm_r( formulate_app_data_dir() )

    end

    def self.formulate_app_data_dir
      if RUBY_PLATFORM =~ /win32/
        data_dir = File.join(ENV['APPDATA'], "ARINcli")
      elsif RUBY_PLATFORM =~ /linux/
        data_dir = File.join(ENV['HOME'], ".ARINcli")
      elsif RUBY_PLATFORM =~ /darwin/
        data_dir = File.join(ENV['HOME'], ".ARINcli")
      elsif RUBY_PLATFORM =~ /freebsd/
        data_dir = File.join(ENV['HOME'], ".ARINcli")
      else
        raise ScriptError, "system platform is not recognized."
      end
      return data_dir
    end

    def self.formulate_config_file_name data_dir
      File.join( data_dir, "config.yaml" )
    end

    @@yaml_config = <<YAML_CONFIG
output:

  # possible values are NONE, SOME, ALL
  messages: SOME

  # If specified, messages goes to this file
  # otherwise, leave it commented out to go to stderr
  #messages_file: /tmp/ARINcli.messages

  # possible values are TERSE, NORMAL, EXTRA
  data: NORMAL

  # If specified, data goest to this file
  # otherwise, leave it commented out to go to stdout
  #data_file: /tmp/ARINcli.data

  # Page output with system pager when appropriate.
  pager: true

  # Automatically wrap text when possible.
  # Comment out to disable auto-wrapping.
  auto_wrap: 80

whois:

  # the base URL for the Whois-RWS service
  url: http://whois.arin.net

  # The maximum age an item from the cache will be used.
  # This value is in seconds
  cache_expiry: 3600

  # The maximum age an item will be in the cache before it is evicted
  # when the cache is cleaned.
  # This value is in seconds
  cache_eviction: 604800

  # Use the cache.
  # Values are true or false
  use_cache: true

  # Automatically clean the cache.
  clean_cache: true

  # Use PFT style queries where appropriate
  pft: true

  # Query for extra details
  details: false

  # CIDR query matching
  # values are EXACT, LESS, and MORE
  cidr: LESS

  # Substring matching
  substring: true

registration:

  # The API-KEY to use for Reg-RWS requests
  apikey: API-1234-5678-9012-3456

  # the base URL for the Reg-RWS service
  url: https://reg.arin.net

  # The editor to use for editing values.
  # If left blank, an attempt will be used to find a system default
  # editor: vi
YAML_CONFIG

  end

end
