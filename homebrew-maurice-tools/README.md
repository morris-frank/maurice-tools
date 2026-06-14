# morris-frank/maurice-tools Homebrew Tap

This is the official Homebrew tap for Maurice Tools.

## Installation

```bash
brew tap morris-frank/maurice-tools
brew install maurice-tools
```

## Quick Start

After installation, run the setup command:

```bash
maurice setup
```

This will:
- Check and install dependencies
- Create configuration directory
- Install Finder Quick Actions
- Prompt for API keys (stored in macOS Keychain)
- Run diagnostics

## Available Tools

| Tool | Description |
|------|-------------|
| `maurice` | Main dispatcher for all commands |
| `transcribe-audio` | Direct audio transcription entrypoint |

## Documentation

See the [main repository](https://github.com/morris-frank/maurice-tools) for full documentation.
