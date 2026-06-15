# Maurice Tools

A macOS CLI suite for audio transcription using OpenAI's API, distributed via Homebrew.

## Features

- **Large file support**: Automatically chunks audio files exceeding OpenAI's 25MB limit
- **High accuracy**: Uses OpenAI's gpt-4o-transcribe model
- **Secure**: API keys stored in macOS Keychain
- **Integrated**: Finder Quick Actions for one-click transcription
- **Fast**: Pure bash implementation using curl

## Installation

### Via Homebrew (Recommended)

```bash
brew tap morris-frank/maurice-tools
brew install maurice-tools
maurice setup
```

### Via Install Script

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/morris-frank/maurice-tools/main/install.sh)"
```

## Quick Start

```bash
# Check system health
maurice doctor

# Configure your OpenAI API key
maurice secret set openai

# Transcribe an audio file
maurice transcribe ~/Downloads/recording.m4a

# Or use the direct command
transcribe-audio ~/Downloads/recording.m4a
```

## Commands

| Command | Description |
|---------|-------------|
| `maurice setup` | Bootstrap installation and configure API keys |
| `maurice doctor` | Check system health and configuration |
| `maurice update` | Update to the latest version |
| `maurice secret set openai` | Store your OpenAI API key in macOS Keychain |
| `maurice secret get openai` | Retrieve your API key (for scripts) |
| `maurice transcribe <file>` | Transcribe audio to text |
| `maurice version` | Show version information |
| `maurice help` | Show help message |

## Configuration

Configuration is stored in `~/.config/maurice-tools/config.toml`:

```toml
[transcription]
default_language = "en"
output_dir = "~/Transcriptions"
overwrite_policy = "prompt"  # Options: prompt, always, never
```

## API Key

Maurice Tools stores your OpenAI API key securely in the macOS Keychain under the service name `maurice.openai.api_key`.

To set your API key:

```bash
maurice secret set openai
```

You can get an API key from [OpenAI's platform](https://platform.openai.com/api-keys).

## Finder Quick Actions

After running `maurice setup`, you can transcribe audio files directly from Finder:

1. Right-click on an audio file
2. Select "Quick Actions" → "Transcribe Audio"
3. The transcription will be saved as a `.txt` file next to the original

## Audio Formats

Supported formats (via ffmpeg):
- M4A (iPhone Voice Memos)
- MP3
- WAV
- MP4 / MOV (extracts audio)
- AAC
- FLAC
- WebM

## Requirements

- macOS 12.0 or later
- Homebrew
- ffmpeg
- jq
- OpenAI API key

## Project Structure

```
maurice-tools/
├── bin/
│   ├── maurice              # Main dispatcher
│   └── transcribe-audio     # Direct entrypoint
├── libexec/
│   ├── shared_helpers.sh    # Common shell functions
│   ├── setup                # Bootstrap script
│   ├── doctor               # Diagnostics
│   ├── secrets-get          # Read from Keychain
│   ├── secrets-set          # Write to Keychain
│   └── transcribe           # Bash transcription backend
├── workflows/
│   └── Transcribe Audio.workflow/  # Finder Quick Action
├── completions/
│   ├── maurice.bash         # Bash completions
│   └── maurice.zsh          # Zsh completions
├── Brewfile                 # Homebrew dependencies
├── install.sh               # Alternative installer
└── README.md
```

## Architecture

**Design Principles:**

1. **Homebrew manages installation** - Use Homebrew for distribution and updates
2. **bin/ exposes user commands** - Entrypoints in `bin/` are the user interface
3. **libexec/ owns implementation** - Actual work happens in `libexec/`
4. **Keychain owns secrets** - API keys stored in macOS Keychain
5. **Quick Actions are UI wrappers** - Finder integration delegates to `bin/`
6. **doctor is the support interface** - Diagnostics for troubleshooting

## Development

```bash
# Clone the repository
git clone https://github.com/morris-frank/maurice-tools.git
cd maurice-tools

# Install dependencies
brew bundle

# Run diagnostics
./bin/maurice doctor
```

## License

MIT

## Author

Morris Frank
