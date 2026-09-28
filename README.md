# Capistrano Local Precompile

If your Rails apps are anything like mine, one of the slowest parts of your deployment is waiting for asset pipeline precompilation. It's sometimes so slow, it's painful. So I went searching for some solutions. [turbo-sprockets](https://github.com/ndbroadbent/turbo-sprockets-rails3) helped, but it's not a silver bullet.  This gem isn't a silver bullet either, but it can help.  Capistrano Local Precompile takes a different approach. It builds your assets locally and rsync's them to your web server(s).

## Usage

Add capistrano-local-precompile to your Gemfile:

```ruby
group :development do
  gem 'capistrano-local-precompile', '~> 1.1.8', require: false
end
```

Then add the following line to your `Capfile`:

```ruby
require 'capistrano/local_precompile'
```

Remove the following line from your `Capfile`:

```ruby
require 'capistrano/rails/assets'
```

Here's the full set of configurable options:

```ruby
set :precompile_env                    # default: "development"
set :node_env                          # default: "production"
set :assets_dir                         # default: "public/assets"
set :assets_pipeline_enabled            # default: false
set :shakapacker_enabled                # default: true
set :shakapacker_config                # default: "config/shakapacker.yml"
set :packs_dir                         # default: "public/packs"
set :rsync_cmd                         # default: "rsync -av --delete"
set :assets_role                       # default: "web"
```

## Acknowledgement

This gem is derived from gists by [uhlenbrock][] and [keighl][].

[uhlenbrock]: https://gist.github.com/uhlenbrock/1477596
[keighl]: https://gist.github.com/keighl/4338134

## Contributing

Pull requests welcome: fork, make a topic branch, commit (squash when possible) *with tests* and I'll happily consider.

## Copyright

Copyright (c) 2017 Steve Agalloco / Tom Caflisch. See [LICENSE](LICENSE.md) for detail
