require 'package'

class Go_tools < Package
  description 'Developer tools for the Go programming language'
  homepage 'https://github.com/golang/tools'
  version '0.6.6'
  license 'BSD'
  compatibility 'all'
  source_url 'SKIP'
  binary_compression 'tar.xz'

  binary_sha256({
    aarch64: '5c938388e815f2d03343301f391640a1cbc11fac3b31e20fc74b77c0963723df',
     armv7l: '5c938388e815f2d03343301f391640a1cbc11fac3b31e20fc74b77c0963723df',
       i686: '02e41321fa7030598a80a396887289027889ad08784bf04c68f38196f33f02ec',
     x86_64: '61c25f3eae11e32d625f917f8d853e134a24581a555b5edd47e76fcef96f565d'
  })

  depends_on 'go' => :build

  def self.install
    @git_dir = 'go_tools_git'
    @git_hash = "gopls/v#{version}"
    @git_url = 'https://github.com/golang/tools/'
    FileUtils.rm_rf(@git_dir)
    FileUtils.mkdir_p(@git_dir)
    Dir.chdir @git_dir do
      system 'git init'
      system "git remote add origin #{@git_url}"
      system "git fetch --depth 1 origin #{@git_hash}"
      system 'git checkout FETCH_HEAD'
      system "GOBIN=#{CREW_DEST_PREFIX}/bin go install ./cmd..."
    end
  end
end
