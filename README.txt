100075
Usage:
key_manager = GameKeyManager.new filename: "frtt.pwd" # Loads login data from the filename provided. Alternate format: GameKeyManager.new username: "frtt", password: "flagreturn"
key_manager.renew_key # Logs into the website
key_manager.game_key # Gets the last saved key, if any. Otherwise, runs renew_key


