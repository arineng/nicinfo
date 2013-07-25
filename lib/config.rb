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
require 'nicinfo_logger'
require 'yaml'
require 'ostruct'
require 'constants'

module NicInfo

  # Handles configuration of the application
  class Config

    attr_accessor :logger, :config, :rdap_cache_dir, :options

    # Intializes the configuration with a place to look for the config file
    # If the file doesn't exist, a default is used.
    # Main routines will do something like NicInfo::Config.new( NicInfo::Config.formulate_app_data_dir() )
    def initialize app_data

      @options = OpenStruct.new
      @app_data = app_data
      @logger = NicInfo::Logger.new

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

        @rdap_cache_dir = File.join( @app_data, "rdap_cache" )
        Dir.mkdir( @rdap_cache_dir )

      else

        if @options.reset_config
          config_file_name = Config.formulate_config_file_name( @app_data )
          @logger.trace "Resetting configuration in " + config_file_name
          f = File.open( config_file_name, "w" )
          f.puts @@yaml_config
          f.close
          @config = YAML.load( File.open( config_file_name ) )
        end
        @logger.trace "Using configuration found in " + @app_data
        @rdap_cache_dir = File.join( @app_data, "rdap_cache" )

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
      output = @config[ NicInfo::OUTPUT ]
      return if output == nil

      @logger.message_level = output[ NicInfo::MESSAGES ]
      @logger.validate_message_level

      messages_file = output[ NicInfo::MESSAGES_FILE ]
      if messages_file != nil
        @logger.message_out = File.open( messages_file, "w+" )
      end

      @logger.data_amount = output[ NicInfo::DATA ]
      @logger.validate_data_amount

      data_file = output[ NicInfo::DATA_FILE ]
      if data_file != nil
        @logger.data_out= File.open( data_file, "w+" )
      end

      @logger.pager=output[ NicInfo::PAGER ]
      @logger.auto_wrap=output[ NicInfo::AUTO_WRAP ]
      @logger.default_width=output[ NicInfo::DEFAULT_WIDTH ]
      @logger.detect_width=output[ NicInfo::DETECT_WIDTH ]
    end

    def self.clean

      FileUtils::rm_r( formulate_app_data_dir() )

    end

    def self.formulate_app_data_dir
      if RUBY_PLATFORM =~ /win32/
        data_dir = File.join(ENV['APPDATA'], "NicInfo")
      elsif RUBY_PLATFORM =~ /linux/
        data_dir = File.join(ENV['HOME'], ".NicInfo")
      elsif RUBY_PLATFORM =~ /darwin/
        data_dir = File.join(ENV['HOME'], ".NicInfo")
      elsif RUBY_PLATFORM =~ /freebsd/
        data_dir = File.join(ENV['HOME'], ".NicInfo")
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
  #messages_file: /tmp/NicInfo.messages

  # possible values are TERSE, NORMAL, EXTRA
  data: NORMAL

  # If specified, data goest to this file
  # otherwise, leave it commented out to go to stdout
  #data_file: /tmp/NicInfo.data

  # Page output with system pager when appropriate.
  pager: true

  # Automatically wrap text when possible.
  auto_wrap: true

  # When auto wrapping, automatically determine the terminal
  # width if possible
  detect_width: true

  # The default terminal width if it is not to be detected
  # or cannot be detected
  default_width: 80

cache:

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

bootstrap:

  #base_url: http://rdappilot.arin.net/rdapbootstrap

  entity_root_url: http://rdappilot.arin.net/rdapbootstrap

  ip_root_url: http://rdappilot.arin.net/rdapbootstrap

  as_root_url: http://rdappilot.arin.net/rdapbootstrap

  domain_root_url: http://rdappilot.arin.net/rdapbootstrap

  ns_root_url: http://rdappilot.arin.net/rdapbootstrap

  arin_url: http://rdappilot.arin.net/restfulwhois/rdap

  ripe_url: http://whois.ripe.net

  lacnic_url: http://restfulwhoisv2.labs.lacnic.net/rdap

  apnic_url: http://testwhois.apnic.net

  afrinic_url: http://whois.afrinic.net

  com_url: http://whois.verisign.net

  net_url: http://whois.verisign.net

  org_url: http://whois.pir.org

  info_url: http://rdg.afilias.info/rdap

  biz_url: http://whois.neustar.biz

  cn_url: http://rdap.restfulwhois.org

search:

  # Substring matching
  # NOT YET USED
  substring: true

YAML_CONFIG

  end

end
