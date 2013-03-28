require "./WebsiteLogin.rb"
class GameKeyManager

  attr_reader :username

  def initialize param

    if param[:filename]
      File.open(param[:filename]) do |f|
        param[:username] = f.gets.strip
        param[:password] = f.gets.strip
      end
    end

    if param[:username]&&param[:password]
      @username = param[:username]
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

  def game_key mode=:normal

    renew_key if (mode == :force)||(!load_key)

    @game_key

  end

end
