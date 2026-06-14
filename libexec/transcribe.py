#!/usr/bin/env python3
"""
transcribe.py - Audio transcription implementation
Supports OpenAI Whisper and Deepgram APIs
"""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Optional


# Provider configurations
PROVIDERS = {
    "openai": {
        "name": "OpenAI Whisper",
        "keychain_service": "maurice.openai.api_key",
    },
    "deepgram": {
        "name": "Deepgram",
        "keychain_service": "maurice.deepgram.api_key",
    },
}


def get_keychain_password(service: str) -> Optional[str]:
    """Retrieve password from macOS Keychain."""
    account = os.environ.get("USER") or subprocess.run(
        ["id", "-un"], capture_output=True, text=True
    ).stdout.strip()

    result = subprocess.run(
        ["security", "find-generic-password", "-s", service, "-a", account, "-w"],
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        return result.stdout.strip()
    return None


def get_config_path() -> Path:
    """Get the path to the config file."""
    return Path.home() / ".config" / "maurice-tools" / "config.toml"


def read_config_value(section: str, key: str, default: Optional[str] = None) -> Optional[str]:
    """Read a value from the TOML config file."""
    config_path = get_config_path()

    if not config_path.exists():
        return default

    try:
        in_section = False
        with open(config_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                # Check for section header
                if line.startswith("[") and line.endswith("]"):
                    current_section = line[1:-1]
                    in_section = current_section == section
                    continue

                # If in target section, look for key
                if in_section and "=" in line:
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip().strip('"').strip("'")
                    if k == key:
                        return v

    except Exception:
        pass

    return default


def get_output_dir() -> Path:
    """Get the output directory for transcriptions."""
    config_dir = read_config_value("transcription", "output_dir", "~/Transcriptions")
    # Expand tilde
    if config_dir.startswith("~"):
        config_dir = str(Path.home()) + config_dir[1:]
    output_dir = Path(config_dir).expanduser()
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def get_preferred_provider() -> str:
    """Get the preferred transcription provider."""
    provider = read_config_value("providers", "preferred", "openai")
    if provider in PROVIDERS:
        return provider
    return "openai"


def check_ffmpeg() -> bool:
    """Check if ffmpeg is available."""
    result = subprocess.run(
        ["which", "ffmpeg"],
        capture_output=True,
    )
    return result.returncode == 0


def convert_to_wav(input_path: Path) -> Path:
    """Convert audio file to WAV format suitable for transcription."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        output_path = Path(tmp.name)

    cmd = [
        "ffmpeg",
        "-i", str(input_path),
        "-ar", "16000",  # 16kHz sample rate (optimal for Whisper)
        "-ac", "1",      # Mono
        "-c:a", "pcm_s16le",  # 16-bit PCM
        "-y",             # Overwrite output
        str(output_path),
    ]

    result = subprocess.run(
        cmd,
        capture_output=True,
    )

    if result.returncode != 0:
        print(f"Error: Failed to convert audio file: {input_path}", file=sys.stderr)
        print(f"ffmpeg stderr: {result.stderr.decode()}", file=sys.stderr)
        sys.exit(1)

    return output_path


def transcribe_with_openai(audio_path: Path, api_key: str, language: Optional[str] = None) -> str:
    """Transcribe audio using OpenAI Whisper API."""
    try:
        import openai
    except ImportError:
        print("Error: OpenAI Python package not installed.", file=sys.stderr)
        print("Run: pip3 install openai", file=sys.stderr)
        sys.exit(1)

    client = openai.OpenAI(api_key=api_key)

    with open(audio_path, "rb") as audio_file:
        kwargs = {
            "model": "whisper-1",
            "file": audio_file,
        }
        if language:
            kwargs["language"] = language

        response = client.audio.transcriptions.create(**kwargs)
        return response.text


def transcribe_with_deepgram(audio_path: Path, api_key: str, language: Optional[str] = None) -> str:
    """Transcribe audio using Deepgram API."""
    try:
        from deepgram import DeepgramClient, PrerecordedOptions, FileSource
    except ImportError:
        print("Error: Deepgram Python package not installed.", file=sys.stderr)
        print("Run: pip3 install deepgram-sdk", file=sys.stderr)
        sys.exit(1)

    client = DeepgramClient(api_key)

    with open(audio_path, "rb") as audio_file:
        buffer_data = audio_file.read()

    payload = {"buffer": buffer_data, "mimetype": "audio/wav"}

    options = PrerecordedOptions(
        model="nova-2",
        smart_format=True,
        language=language or "en",
    )

    response = client.listen.prerecorded.v("1").transcribe_file(
        payload, options
    )

    # Extract transcript from response
    transcript = response.results.channels[0].alternatives[0].transcript
    return transcript


def transcribe_file(input_path: Path, provider: str, language: Optional[str] = None) -> str:
    """Transcribe a single audio file."""
    # Validate provider
    if provider not in PROVIDERS:
        print(f"Error: Unknown provider '{provider}'", file=sys.stderr)
        print(f"Supported providers: {', '.join(PROVIDERS.keys())}", file=sys.stderr)
        sys.exit(1)

    # Get API key
    service = PROVIDERS[provider]["keychain_service"]
    api_key = get_keychain_password(service)

    if not api_key:
        print(f"Error: No API key found for {PROVIDERS[provider]['name']}", file=sys.stderr)
        print(f"Set it with: maurice secret set {provider}", file=sys.stderr)
        sys.exit(1)

    # Convert to WAV
    print(f"Converting {input_path.name}...", file=sys.stderr)
    wav_path = convert_to_wav(input_path)

    try:
        print(f"Transcribing with {PROVIDERS[provider]['name']}...", file=sys.stderr)
        if provider == "openai":
            transcript = transcribe_with_openai(wav_path, api_key, language)
        elif provider == "deepgram":
            transcript = transcribe_with_deepgram(wav_path, api_key, language)
        else:
            raise ValueError(f"Unknown provider: {provider}")

        return transcript

    finally:
        # Clean up temp file
        wav_path.unlink(missing_ok=True)


def write_transcription(input_path: Path, transcript: str, output_dir: Path, overwrite_policy: str = "prompt") -> Path:
    """Write transcription to output file."""
    output_name = input_path.stem + ".txt"
    output_path = output_dir / output_name

    # Handle existing file
    if output_path.exists():
        if overwrite_policy == "never":
            print(f"Skipping (file exists): {output_path}", file=sys.stderr)
            return output_path
        elif overwrite_policy == "prompt":
            print(f"File exists: {output_path}", file=sys.stderr)
            response = input("Overwrite? [y/N]: ")
            if response.lower() != "y":
                print("Skipped.", file=sys.stderr)
                return output_path

    # Write transcription
    output_path.write_text(transcript, encoding="utf-8")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Transcribe audio files using OpenAI Whisper or Deepgram"
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="Audio files to transcribe",
    )
    parser.add_argument(
        "--provider",
        choices=["openai", "deepgram"],
        help="Transcription provider (default: from config or openai)",
    )
    parser.add_argument(
        "--language",
        "-l",
        help="Language code (e.g., 'en', 'de', 'es')",
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        help="Output directory (default: from config or ~/Transcriptions)",
    )
    parser.add_argument(
        "--overwrite",
        choices=["prompt", "always", "never"],
        default="prompt",
        help="Overwrite policy for existing files",
    )

    args = parser.parse_args()

    # Check ffmpeg
    if not check_ffmpeg():
        print("Error: ffmpeg not found. Install with: brew install ffmpeg", file=sys.stderr)
        sys.exit(1)

    # Determine provider
    provider = args.provider or get_preferred_provider()

    # Determine language
    language = args.language or read_config_value("transcription", "default_language")

    # Determine output directory
    if args.output_dir:
        output_dir = Path(args.output_dir).expanduser()
        output_dir.mkdir(parents=True, exist_ok=True)
    else:
        output_dir = get_output_dir()

    # Get overwrite policy from config if not specified
    overwrite_policy = args.overwrite
    if overwrite_policy == "prompt":
        config_policy = read_config_value("transcription", "overwrite_policy")
        if config_policy in ["always", "never", "prompt"]:
            overwrite_policy = config_policy

    # Process each file
    success_count = 0
    for file_path_str in args.files:
        input_path = Path(file_path_str).expanduser().resolve()

        if not input_path.exists():
            print(f"Error: File not found: {input_path}", file=sys.stderr)
            continue

        print(f"\nProcessing: {input_path}", file=sys.stderr)

        try:
            transcript = transcribe_file(input_path, provider, language)
            output_path = write_transcription(
                input_path, transcript, output_dir, overwrite_policy
            )
            print(f"Saved to: {output_path}", file=sys.stderr)
            success_count += 1

            # Also print transcript to stdout for piping
            print(transcript)

        except Exception as e:
            print(f"Error transcribing {input_path}: {e}", file=sys.stderr)

    # Summary
    print(f"\nDone: {success_count}/{len(args.files)} files transcribed.", file=sys.stderr)
    sys.exit(0 if success_count == len(args.files) else 1)


if __name__ == "__main__":
    main()
