require "GameKeyManager"

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
    @game.wait_and_read :recipe # acquire parsed crafting packet
  end

end

class GameClient # class that handles actual game server interaction and packet parsing
  def initialize
    # TODO: socket connect
    server = ""
  end

  def login_request nick, password

    packet = GamePacket.new :type => :login # prepare login packet
    packet.add_utf8 nick
    packet.add_utf8 password

    send_packet :login, packet
    page_response = wait_and_read :login
    raise "FATAL ERROR: PAGE SERVER LOGIN FAILED" unless page_response[:result] == :success

    send_packet :market, packet
    market_response = wait_and_read :login
    raise "FATAL ERROR: MARKET SERVER LOGIN FAILED" unless market_response[:result] == :success

    page_response[:misc_data] # see THE SWORD GIRLS PROTOCOL p.3

  end

  def recipe_request card_number
    packet = GamePacket.new :type => :recipe
    packet.add_long card_number
    send_packet :market, packet
  end

  def wait_and_read type
    while receive_packet[:type] != type do
      puts "Waiting for packet of type #{type}..."
    end
  end


end
