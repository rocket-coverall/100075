require "./GameConnection.rb"
require 'net/http'
require 'json'


def load_all_the_cards r, l
  puts "Attempting to load recipes for all the cards..."
  start

  count = l.length
  l.each_with_index do |id, index|
    card_id = id[0].to_i
    zombie if (index % 5 == 0)
    puts "Requesting recipe for card #{card_id.to_s} (#{(index+1).to_s}/#{count.to_s})..."
    card = recipe card_id
    r[card[:card]]=card[:recipe] if card
  end


end



def start
  $game = GameConnection.new
  $game.login filename: "frtt.pwd"
end

def recipe c
  r = $game.recipe c
  {card: r[:card_id], recipe: r[:cards]} if r[:result] == :success
end

def save_db c
  File.open("db/"+Time.now.strftime("%Y-%m-%d-%H%M%S")+"_recipes.json", "w") do |f|
    f.write(c.to_json)
  end
  File.open("db/recipes.json", "w") do |f|
    f.write(c.to_json)
  end
end

def load_db
  JSON.parse(File.read("db/recipe.yaml"))
end

def zombie
  $game.zombie
end



cards = {}
card_list = []

puts "Downloading card list..."

Net::HTTP.start("changyou-icdn.pandonetworks.com") do |http|
  resp = http.get("/changyou/downloads/SG/obt/OBT_Client/assets/maintenance/xml/en_cardData.xml")
  s = resp.body
  card_list = s.scan(/<RECIPE_NUMBER>(.*?)<\/RECIPE_NUMBER>/).uniq
end

puts "#{card_list.length} cards with recipe IDs found."

load_all_the_cards cards, card_list

save_db cards
