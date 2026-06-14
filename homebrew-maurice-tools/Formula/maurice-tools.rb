class MauriceTools < Formula
  desc "macOS CLI suite for audio transcription and utilities"
  homepage "https://github.com/morris-frank/maurice-tools"
  url "https://github.com/morris-frank/maurice-tools/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on "python@3.12"
  depends_on "uv"
  depends_on "ffmpeg"
  depends_on "jq"

  resource "openai" do
    url "https://files.pythonhosted.org/packages/source/o/openai/openai-1.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "deepgram-sdk" do
    url "https://files.pythonhosted.org/packages/source/d/deepgram-sdk/deepgram-sdk-3.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "pydub" do
    url "https://files.pythonhosted.org/packages/source/p/pydub/pydub-0.25.1.tar.gz"
    sha256 "PLACEHOLDER"
  end

  def install
    # Install bin/ executables
    bin.install Dir["bin/*"]

    # Install libexec/ helpers
    libexec.install Dir["libexec/*"]

    # Install workflow files
    pkgshare.install Dir["workflows/*"]

    # Install completions
    bash_completion.install "completions/maurice.bash" => "maurice"
    zsh_completion.install "completions/maurice.zsh" => "_maurice"

    # Set up Python environment
    venv = virtualenv_create(libexec, "python3.12")

    # Install Python dependencies
    venv.pip_install resources

    # Create wrapper scripts that set MAURICE_ROOT
    (bin/"maurice").write_env_script libexec/"maurice",
      MAURICE_ROOT: opt_prefix

    (bin/"transcribe-audio").write_env_script libexec/"transcribe-audio",
      MAURICE_ROOT: opt_prefix
  end

  def caveats
    <<~EOS
      Maurice Tools has been installed!

      Quick start:
        maurice setup     # Bootstrap installation
        maurice doctor    # Check system health

      To use Finder Quick Actions:
        maurice setup will install "Transcribe Audio" to ~/Library/Services/

      To configure API keys:
        maurice secret set openai
        maurice secret set deepgram

      Documentation: https://github.com/morris-frank/maurice-tools
    EOS
  end

  test do
    # Test that binaries are available
    assert_match "Maurice Tools", shell_output("#{bin}/maurice version")

    # Test that doctor runs
    system "#{bin}/maurice", "doctor"
  end
end
