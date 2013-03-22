require "GameKeyManager"

class GameConnection

  def login param
    key_manager = GameKeyManager.new param
    @key = key_manager.game_key :force
  end

  def request_recipe card_number
    card_number
  end

end



