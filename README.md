# StringDiff

StringDiff is a gem that compares one string to another. If insertions or deletions are made, a corresponding style is added to that difference.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'string_diff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install string_diff

## Usage


string_1 = "hello world"
string_2 ="hello beautiful world"
StringDiff::Diff.new(string_1, string_2).diff
# => "hello <span class='insertion'>beautiful</span> world"

string_1 = "hello world"
string_2 = "hello"
StringDiff::Diff.new(string_1, string_2).diff
# => "hello <span class='deletion'>world</span>"


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/string_diff. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

