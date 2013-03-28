require "./GameKeyManager.rb"
require "./GamePacket.rb"

class GameConnection

  def initialize
    @game = GameClient.new
  end


  def login param
    @key_manager = GameKeyManager.new param
    @key = @key_manager.game_key :force
    @game.login_request @key_manager.username, @key
  end

  def recipe card_number
    @game.recipe_request card_number
    @game.wait_and_read :login, :recipe # acquire parsed crafting packet
  end

  def zombie
    @game.zombie_request :login
  end

end





class GameClient # class that handles actual game server interaction and packet parsing

  def initialize
    @sockets = {}
    @type_codes = {
        login: {login: 6, zombie: 5, recipe: 92},
        market: {login: 50, zombie: 5, recipe: 60}
    }
    server_connect :login, page_ip, page_port
  end

  def page_ip
    "74.201.81.93"
  end

  def market_ip
    "74.201.81.93"
  end

  def page_port
    18511
  end

  def market_port
    18516
  end

  def server_connect server, ip, port
    puts "connecting to #{server}"
    @sockets[server] = TCPSocket.open ip, port
  end

  def get_socket server
    @sockets[server]
  end

  def get_type_code server, type_hash

    @type_codes[server][type_hash]
  end

  def get_type_hash server, type_code
    @type_codes[server].key type_code
  end

  def login_request nick, password

    packet = GamePacket.new :type => :login # prepare login packet
    packet.add_utf8 nick
    packet.add_utf8 password

    send_packet :login, packet
    page_response = wait_and_read :login, :login
    raise "FATAL ERROR: PAGE SERVER LOGIN FAILED" unless page_response[:result] == :success

    zombie_request :login

    page_response[:misc_data] # see THE SWORD GIRLS PROTOCOL p.3

  end

  def zombie_request server
    packet = GamePacket.new :type => :zombie
    packet.add_byte 0
    packet.add_byte 100
    send_packet server, packet
  end

  def recipe_request card_number
    packet = GamePacket.new :type => :recipe
    packet.add_long card_number
    send_packet :login, packet
  end

  def wait_and_read server, type

    pack = receive_packet server

    while pack[:type] != type do          # receive packets until one of the required type arrives
      puts "Waiting for packet of type #{type}..."
      pack = receive_packet server
    end

    pack

  end

  def receive_packet server  # waits for the next incoming packet on the specified server socket, then reads and parses the packet

    sock = get_socket server
    raise "FATAL ERROR: CANNOT READ PACK FROM '#{server}' SERVER - NO CONNECTION" unless sock
    size_buffer = sock.recv 2                            # read two bytes from the stream
    size = (size_buffer[0].ord*256+size_buffer[1].ord)-2 # subtract the two bytes from the size to acquire the rest of the packet's size
    body = sock.recv size                                # receive size bytes

    puts "Acquired packet of size #{size.to_s}"
    puts "Packet body:"
    p body

    packet_stream = ServerPacket.new body, server                # create the almost-stream object to read the data from

    parse_packet packet_stream, server

  end

  def parse_packet source, server
    type_code = source.read_int
    puts "type code:"
    puts type_code
    type = get_type_hash server, type_code
    source.forward 3  # skip to the end of the packet header

    case type
      when :login
        pack = parse_login_packet source, server
      when :recipe
        pack = parse_recipe_packet source
      when :zombie
        pack = parse_zombie_packet source, server
      else
        puts "UNIDENTIFIED PACKET OF TYPE #{type_code.to_s} FROM '#{server}' SERVER"
        pack = {}
    end

    pack

  end

  def parse_login_packet source, server

    pack = {}

    pack[:type] = :login
    pack[:server] = server
    pack[:size] = source.size+2
    pack[:source] = source
    pack[:result_code] = source.read_byte
    pack[:result] = :success if pack[:result_code]==0

    pack

  end

  def parse_recipe_packet source
    pack = {type: :recipe}

    pack[:source] = source

    pack[:result_code] = source.read_byte
    pack[:card_id] = source.read_long

    pack[:result] = :success if pack[:result_code]==0
    unless pack[:result] == :success
      puts "No recipe for card #{pack[:card_id].to_s}"
      return pack
    end



    pack[:num_cards] = source.read_long
    pack[:cards] = []

    puts "Received recipe for card #{pack[:card_id].to_s}"


    (1..pack[:num_cards]).each do
      pack[:cards] << {id: source.read_long, count: source.read_long}
      #puts "#{pack[:cards].last[:count]}x#{pack[:cards].last[:id]}"
    end



    pack

  end

  def parse_zombie_packet source, server
    {type: :zombie, source: source, server: server}
  end


  def send_packet server, packet
    type = get_type_code server, packet.type  # convert packet type to server-specific type identifier
    puts "sending packet of type #{packet.type}"
    str = packet.to_s type          # acquire the complete packet string
    sock = get_socket server
    raise "FATAL ERROR: CANNOT SEND PACK TO '#{server}' SERVER - NO CONNECTION" unless sock
    sock.send str, 0
  end


end
