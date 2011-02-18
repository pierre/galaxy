require 'rubygems'
require 'fileutils'
require 'tmpdir'
require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'lib/galaxy/version'
begin
    require 'rcov/rcovtask'
    $RCOV_LOADED = true
rescue LoadError
    $RCOV_LOADED = false
    puts "Unable to load rcov"
end

THIS_FILE = File.expand_path(__FILE__)
PWD = File.dirname(THIS_FILE)
RUBY = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])

PACKAGE_NAME = 'galaxy'
PACKAGE_VERSION = Galaxy::Version
GEM_VERSION = PACKAGE_VERSION.split('-')[0]

task :default => [:test]

task :install do
  sitelibdir = CONFIG["sitelibdir"]
  cd 'lib' do
    for file in Dir["galaxy/*.rb", "galaxy/commands/*.rb" ]
      d = File.join(sitearchdir, file)
      mkdir_p File.dirname(d)
      install(file, d)
    end
  end

  bindir = CONFIG["bindir"]
  cd 'bin' do
    for file in ["galaxy", "galaxy-agent", "galaxy-console" ]
      d = File.join(bindir, file)
      mkdir_p File.dirname(d)
      install(file, d)
    end
  end
end


Rake::TestTask.new("test") do |t|
  t.pattern = 'test/test*.rb'
  t.libs << 'test'
  t.warning = true
end

if $RCOV_LOADED
    Rcov::RcovTask.new do |t|
      t.pattern = 'test/test*.rb'
      t.libs << 'test'
      t.rcov_opts = ['--exclude', 'gems/*', '--text-report']
    end
end

Rake::PackageTask.new(PACKAGE_NAME, PACKAGE_VERSION) do |p|
  p.tar_command = 'gtar' if RUBY_PLATFORM =~ /solaris/
  p.need_tar = true
  p.package_files.include(["lib/galaxy/**/*.rb", "bin/*"])
end

spec = Gem::Specification.new do |s|
  s.name = PACKAGE_NAME
  s.version = GEM_VERSION
  s.author = "Ning, Inc."
  s.email = "pierre@ning.com"
  s.homepage = "http://github.com/ning/galaxy"
  s.platform = Gem::Platform::RUBY
  s.summary = "Galaxy is a lightweight software deployment and management tool."
  s.files =  FileList["lib/galaxy/**/*.rb", "bin/*"]
  s.executables = FileList["galaxy-agent", "galaxy-console", "galaxy"]
  s.require_path = "lib"
  s.add_dependency("fileutils", ">= 0.7")
  s.add_dependency("json", ">= 1.5.1")
  s.add_dependency("mongrel", ">= 1.1.5")
  s.add_dependency("rcov", ">= 0.9.9")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.tar_command = 'gtar' if RUBY_PLATFORM =~ /solaris/
  pkg.need_tar = true
end

namespace :run do
  desc "Run a Gonsole locally"
  task :gonsole do
    # Note that -i localhost is needed. Otherwise the DRb server will bind to the
    # hostname, which can be as ugly as "Pierre-Alexandre-Meyers-MacBook-Pro.local"
    system(RUBY, "-I", File.join(PWD, "lib"),
           File.join(PWD, "bin", "galaxy-console"), "--start",
           "-i", "localhost",
           "--ping-interval", "10", "-f", "-l", "STDOUT", "-L", "DEBUG", "-v")
  end

  desc "Run a Gagent locally"
  task :gagent do
    system(RUBY, "-I", File.join(PWD, "lib"),
           File.join(PWD, "bin", "galaxy-agent"), "--start",
           "-i", "localhost", "-c", "localhost",
           "-r", "http://localhost/config/trunk/qa",
           "-b", "http://localhost/binaries",
           "-d", "/tmp/deploy", "-x", "/tmp/extract",
           "--announce-interval", "10", "-f", "-l", "STDOUT", "-L", "DEBUG", "-v")
  end
end

desc "Build a Gem with the full version number"
task :versioned_gem => :gem do
  gem_version = PACKAGE_VERSION.split('-')[0]
  if gem_version != PACKAGE_VERSION
    FileUtils.mv("pkg/#{PACKAGE_NAME}-#{gem_version}.gem", "pkg/#{PACKAGE_NAME}-#{PACKAGE_VERSION}.gem")
  end
end

namespace :package do
  desc "Build an RPM package"
  task :rpm => :versioned_gem do
    build_dir = "/tmp/galaxy-package"
    rpm_dir = "/tmp/galaxy-rpm"
    rpm_version = PACKAGE_VERSION
    rpm_version += "-final" unless rpm_version.include?('-')

    FileUtils.rm_rf(build_dir)
    FileUtils.mkdir_p(build_dir)
    FileUtils.rm_rf(rpm_dir)
    FileUtils.mkdir_p(rpm_dir)

    `rpmbuild --target=noarch -v --define "_builddir ." --define "_rpmdir #{rpm_dir}" -bb build/rpm/galaxy.spec` || raise("Failed to create package")
    # You can tweak the rpm as follow:
    #`rpmbuild --target=noarch -v --define "_gonsole_url gonsole.company.com" --define "_gepo_url http://gepo.company.com/config/trunk/prod" --define "_builddir ." --define "_rpmdir #{rpm_dir}" -bb build/rpm/galaxy.spec` || raise("Failed to create package")

    FileUtils.cp("#{rpm_dir}/noarch/#{PACKAGE_NAME}-#{rpm_version}.noarch.rpm", "pkg/#{PACKAGE_NAME}-#{rpm_version}.noarch.rpm")
    FileUtils.rm_rf(build_dir)
    FileUtils.rm_rf(rpm_dir)
  end

  desc "Build a Sun package"
  task :sunpkg => :versioned_gem do
    build_dir = "#{Dir.tmpdir}/galaxy-package"
    source_dir = File.dirname(__FILE__)

    FileUtils.rm_rf(build_dir)
    FileUtils.mkdir_p(build_dir)
    FileUtils.cp_r("#{source_dir}/build/sun/.", build_dir)
    FileUtils.cp("#{source_dir}/pkg/#{PACKAGE_NAME}-#{PACKAGE_VERSION}.gem", "#{build_dir}/#{PACKAGE_NAME}.gem")
    FileUtils.mkdir_p("#{build_dir}/root/lib/svc/method")

    # Expand version tokens
    `ruby -pi -e "gsub('\#{PACKAGE_VERSION}', '#{PACKAGE_VERSION}'); gsub('\#{GEM_VERSION}', '#{GEM_VERSION}')" #{build_dir}/*`

    # Build the package
    `cd #{build_dir} && pkgmk -r root -d .` || raise("Failed to create package")
    `cd #{build_dir} && pkgtrans -s . #{PACKAGE_NAME}.pkg galaxy` || raise("Failed to translate package")

    FileUtils.cp("#{build_dir}/#{PACKAGE_NAME}.pkg", "#{source_dir}/pkg/#{PACKAGE_NAME}-#{PACKAGE_VERSION}.pkg")
    FileUtils.rm_rf(build_dir)
  end
end
