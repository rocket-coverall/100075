*100075*
Usage of the game key generator:
```ruby
key_manager = GameKeyManager.new filename: "frtt.pwd" 
key_manager.game_key
```
This will attempt to read the last saved key.
If no key is saved, a new one is requested using the account credentials in frtt.pwd

The password file should contain username and password, separated by a single newline character.

To force a new key:
```ruby
key_manager.game_key :force
```

This will overwrite the existing key file.
