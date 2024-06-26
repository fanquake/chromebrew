require 'package'

class Chrome < Package
  description 'Google Chrome is a fast, easy to use, and secure web browser.'
  homepage 'https://www.google.com/chrome/'
  version '126.0.6478.61-1'
  license 'google-chrome'
  compatibility 'x86_64'
  min_glibc '2.29'
  source_url "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_#{version}_amd64.deb"
  source_sha256 '2fb80197848c1c8ab4c7e19989a68ae43c6cf942436a7773d316044fb60eef7a'

  depends_on 'nspr'
  depends_on 'cairo'
  depends_on 'gtk3'
  depends_on 'expat'
  depends_on 'cras'

  no_compile_needed
  no_shrink

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"

    FileUtils.mv 'usr/share', CREW_DEST_PREFIX
    FileUtils.mv 'opt/google/chrome', "#{CREW_DEST_PREFIX}/share"

    FileUtils.ln_s '../share/chrome/google-chrome', "#{CREW_DEST_PREFIX}/bin/google-chrome-stable"
    FileUtils.ln_s '../share/chrome/google-chrome', "#{CREW_DEST_PREFIX}/bin/google-chrome"
  end

  def self.postinstall
    ExitMessage.add "\nType 'google-chrome' to get started.\n".lightblue
  end
end
