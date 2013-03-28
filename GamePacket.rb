class GamePacket  # class for outgoing game packets

  def initialize param = {}
    @type = param[:type]
    @body = ""
  end

  def type
    @type
  end

  def add_utf8 param
    @body += [param.length].pack('n')+param
  end

  def add_long param
    @body += [param].pack('N')
  end

  def add_byte param
    @body += [param].pack('n')
  end

  def to_s type
    head = [size,type,0,0,0].pack('nnccc')
    head+@body
  end

  def size
    @body.length + 7
  end

end

class ServerPacket   # class for incoming game packets. it is actually just a stream, but fuck that

  attr_accessor :cursor, :server

  def initialize str, server
    @data = str
    @server = server
    reset
  end

  def unp a,b           # i honestly don't remember how this works, nor do i want to figure it out again
    r = 0
    @sic = @data
    (a..b).each {|i| r+=@sic[i].ord*(256**(b-i)) }
    r
  end

  def reset
    @cursor = 0
  end

  def forward bytes
    @cursor += bytes
  end

  def size
    @data.length
  end

  def read_byte

    return false unless size >= cursor

    @cursor += 1
    @data[@cursor-1].ord

  end

  def read_long

    return false unless size >= cursor+3

    cursor += 4
    unp cursor-4, cursor-1

  end

  def type
    unp 0,1
  end

  def read_int

    return false unless size >= cursor+1

    cursor += 2
    unp cursor-2, cursor-1

  end

  def read_utf8
    len = read_byte
    return false unless size >= cursor+size
    cursor += len
    @data[cursor-len .. cursor-1]
  end

end