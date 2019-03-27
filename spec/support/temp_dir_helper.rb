# frozen_string_literal: true

require 'pathname'
require 'tmpdir'

module TempDirHelper
  module WithinTempDir
    def create_file(filename, body = '')
      path = Pathname.pwd.join(filename)
      path.parent.mkpath
      path.write(body)
      path
    end

    def create_file_list(*filenames)
      filenames.each do |filename|
        create_file(filename)
      end
    end

    def gitignore(body)
      create_file('.gitignore', body)
    end
  end

  def within_temp_dir
    dir = Pathname.new(Dir.mktmpdir)
    Dir.chdir(dir) do
      extend WithinTempDir
      yield
    end
  ensure
    dir&.rmtree
  end
end

RSpec.configure do |config|
  config.include TempDirHelper
end
