require "net/http"
require "uri"
require 'digest/md5'
require 'socket'

class WebsiteLogin
  @@user_name = " "
  @@password = " "
  @@private_key = "we are one team,fight together!"

  def self.set_login_data username, password
    @@user_name = username
    @@password = password
  end

  def self.login_data
    "Username='#{@@user_name}'\nPassword='#{@@password}'"
  end

  def self.game_key
    @@game_key
  end

  def self.signature
    Digest::MD5.hexdigest(@@user_name+@@password+@@private_key)
  end

  def self.access_token
    Digest::MD5.hexdigest(@@user_name+@@password+@@private_key+self.signature)
  end


  def self.extract_cookie source, name
    source.scan /#{name}=(.+?);/i
  end

  def self.parse_cookies string
    cookies = {}
    string.split("; ").each do |cookie|
        cookie_name, cookie_value = cookie.strip.split("=", 2)
        cookies[cookie_name] = cookie_value
    end
    cookies
  end

  def self.encode_cookies param
    result = ""
    param.each_pair {|pair| result += "#{pair[0].to_s}=#{pair[1].to_s}; "}
    result[0..result.length-3]
  end



  def self.http_request param

    uri = URI.parse(param[:page])

    get_params = if param[:get_params]
                  param[:get_params]
                 else
                   ""
                 end


    cookies = if param[:cookies]
                "\r\nCookie: #{self.encode_cookies(param[:cookies])}"
              else
                ""
              end

    method = if param[:method] == :post
          "POST"
        else
          "GET"
        end

    form_data = param[:form_data].collect {|k,v| "#{k}=#{v}"}.join("&") if param[:form_data]

    content_info = if param[:form_data]
          "\r\nContent-Length: #{form_data.length}\r\nContent-Type: application/x-www-form-urlencoded"
        else
          ""
        end


    headers = if param[:headers]
                param[:headers].each_pair {|pair| headers = (headers||"") + "#{pair[0].to_s}: #{pair[1].to_s}\r\n" }
              else
                ""
              end

    body = method+" #{uri.path+get_params} HTTP/1.1\r\nHost: #{uri.host}\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUser-Agent: Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11#{content_info}\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: en-US,en;q=0.8\r\n#{headers}Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3#{cookies}\r\n\r\n"

    body += form_data if param[:form_data]

    sock =TCPSocket.open(uri.host, 80)

    sock.puts body

    response = {}
    response[:headers] = {}
    response[:result] = sock.gets().strip
    response[:full] = ""
    response[:body] = ""
    response[:cookies] = {}


    while true do
      s = sock.gets()

      unless s=="\r\n"

        header_name, header_value = s.strip.split(": ", 2)
        response[:headers][header_name] = header_value
        response[:full] += s


        if header_name == "Set-Cookie"
          header_value =~ /(.+?)=(.+?);/
          cookie_name = $1
          cookie_value = $2
          response[:cookies][cookie_name] = cookie_value



        end

      else
        break
      end

    end

    if response[:headers]["Content-Length"]
      response[:body] += sock.getbyte.chr while response[:body].length <= response[:headers]["Content-Length"].to_i-1
    elsif response[:headers]["Content-Type"]
        s = sock.gets
        response_length = s.strip.to_i(16)
        response[:body] = ""
        while response[:body].length < response_length
          response[:body] += sock.gets
        end
        response[:body].chomp!
    end


    response

  end


  def self.authenticate param={}

    puts "Authentication stage 1, 'authority check'..." if param[:output] == :stdout

    auth_response = http_request :page => "http://www.swordgirlsonline.com/checkAuthority.do",
                                 :get_params => "?userName=#{@@user_name}&password=#{@@password}&accessToken=#{self.access_token}&singnature=#{self.signature}",
                                 :method => :get

    if auth_response[:body] != '{"exist":"true"}'
      raise "Authentication failed at step 1 (authority check)"
    end

    puts "Authentication stage 2, login request..."  if param[:output] == :stdout

    login_response = http_request :page => "http://www.swordgirlsonline.com/loginAct.do",
                                  :form_data => {"userName" => @@user_name, "password" => @@password, "__checkbox_isRememberMe" => "true", "redirectUrl" => "http://www.swordgirlsonline.com/"},
                                  :method => :post



    puts "Authentication stage 3, realm list..."  if param[:output] == :stdout


    http_request :page => "http://www.swordgirlsonline.com/gameStart.do",
                                       :method => :get,
                                       :cookies => {
                                           :cookieUserID => login_response[:cookies]["cookieUserID"],
                                           :cookieNickName => login_response[:cookies]["cookieNickName"],
                                           :changyouToken => login_response[:cookies]["changyouToken"]
                                       }


    puts "Authentication stage 4, game start..." if param[:output] == :stdout

    game_start_response = http_request :page => "http://www.swordgirlsonline.com/gameStart.do",
                                       :method => :post,
                                       :cookies => {
                                           :cookieUserID => login_response[:cookies]["cookieUserID"],
                                           :cookieNickName => login_response[:cookies]["cookieNickName"],
                                           :changyouToken => login_response[:cookies]["changyouToken"]
                                       },
                                       #:headers => {'Referer' => "http://www.swordgirlsonline.com/"},
                                       :form_data => {"channelId" => "5", "loginFrom" => ""}

    game_start_response[:body] =~ /password=(.+?)&locales/

    @@game_key = $1

    true if self.game_key

  end

end
