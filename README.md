# Capistrano Local Precompile

If your Rails apps are anything like mine, one of the slowest parts of your deployment is waiting for asset pipeline precompilation. It's sometimes so slow, it's painful. So I went searching for some solutions. [turbo-sprockets](https://github.com/ndbroadbent/turbo-sprockets-rails3) helped, but it's not a silver bullet.  This gem isn't a silver bullet either, but it can help.  Capistrano Local Precompile takes a different approach. It builds your assets locally and rsync's them to your web server(s).

## Usage

Add capistrano-local-precompile to your Gemfile:

```ruby
group :development do
  # Capistrano v2 should use '~> 0.0.5'
  # Capistrano v3 should use '~> 1.0.0'
  # Capistrano v3.8+ should use '~> 1.1.3'
  gem 'capistrano-local-precompile', '~> 1.1.3', require: false
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

During local Shakapacker compilation, the gem generates a temporary copy of
`config/shakapacker.yml` and maps the local Rails environment's configuration
section to `precompile_env`. It passes that copy with `SHAKAPACKER_CONFIG` and
removes it after compilation. This lets `NODE_ENV=production` use the
production Shakapacker configuration while Rails continues to run locally in
development.

Here's the full set of configurable options:

```ruby
set :precompile_env                    # default: "production"
set :shakapacker_config                # default: "config/shakapacker.yml"
set :shakapacker_config_environment    # default: "development"
set :packs_dir                         # default: "public/packs"
set :rsync_cmd                         # default: "rsync -av --delete"
set :assets_role                       # default: "web"
```

Set `shakapacker_config_environment` to the Rails environment used by the
local command when it is not `development`.

## Acknowledgement

This gem is derived from gists by [uhlenbrock][] and [keighl][].

[uhlenbrock]: https://gist.github.com/uhlenbrock/1477596
[keighl]: https://gist.github.com/keighl/4338134

## Contributing

Pull requests welcome: fork, make a topic branch, commit (squash when possible) *with tests* and I'll happily consider.

## Copyright

Copyright (c) 2017 Steve Agalloco / Tom Caflisch. See [LICENSE](LICENSE.md) for detail
