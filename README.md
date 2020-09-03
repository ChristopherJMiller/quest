# Quest

A discord bot to manage a [West Marches](https://www.youtube.com/watch?v=oGAC-gBoX9k) TTRPG playstyle.

# Developing

## Requirements

- [Elixir ~1.10](https://elixir-lang.org/install.html)
- A Container Engine and Compose Runner (We recommend [podman](https://podman.io/) with [podman-compose](https://github.com/containers/podman-compose))
- [A Discord Bot Token](https://discord.com/developers)

## Environment Setup

```
# Clone the repo
git clone ...
cd quest/

# Install Elixir Dependencies
mix deps.get

# Start Dev Database
podman-compose up -d

# Setup Dev Database
mix ecto.create
mix ecto.migrate

# Start Bot
TOKEN=<DISCORD_BOT_TOKEN> mix run --no-halt

# Or, run unit tests
mix test
```

# Contributing
Interested in contributing to Quest? We use [Github Issues](https://github.com/ChristopherJMiller/quest/issues) to track open feature requests and bugs. Feel free to make a PR for any open features and additions.