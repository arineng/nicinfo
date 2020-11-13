# Copyright (C) 2009 Original Author Unknown
# Copyright (C) 2016 American Registry for Internet Numbers
# Adopted from https://code.google.com/archive/p/rubyroute/
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
# conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
# of conditions and the following disclaimer in the documentation and/or other materials
# provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to
# endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


require 'timeout'
require 'socket'
require 'nicinfo/config'
require 'nicinfo/nicinfo_logger'

module NicInfo

  def NicInfo.random_port
    1024 + rand(64511)
  end

  def NicInfo.traceroute host, config
    ips = Array.new

    begin
      myname = Socket.gethostname
    rescue SocketError => err_msg
      config.logger.mesg "Can't get my own host name (#{err_msg})."
      exit 1
    end

    config.logger.mesg "Tracing route to #{host}"

    ttl                     = 1
    max_ttl                 = 255
    max_contiguaous_timeout = 16
    localport               = random_port
    dgram_sock              = UDPSocket::new

    begin
      dgram_sock.bind( myname, localport )
    rescue
      localport = random_port
      retry
    end

    begin
      icmp_sock     = Socket.open( Socket::PF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP )
      icmp_sockaddr = Socket.pack_sockaddr_in( localport, myname )
      icmp_sock.bind( icmp_sockaddr )
    rescue SystemCallError => socket_error
      config.logger.mesg "Error with ICMP socket. You probably need to be root: #{socket_error}"
      exit 1
    end


    begin
      dgram_sock.connect( host, 999 )
    rescue SocketError => err_msg
      config.logger.mesg "Can't connect to remote host (#{err_msg})."
      exit 1
    end

    stop_tracing = false
    continguous_timeout = 0
    until stop_tracing
      dgram_sock.setsockopt( 0, Socket::IP_TTL, ttl )
      dgram_sock.send( "RubyRoute says hello!", 0 )

      begin
        Timeout::timeout( 1 ) {
          data, sender = icmp_sock.recvfrom( 8192 )
          # 20th and 21th bytes of IP+ICMP datagram carry the ICMP type and code resp.
          icmp_type = data.unpack( '@20C' )[0]
          icmp_code = data.unpack( '@21C' )[0]
          # Extract the ICMP sender from response.
          ip = Socket.unpack_sockaddr_in( sender )[1].to_s
          ips << ip
          config.logger.mesg "TTL = #{ttl}:  " + ip
          continguous_timeout = 0
          if ( icmp_type == 3 and icmp_code == 13 )
            config.logger.mesg "'Communication Administratively Prohibited' from this hop."
            # ICMP 3/3 is port unreachable and usually means that we've hit the target.
          elsif ( icmp_type == 3 and icmp_code == 3 )
            config.logger.mesg "Destination reached. Trace complete."
            stop_tracing = true
          end
        }
      rescue Timeout::Error
        config.logger.mesg "Timeout error with TTL = #{ttl}!"
        continguous_timeout += 1
      end

      ttl += 1
      stop_tracing = true if ttl > max_ttl
      if continguous_timeout > max_contiguaous_timeout
        stop_tracing = true
        config.logger.mesg "Getting a lot of contiguous timeouts. Prematurely terminating trace."
      end
    end

    ips
  end

end


