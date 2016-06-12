require('ipaddr')

def split_range(s, e, pfx)
  diff = e - s
  pfx += 1
  return [[s, s + diff / 2, pfx], [s + diff/2 + 1, e, pfx]]
end

def cidr_to_str(ip, mask, type)
  ip = IPAddr.new(ip, type)
  return "%s/%i" % [ip.to_s, mask]
end

def find_start_cidrs(r, start)
  s = r[0]
  e = r[1]
  pfx = r[2]
  p cidr_to_str(s, pfx, Socket::AF_INET)
  p cidr_to_str(e, pfx, Socket::AF_INET)
  if s >= start
    return [r]
  elsif start > e  
    return []
  else
    nr1, nr2 = split_range(s, e, pfx)
    return find_start_cidrs(nr1, start) + find_start_cidrs(nr2, start)
  end
end

def find_end_cidrs(r, end_val)
  s = r[0]
  e = r[1]
  pfx = r[2]
  if e <= end_val
    return [r]
  elsif end_val < s
    return []
  else
    nr1, nr2 = split_range(s, e, pfx)
    return find_end_cidrs(nr1, end_val) + find_end_cidrs(nr2, end_val)
  end
end  

def clean_ip(ip)
  return ip.split('.').map(&:to_i).join('.')
end

def find_cidrs(lower, upper)

  lower = clean_ip(lower)
  upper = clean_ip(upper)

  s = IPAddr.new lower
  e = IPAddr.new upper

  maxlen = 128
  type = Socket::AF_INET6
  if s.ipv4?
    maxlen = 32
    type = Socket::AF_INET
  end

  s = s.to_i
  e = e.to_i

  if s < e
    tmp = e
    e = s
    s = tmp
  end

  mask = e ^ s
  i = 0
  while mask != 0
    i += 1
    mask = mask >> 1
  end
  
  r_start = s - (s % 2**i)
  r_end = r_start + (2**i) - 1

  r1, r2 = split_range(r_start, r_end, maxlen - i)
  #require('pry')
  #binding.pry
  rs = find_start_cidrs(r1, s) + find_end_cidrs(r2, e)

  ret = []
  for r in rs
    ret.push(cidr_to_str(r[0], r[2], type))
  end
  return ret
end
