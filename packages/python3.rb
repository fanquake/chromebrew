require 'package'

class Python3 < Package
  description 'Python is a programming language that lets you work quickly and integrate systems more effectively.'
  homepage 'https://www.python.org/'
  version '3.12.4'
  license 'PSF-2.0'
  compatibility 'all'
  source_url "https://www.python.org/ftp/python/#{version}/Python-#{version}.tar.xz"
  source_sha256 'f6d419a6d8743ab26700801b4908d26d97e8b986e14f95de31b32de2b0e79554'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: 'f0bfcd80509e4033c28b3382f3a416b83dcde5efbdcbd7052ca49a7b8269bc7b',
     armv7l: 'f0bfcd80509e4033c28b3382f3a416b83dcde5efbdcbd7052ca49a7b8269bc7b',
       i686: '44905c28ef097fe5cbeb44410bd0d36694dbfb4f417c1ae4662d09e0f0a17bd6',
     x86_64: 'c3c7fdb3017d800b45858863d19641e86ca608aedc3e60a45b6454b18d3f8951'
  })

  depends_on 'autoconf_archive' => :build
  depends_on 'bzip2' # R
  depends_on 'expat' # R
  depends_on 'gcc_lib' # R
  depends_on 'gdbm' # R
  depends_on 'glibc' # R
  depends_on 'krb5' => :build
  depends_on 'libdb' # R
  depends_on 'libffi' # R
  depends_on 'libnsl' # R
  depends_on 'libtirpc' # R
  depends_on 'mpdecimal' # R
  depends_on 'ncurses' # R
  depends_on 'openssl' # R
  depends_on 'readline' # R
  depends_on 'sqlite' # R
  depends_on 'tcl' => :build unless ARCH == 'i686' # Needed for tkinter support
  depends_on 'tk' => :build unless ARCH == 'i686' # Needed for tkinter support
  depends_on 'util_linux' # R
  depends_on 'xzutils' # R
  depends_on 'zlibpkg' # R
  depends_on 'zoneinfo' # L

  no_env_options
  conflicts_ok

  def self.preinstall
    @device = JSON.load_file("#{CREW_CONFIG_PATH}/device.json", symbolize_names: true)
    @replaces = %w[py3_pip py3_setuptools]
    @replaces_installed = []
    @replaces.each do |package|
      @replaces_installed.push(package) if @device[:installed_packages].any? { |elem| elem[:name] == package }
    end
    return if @replaces_installed.empty?

    puts "Removing superseded package(s): #{@replaces_installed.join(' ')}...".orange
    system "crew remove #{@replaces_installed.join(' ')}", exception: false
  end

  def self.prebuild
    # Ensure that internal copies of expat, libffi and zlib aren't used
    FileUtils.rm_rf 'Modules/expat'
    FileUtils.rm_rf Dir.glob('Modules/_ctypes/libffi*')
    FileUtils.rm_rf 'Modules/zlib'
  end

  def self.build
    # Using /tmp breaks test_distutils, test_subprocess.
    # Proxy setting breaks test_httpservers, test_ssl,
    # test_urllib, test_urllib2, test_urllib2_localnet.
    # So, modifying environment variable to make pass tests.

    return if Dir.exist?('builddir')

    FileUtils.mkdir_p 'builddir'
    Dir.chdir 'builddir' do
      system "../configure #{CREW_OPTIONS} \
          --with-lto \
          --with-computed-gotos \
          --enable-loadable-sqlite-extensions \
          --with-ensurepip \
          --enable-optimizations \
          --with-platlibdir='lib#{CREW_LIB_SUFFIX}' \
          --with-system-expat \
          --with-system-libmpdec \
          --with-tzpath=#{CREW_PREFIX}/share/zoneinfo \
          --with-libc= \
          --enable-shared"
      system "MAKEFLAGS=-j#{CREW_NPROC} mold -run make"
      File.write 'python_config_env', <<~PYTHON_CONFIG_EOF
        # Force use of python3 over python2.7 in packages which check the variable to set the python used.
        PYTHON=python3
      PYTHON_CONFIG_EOF
    end
  end

  def self.check
    # Chromebooks do not allow SIGHUP, so disable SIGHUP test
    system 'sed', '-i', 'Lib/test/test_asyncio/test_events.py', '-e', "/Don't have SIGHUP/s/win32/linux/"
    system 'sed', '-i', 'Lib/test/test_asyncio/test_subprocess.py', '-e', "/Don't have SIGHUP/s/win32/linux/"

    # Chromebooks return EINVAL for F_NOTIFY DN_MULTISHOT, so disable test_fcntl_64_bit
    system 'sed', '-i', 'Lib/test/test_fcntl.py', '-e', '/ARM Linux returns EINVAL for F_NOTIFY DN_MULTISHOT/s/$/\
    @unittest.skipIf(platform.system() == '"'Linux'"', "Chromeos returns EINVAL for F_NOTIFY DN_MULTISHOT")/'

    # imaplib test used to use a kind of security hole on a server in university and the hole is closed now.
    # See https://bugs.python.org/issue30175 and https://github.com/python/cpython/pull/1320/files for details.
    system 'sed', '-i', 'Lib/test/test_imaplib.py',
           '-e', '/test_logincapa_with_client_certfile/i\ \ \ \ @unittest.skipIf(True,\
                     "bpo-30175: FIXME: cyrus.andrew.cmu.edu doesn\'t accept "\
                     "our randomly generated client x509 certificate anymore")',
           '-e', '/test_logincapa_with_client_ssl_context/i\ \ \ \ @unittest.skipIf(True,\
                     "bpo-30175: FIXME: cyrus.andrew.cmu.edu doesn\'t accept "\
                     "our randomly generated client x509 certificate anymore")'

    # Using /tmp breaks test_distutils, test_subprocess
    # Proxy setting breaks test_httpservers, test_ssl,
    # test_urllib, test_urllib2, test_urllib2_localnet
    # system "http_proxy= https_proxy= ftp_proxy= make test"
  end

  def self.install
    Dir.chdir 'builddir' do
      system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
      # There is a Python ABI break in 3.11.5 coming from 3.11.4, see https://github.com/python/cpython/issues/108525
      system "LD_LIBRARY_PATH=#{CREW_DEST_LIB_PREFIX}:#{CREW_LIB_PREFIX} #{CREW_DEST_PREFIX}/bin/python3 -m ensurepip --upgrade --default-pip"
      system "sed -i 's,#{CREW_DEST_PREFIX}/bin/python3,#{CREW_PREFIX}/bin/python3,g' #{CREW_DEST_PREFIX}/bin/pip3"
    end

    # Make python3 the default python
    FileUtils.ln_sf 'python3', "#{CREW_DEST_PREFIX}/bin/python"
    FileUtils.ln_sf 'pip3', "#{CREW_DEST_PREFIX}/bin/pip"
    FileUtils.install 'builddir/python_config_env', "#{CREW_DEST_PREFIX}/etc/env.d/python", mode: 0o644
  end

  def self.postinstall
    # First force pip upgrade to make sure we are past the problematic pip 23.2.1
    # See https://github.com/pypa/pip/issues/12357 and https://github.com/pypa/pip/issues/12428
    system 'PIP_DISABLE_PIP_VERSION_CHECK=1 python -m pip install --upgrade --force-reinstall pip'
    # Pip is installed inside Python 3. The following steps ensure that
    # pip can properly build other packages from buildsystems/pip.
    @required_pip_modules = %w[build installer setuptools wheel pyproject_hooks]
    @pip_list = `pip list --exclude pip`
    @required_pip_modules.each do |pip_pkg|
      unless @pip_list.include?(pip_pkg)
        puts "Installing #{pip_pkg} using pip..."
        system "MAKEFLAGS=-j#{CREW_NPROC} pip install #{pip_pkg}"
      end
    end

    puts 'Updating pip packages...'.lightblue
    system 'pip list --outdated --format=json | python -c "import json, sys; print(\'\n\'.join([x[\'name\'] for x in json.load(sys.stdin)]))" | xargs -rn1 pip install -U', exception: false
    ExitMessage.add "Please install tcl and tk with 'crew install tcl tk' if tkinter is needed.".lightblue unless ARCH == 'i686'
  end
end
