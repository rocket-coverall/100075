require './WebsiteLogin.rb'
class GameKeyManager

  def initialize param

    if param[:filename]
      File.open(param[:filename]) do |f|
        param[:username] = f.gets.strip
        param[:password] = f.gets
      end
    end

    if param[:username]&&param[:password]
      WebsiteLogin.set_login_data param[:username], param[:password]
    end

  end

  def game_key= param
    File.new("game_key", "w").write(param)
    @game_key = param
  end

  def load_key
    return false unless File.exist? "game_key"
    @game_key = File.open("game_key").gets()
  end

  def renew_key
    WebsiteLogin.authenticate
    self.game_key = WebsiteLogin.game_key
  end

  def game_key
    unless load_key
     renew_key
    end
    @game_key
  end

end
