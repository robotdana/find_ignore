RSpec.describe FastIgnore::GitconfigParser do
  it 'returns nil for empty file' do
    expect(described_class.parse('')).to eq(nil)
  end

  it 'returns nil for file with no [core]' do
    expect(described_class.parse(<<~GITCONFIG))
      [remote "origin"]
        url = https://github.com/robotdana/fast_ignore.git
        fetch = +refs/heads/*:refs/remotes/origin/*
    GITCONFIG
      .to eq(nil)
  end

  it 'returns nil for file with [core] but no excludesfile' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        mergeoptions = --no-edit
        hooksPath = ~/.dotfiles/hooks
        editor = mate --wait
    GITCONFIG
      .to eq(nil)
  end

  it 'returns value for file with excludesfile' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/.gitconfig
    GITCONFIG
      .to eq('~/.gitconfig')
  end

  it 'returns value for file with excludesfile after other stuff' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        mergeoptions = --no-edit
        excludesfile = ~/.gitconfig
    GITCONFIG
      .to eq('~/.gitconfig')
  end

  it 'returns value for file with excludesfile before other stuff' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/.gitconfig
        mergeoptions = --no-edit
    GITCONFIG
      .to eq('~/.gitconfig')
  end

  it 'returns value for file with [core] after other stuff' do
    expect(described_class.parse(<<~GITCONFIG))
      [remote "origin"]
        url = https://github.com/robotdana/fast_ignore.git
        fetch = +refs/heads/*:refs/remotes/origin/*
      [core]
        excludesfile = ~/.gitconfig
    GITCONFIG
      .to eq('~/.gitconfig')
  end

  it 'returns value for file with [core] before other stuff' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/.gitconfig
      [remote "origin"]
        url = https://github.com/robotdana/fast_ignore.git
        fetch = +refs/heads/*:refs/remotes/origin/*
    GITCONFIG
      .to eq('~/.gitconfig')
  end

  it 'returns nil for file with commented excludesfile line' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
      #  excludesfile = ~/.gitconfig
    GITCONFIG
      .to eq(nil)
  end

  it 'returns value for file with excludesfile in quotes' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = "~/gitconfig"
    GITCONFIG
      .to eq('~/gitconfig')
  end

  it 'returns value for file with excludesfile partially in quotes' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/git"config"
    GITCONFIG
      .to eq('~/gitconfig')
  end

  it 'returns value for file with excludesfile with literal quote character' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/git\\"config
    GITCONFIG
      .to eq('~/git"config')
  end

  it 'returns value for file with excludesfile with literal newline (why)' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/git\\nconfig
    GITCONFIG
      .to eq("~/git\nconfig")
  end

  it 'returns value for file with excludesfile with a ; comment' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/gitconfig ; comment
    GITCONFIG
      .to eq("~/gitconfig")
  end

  it 'returns value for file with excludesfile with a ; comment with no space' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/gitconfig;comment
    GITCONFIG
      .to eq("~/gitconfig")
  end

  it 'returns value for file with excludesfile with a # comment' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = ~/gitconfig # comment
    GITCONFIG
      .to eq("~/gitconfig")
  end

  it 'returns value for file with excludesfile with a # in quotes' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = "~/git#config"
    GITCONFIG
      .to eq("~/git#config")
  end

  it 'returns value with no trailing whitespace' do
    expect(described_class.parse("[core]\n  excludesfile = ~/gitconfig    \n"))
      .to eq("~/gitconfig")
  end

  it 'returns value for file with trailing whitespace when quoted' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = "~/gitconfig   "
    GITCONFIG
      .to eq("~/gitconfig   ")
  end

  it 'returns nil for file with unclosed quote' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = "~/gitconfig
    GITCONFIG
      .to eq(nil)
  end

  it 'returns nil for file with invalid \ escape' do
    expect(described_class.parse(<<~GITCONFIG))
      [core]
        excludesfile = "~/gitconfig\\x"
    GITCONFIG
      .to eq(nil)
  end
end
