require 'package'

class Musl_libssh < Package
  description 'libssh is a multiplatform C library implementing the SSHv2 and SSHv1 protocol on client and server side.'
  homepage 'https://www.libssh.org/'
  version '0.9.6'
  compatibility 'all'
  license 'LGPL-2.1'
  source_url 'https://git.libssh.org/projects/libssh.git'
  git_hashtag "libssh-#{version}"
  binary_compression 'tpxz'

  binary_sha256({
    aarch64: '4174ea38f912fdc3de9f7100131b0bf826ad9412877bd33ff68835692aabe86f',
     armv7l: '4174ea38f912fdc3de9f7100131b0bf826ad9412877bd33ff68835692aabe86f',
       i686: 'ddb6ba2660d2118ce19a9b551668bf75b55a45fa202d1673186aa1ccb7a1a4db',
     x86_64: '59e96f9b5902d6789dcb71d7ff864d533ed4522f419dd7178b2d1c86664a3264'
  })

  depends_on 'musl_native_toolchain' => :build
  depends_on 'musl_libunistring' => :build
  depends_on 'musl_libidn2' => :build
  depends_on 'musl_zlib' => :build
  depends_on 'musl_ncurses' => :build
  depends_on 'musl_openssl' => :build
  depends_on 'musl_libnghttp2' => :build
  depends_on 'py3_abimap' => :build

  is_static
  print_source_bashrc

  def self.build
    load "#{CREW_LIB_PATH}/lib/musl.rb"
    FileUtils.mkdir('builddir')
    Dir.chdir('builddir') do
      system "#{MUSL_CMAKE_OPTIONS} \
      -DOPENSSL_INCLUDE_DIR=#{CREW_MUSL_PREFIX}/include \
      -DBUILD_SHARED_LIBS=OFF \
      -DGLOBAL_BIND_CONFIG=#{CREW_PREFIX}/etc/ssh/libssh_server_config \
      -DGLOBAL_CLIENT_CONFIG=#{CREW_PREFIX}/etc/ssh/ssh_config \
      -DHAVE_GLOB=0 \
      -DUNIT_TESTING=OFF \
      -DWITH_EXAMPLES=OFF \
      ../ -G Ninja"
    end
    system 'samu -C builddir'
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} samu -C builddir install"
  end
end
