RSpec.describe FastIgnore::GlobalGitignore do
  subject { described_class.path(root: root) }
  let(:system_path) { '/etc/gitconfig' }
  let(:xdg_config_home) { nil }

  let(:repo_config_path_content) { nil }
  let(:global_config_path_content) { nil }
  let(:system_config_path_content) { nil }

  let(:default_ignore_path) { "#{home}/.config/git/ignore" }

  let(:repo_config_path) { "#{root}/.git/config" }
  let(:global_config_path) { "#{home}/.gitconfig" }
  let(:system_config_path) { "/etc/gitconfig" }
  let(:home) { ENV['HOME'] }
  let(:root) { Dir.pwd }

  let(:config_content) { "[core]\n\texcludesfile = #{excludesfile_value}\n" }
  let(:excludesfile_value) { "~/.global_gitignore" }

  around { |e| within_temp_dir { e.run } }

  before do
    allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').and_return(xdg_config_home)
    allow(ENV).to receive(:[]).and_call_original
    allow(File).to receive(:exist?).with(repo_config_path).and_return(!!repo_config_path_content)
    allow(File).to receive(:exist?).with(global_config_path).and_return(!!global_config_path_content)
    allow(File).to receive(:exist?).with(system_config_path).and_return(!!system_config_path_content)
    allow(File).to receive(:readlines).with(repo_config_path).and_return(repo_config_path_content&.lines)
    allow(File).to receive(:readlines).with(global_config_path).and_return(global_config_path_content&.lines)
    allow(File).to receive(:readlines).with(system_config_path).and_return(system_config_path_content&.lines)
  end

  context 'with no excludesfile defined' do
    it 'returns the default path' do
      expect(subject).to eq "#{home}/.config/git/ignore"
    end
  end

  context 'with excludesfile defined in a config' do
    let(:repo_config_path_content) { config_content }

    it 'returns a literal unquoted value for the path' do
      expect(subject).to eq "#{home}/.global_gitignore"
    end

    context 'when excludesfile value is quoted' do
      let(:excludesfile_value) { '"~/.global_gitignore_in_quotes"'}

      it 'returns a literal unquoted value for the path' do
        expect(subject).to eq "#{home}/.global_gitignore_in_quotes"
      end
    end
  end

  # it 'recognises ~/.gitconfig gitignore files in quotes' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = \"~/.global_gitignore\"\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises ~/.gitconfig gitignore files with # character in the name in quotes' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = \"~/.global#gitignore\"\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global#gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global#gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises ~/.gitconfig gitignore files with " character in the name in quotes' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = \"~/.global\\\"gitignore\"\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global\"gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global\"gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises ~/.gitconfig gitignore files with ; character in the name in quotes' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = \"~/.global;gitignore\"\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global;gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global;gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises XDG_CONFIG_HOME gitconfig gitignore files' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return("#{ENV['HOME']}/.xconfig")
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.xconfig/git/config").at_least(:once).and_return(true)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.xconfig/git/config").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = ~/.global_gitignore\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises XDG_CONFIG_HOME gitconfig gitignore files but home .gitconfig overrides' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return("#{ENV['HOME']}/.xconfig")
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.xconfig/git/config").at_least(:once).and_return(true)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.xconfig/git/config").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = ~/.x_global_gitignore\n".dup
  #       ])

  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile = ~/.global_gitignore\n".dup
  #       ])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.global_gitignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.x_global_gitignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.x_global_gitignore")
  #         .at_least(:once).and_return(["a/b/d\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises default global gitignore file when XDG_CONFIG_HOME is blank' do # rubocop:disable RSpec/ExampleLength
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(false)
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return('')
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises default global gitignore file when XDG_CONFIG_HOME is nil' do # rubocop:disable RSpec/ExampleLength
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises default global gitignore file when gitconfig has no excludesfile and XDG_CONFIG_HOME is nil' do # rubocop:disable RSpec/ExampleLength
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[user]\n".dup,
  #         "\tname = Dana \n".dup
  #       ])
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.config/git/ignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'ignores default global gitignore file when gitconfig has blank excludes file' do # rubocop:disable RSpec/ExampleLength
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return([
  #         "[core]\n".dup,
  #         "\texcludesfile =\n".dup
  #       ])
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.config/git/ignore")
  #         .and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.config/git/ignore")
  #         .and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c', 'a/b/c')
  #       expect(subject).to match_files('b/d')
  #     end

  #     it 'recognises default global gitignore file when XDG_CONFIG_HOME is set' do # rubocop:disable RSpec/ExampleLength
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return('~/.xconfig')
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)

  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.xconfig/git/ignore")
  #         .at_least(:once).and_return(true)
  #       allow(File).to receive(:readlines).with("#{ENV['HOME']}/.xconfig/git/ignore")
  #         .at_least(:once).and_return(["a/b/c\n".dup])

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end

  #     it 'recognises project .gitignore file when no global gitignore' do # rubocop:disable RSpec/ExampleLength
  #       allow(File).to receive(:exist?).with('/etc/gitconfig').at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{Dir.pwd}/.git/gitconfig").at_least(:once).and_return(false)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.gitconfig").at_least(:once).and_return(false)
  #       allow(ENV).to receive(:[]).with('XDG_CONFIG_HOME').at_least(:once).and_return(nil)
  #       allow(File).to receive(:exist?).with("#{ENV['HOME']}/.config/git/ignore").at_least(:once).and_return(false)

  #       gitignore 'b/c', path: 'a/.gitignore'

  #       expect(subject).not_to match_files('a/b/d', 'b/c')
  #       expect(subject).to match_files('a/b/c', 'b/d')
  #     end
end
