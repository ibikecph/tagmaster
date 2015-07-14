# Tagmaster

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tagmaster'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tagmaster

## Usage

Ruby tools for receiving data from TagMaster RFID tag readers. 

tagp
The script can be used a server, which:
- speaks the tagp protocol
- receives data from multiple reeaders
- logs events
- distributes events to a secondary server via a JSON api


scan
The script can be used to scan unique tag ids, which can be useful beofre distributing tags.
- speaks the tagp protocol
- receives data from multiple reeaders
- logs unique tag ids

## Contributing

1. Fork it ( https://github.com/[my-github-username]/tagmaster/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
