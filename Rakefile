#!/usr/bin/env ruby
require 'optparse'
require 'rbconfig'

# TODO: Is this the best way to do this? Is there any other way?
PACKAGE = (
  if file = Dir['{.,meta/}unixname{,.txt}'].first
    File.read(file).strip
  else
    abort "Requires package unix-name. Edit .unixname or meta/unixname."
  end
)
GENERATE_DOCS = true   # TODO: maybe just check if it already exists instead?

# UberTask defines all the tasks one needs for the typical end-user
# to configure, compile, test and install a package to their system.

class UberTask

  attr_accessor :package
  attr_accessor :gendocs

  attr :config

  #
  def initialize(package_name, generate_docs=true) #:yield:
    @package = package_name
    @gendocs = generate_docs
    @config  = Configure.new
    yield[self] if block_given?
    define
  end

  #
  def define
    # Default task will compile and test.

    task :default => [:setup, :test]

    #
    # TASK config
    #

    desc "Configure for your system."
    task :config => [:config_load] do
      config.quiet = Rake.application.options.silent
      config.exec_config
    end

    if File.exist?(Configure::FILENAME)
      desc "Reconfigure for your system."
      task :reconfig do
        config.quiet = Rake.application.options.silent
        config.exec_config
      end
    end

    #

    task :config_load do
      if File.file?('.config')
        config.load
      else
        abort "Run rake config first."
      end
    end

    #
    # TASK show
    #

    desc "Display current configuraiton."
    task :show do
      config.show
    end

    #
    # TASK clean & clobber
    #

    require 'rake/clean'

    CLOBBER.include(Configure::FILENAME)
    CLOBBER.include(Installer::MANIFEST)
    CLOBBER.include(File.join('doc', PACKAGE, 'rdoc')) if GENERATE_DOCS

    task :clean   => [:makeclean]
    task :clobber => [:distclean]

    task :makeclean do
      config.extensions.each do |dir|
        Dir.chdir(dir) do
          config.make 'clean' if File.file?('Makefile')
        end
      end
    end

    task :distclean do
      config.extensions.each do |dir|
        Dir.chdir(dir) do
          config.make 'distclean' if File.file?('Makefile')
        end
      end
    end

    #
    # TASK all
    #

    if File.exist?('.config')
      desc "Setup, test, document and install."
      task :all => [:setup, :test, :doc, :index, :install]
    else
      # shortcut
      desc "Configure, setup, test, document and install."
      task :all => [:config, :setup, :test, :doc, :install]
    end

    #
    # TASK setup
    #

    # TODO: No shebang until it works at install time and doesn't overwrite the repo scripts.

    desc "Compile extensions."  # update shebangs
    task :setup => [:config_load, :extconf, :make] #, :shebang]

    task :extconf => [:config_load] do
      config.extensions.each do |dir|
        next if File.file?(File.join(dir, 'Makefile'))
        Dir.chdir(dir) do
          config.ruby('extconf.rb', config.configopt)
        end
      end
    end

    task :make => [:config_load] do
      config.extensions.each do |dir|
        Dir.chdir(dir) do
          config.make
        end
      end
    end

    task :shebang => [:config_load, :installer] do
      Dir.chdir('bin') do
        executables = Dir['*'].select{ |f| File.file?(f) }
        executables.each do |file|
          INSTALLER.update_shebang_line(file)
        end
      end
    end

    #
    # TASK test
    #

    # You can provide a test/suite.rb file to be run if
    # by the testrb command, if you special testing requirements.

    desc "Run unit tests."
    task :test => [:config_load, :setup] do
      runner = config.testrunner
      # build testrb options
      opt = []
      opt << " -v" if verbose?
      opt << " --runner #{runner}"
      if File.file?('test/suite.rb')
        notests = false
        opt << "test/suite.rb"
      else
        notests = Dir["test/**/*.rb"].empty?
        lib = ["lib"] + config.extensions.collect{ |d| File.dirname(d) }
        opt << "-I" + lib.join(':')
        opt << Dir["test/**/{test,tc}*.rb"]
      end
      opt = opt.flatten.join(' ').strip
      # run tests
      if notests
        $stderr.puts 'No tests.' #if verbose?
      else
        cmd = "testrb #{opt}"
        $stderr.puts cmd if verbose?
        system cmd #config.ruby "-S tesrb", opt
      end
    end

    #
    # TASK doc
    #

    # If a .document file is available, it will be
    # used to compile the list of toplevel files
    # to document. (For some reason it doesn't use
    # the .document file on it's own.)
    #
    # Note that this places the rdoc in doc/name/rdoc,
    # So that they are subsequently installed to your
    # system by the installer. To prevent this use
    # the @without_doc@ config option.

    if GENERATE_DOCS
      desc "Generate html docs."
      task :doc => [:config_load] do
        output    = File.join('doc', PACKAGE, 'rdoc')
        title     = (PACKAGE.capitalize + " API").strip
        main      = Dir.glob("README{,.txt}", File::FNM_CASEFOLD).first
        template  = config.rdoctemplate || 'html'

        opt = []
        opt << "-U"
        opt << "-S"
        opt << "--op=#{output}"
        opt << "--template=#{template}"
        opt << "--title=#{title}"
        opt << "--main=#{main}"     if main

        if File.exist?('.document')
          files = File.read('.document').split("\n")
          files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
          files.collect!{ |f| f.strip }
          opt << files
        else
          opt << main           if main
          opt << ["lib", "ext"]
        end

        opt = opt.flatten

        if no_harm?
          puts "rdoc #{opt.join(' ').strip}"
        else
          #sh "rdoc {opt.join(' ').strip}"
          require 'rdoc/rdoc'
          ::RDoc::RDoc.new.document(opt)
        end
      end
    else
      task :doc do
      end
    end

    #
    # TASK index
    #

    # This task generates and installs the ri docs to 
    # the designated installdirs-based location.
    #
    # It is unfortunate that this isn't more like rdocing.
    # In that we can't first generate them, then install them.
    # We have to do it all at once. We may be able to fix this
    # later, but it requires special action by the installer,
    # so it will have to wait.

    desc "Generate and install index docs."
    task :index => [:config_load] do
      case config.installdirs
      when 'std'
        output = "--ri-system"
      when 'site'
        output = "--ri-site"
      when 'home'
        output = "--ri"
      else
        abort "bad config: sould not be possible -- installdirs = #{config.installdirs}"
      end

      opt = []

      if File.exist?('.document')
        files = File.read('.document').split("\n")
        files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
        files.collect!{ |f| f.strip }
        opt << files
      else
        opt << ["lib", "ext"]
      end

      opt << "-U"
      opt << output
      opt << files
      opt = opt.flatten

      if no_harm?
        puts "rdoc #{opt.join(' ').strip}"
      else
        #sh "rdoc #{opt.join(' ').strip}"
        require 'rdoc/rdoc'
        ::RDoc::RDoc.new.document(opt)
      end
    end

    #
    # TASK install & uninstall
    #

    # Install uses the installation procedures developed by Minero Aoki
    # for setup.rb. Over time it would be nice to "rakeify" these. Every
    # file installed is listed in the install manifest (.installedfiles).
    #
    # The uninstall task simply reads the install manifest, and removes 
    # the files listed there from your system. Note, when you use the
    # clobber task, this file is removed. So be sure not to clobber,
    # if you pan to uninstall!
    #
    # TODO: Maybe the install manifest should never be clobber, expect
    # after an uninstall?

    desc "Install package files."
    task :install => [:config_load, :setup, :installer] do
      @installer.exec_install
      unless config.without_index?
        Rake::Task[:index].invoke
      end
    end

    if Installer.uninstallable?
      desc "Remove previously installed files."
      task :uninstall => [:confg_load, :installer] do
        @installer.exec_uninstall
      end
    end

    task :installer do
      @installer = Installer.new(config)
      @installer.verbose = env('verbose')
      @installer.no_harm = env('noharm')
    end

    #
    # TASK help
    #

    # Yea, we all need help some times ;)

    desc "Display config help information."
    task :help do
      puts Configure::HELP
    end
  end

  # Get environament variables.

  def env(*keys)
    key = keys.find{ |k| ENV[k.to_s] || ENV[k.to_s.downcase] || ENV[k.to_s.upcase] }
    ENV[key] if key
  end

  def verbose?
    env('verbose')
  end

  def no_harm?
    env('noharm','nowrite')
  end

end

# Configure class is used to generate the .config file
# contining the settings used for installing a package.
# These settings can be altered by the user if required
# for their particular system, either via the command line
# or environment variables.

class Configure

  Version     = [1,0,0]
  Copyright   = "Copyright (c) 2008 Trans"

  Error       = Class.new(StandardError)

  RBCONFIG    = ::Config::CONFIG
  FILENAME  = '.config'

  DESCRIPTIONS = [
    [:prefix          , 'Path prefix of target environment'],
    [:bindir          , 'Directory for commands'],
    [:libdir          , 'Directory for libraries'],
    [:datadir         , 'Directory for shared data'],
    [:mandir          , 'Directory for man pages'],
    [:docdir          , 'Directory for documentation'],
    [:sysconfdir      , 'Directory for system configuration files'],
    [:localstatedir   , 'Directory for local state data'],
    [:libruby         , 'Directory for ruby libraries'],
    [:librubyver      , 'Directory for standard ruby libraries'],
    [:librubyverarch  , 'Directory for standard ruby extensions'],
    [:siteruby        , 'Directory for version-independent aux ruby libraries'],
    [:siterubyver     , 'Directory for aux ruby libraries'],
    [:siterubyverarch , 'Directory for aux ruby binaries'],
    [:rbdir           , 'Directory for ruby scripts'],
    [:sodir           , 'Directory for ruby extentions'],
    [:rubypath        , 'Path to set to #! line'],
    [:rubyprog        , 'Ruby program using for installation'],
    [:makeprog        , 'Make program to compile ruby extentions'],
    [:without_ext     , 'Do not compile/install ruby extentions'],
    [:without_doc     , 'Do not install docs'],
    [:without_index   , 'Do not generate ri docs'],
    [:shebang         , 'Shebang line (#!) editing mode (all,ruby,never)'],
    [:installdirs     , 'Install location mode (std,site,home)'],
    [:testrunner      , 'Runner to use for testing (console|tk|gtk|gtk2)'],
    [:rdoctemplate    , 'Document template to use (html)']
  ]

  # List of configurable options.
  OPTIONS = DESCRIPTIONS.collect{ |(k,v)| k.to_s }

  # Pathname attribute. Pathnames are automatically expanded
  # unless they start with '$', a path variable.
  def self.attr_pathname(name)
    class_eval %{
      def #{name}
        @#{name}.gsub(%r<\\$([^/]+)>){ self[$1] }
      end
      def #{name}=(path)
        raise Error, "bad config: #{name.to_s.upcase} requires argument" unless path
        @#{name} = (path[0,1] == '$' ? path : File.expand_path(path))
      end
    }   
  end

  # List of pathnames. These are not expanded though.
  def self.attr_pathlist(name)
    class_eval %{
      def #{name}
        @#{name}
      end
      def #{name}=(pathlist)
        case pathlist
        when Array
          @#{name} = pathlist
        else
          @#{name} = pathlist.to_s.split(/[:;,]/)
        end
      end
    }   
  end

  # Adds boolean support.
  def self.attr_accessor(*names)
    bools, attrs = names.partition{ |name| name.to_s =~ /\?$/ }
    attr_boolean *bools
    super *attrs
  end

  # Boolean attribute. Can be assigned true, false, nil, or
  # a string matching yes|true|y|t or no|false|n|f.
  def self.attr_boolean(*names)
    names.each do |name|
      name = name.to_s.chomp('?')
      attr_reader name  # MAYBE: Deprecate
      code = %{
        def #{name}?; @#{name}; end
        def #{name}=(val)
          case val
          when true, false, nil
            @#{name} = val
          else
            case val.to_s.downcase
            when 'y', 'yes', 't', 'true'
               @#{name} = true
            when 'n', 'no', 'f', 'false'
               @#{name} = false
            else
              raise Error, "bad config: use #{name.upcase}=(yes|no) [\#{val}]"
            end
          end
        end
      }
      class_eval code
    end
  end

  # path prefix of target environment
  attr_pathname :prefix

  # directory for commands
  attr_pathname :bindir

  #directory for libraries
  attr_pathname :libdir

  # directory for shared data
  attr_pathname :datadir

  # directory for man pages
  attr_pathname :mandir

  # directory for documentation
  attr_pathname :docdir

  # directory for system configuration files
  attr_pathname :sysconfdir

  # directory for local state data
  attr_pathname :localstatedir

  # directory for ruby libraries
  attr_pathname :libruby

  # directory for standard ruby libraries
  attr_pathname :librubyver

  # directory for standard ruby extensions
  attr_pathname :librubyverarch

  # directory for version-independent aux ruby libraries
  attr_pathname :siteruby

  # directory for aux ruby libraries
  attr_pathname :siterubyver

  # directory for aux ruby binaries
  attr_pathname :siterubyverarch

  # directory for ruby scripts
  attr_pathname :rbdir

  # directory for ruby extentions
  attr_pathname :sodir

  # path to set to #! line
  attr_accessor :rubypath

  # ruby program using for installation
  attr_accessor :rubyprog

  # program to compile ruby extentions
  attr_accessor :makeprog

  # shebang line (#!) editing mode (all,ruby,never)', 'all/ruby/never
  attr_accessor :shebang

  # install location mode (std: libruby, site: site_ruby, home: $HOME)
  attr_accessor :installdirs

  # options to pass to extconfig.rb
  attr_accessor :configopt

  # do not compile/install ruby extentions
  attr_accessor :without_ext?

  # do not compile/install ruby extentions
  attr_accessor :without_doc?

  # do not compile/install ruby extentions
  attr_accessor :without_index?

  # document template to use [html]
  attr_accessor :rdoctemplate

  # runner to use for testing (console|tk|gtk|gtk2)
  attr_accessor :testrunner

  # Run silently.
  attr_accessor :quiet?

  # shebang has only three options.
  def shebang=(val)
    if %w(all ruby never).include?(val)
      @shebang = val
    else
      raise Error, "bad config: use SHEBANG=(all|ruby|never) [#{val}]"
    end
  end

  # installdirs has only three options; and it has side-effects.
  def installdirs=(val)
    @installdirs = val
    case val.to_s
    when 'std'
      self.rbdir = '$librubyver'
      self.sodir = '$librubyverarch'
    when 'site'
      self.rbdir = '$siterubyver'
      self.sodir = '$siterubyverarch'
    when 'home'
      raise Error, 'HOME is not set.' unless ENV['HOME']
      self.prefix = ENV['HOME']
      self.rbdir = '$libdir/ruby'
      self.sodir = '$libdir/ruby'
    else
      raise Error, "bad config: use INSTALLDIRS=(std|site|home|local) [#{val}]"
    end
  end

  # Get configuration from environment.
  def getenv
    OPTIONS.each do |name|
      if value = ENV[name] || ENV[name.upcase]
        __send__("#{name}=",value)
      end
    end
  end

  # Load configuration.
  def load
    #if File.file?(FILENAME)
      begin
        File.foreach(FILENAME) do |line|
          k, v = *line.split(/=/, 2)
          __send__("#{k}=",v.strip) #self[k] = v.strip
        end
      rescue Errno::ENOENT
        raise Error, $!.message + "\n#{File.basename($0)} config first"
      end
    #end
  end

  # Save configuration.
  def save
    File.open(FILENAME, 'w') do |f|
      OPTIONS.each do |name|
        val = self[name]
        case val
        when Array
          f << "#{name}=#{val.join(';')}\n"
        else
          f << "#{name}=#{val}\n"
        end
      end
    end
  end

  def show
    fmt = "%-20s %s\n"
    OPTIONS.each do |name|
      value = self[name]
      printf fmt, name, __send__(name) if value
    end
    printf fmt, 'VERBOSE', verbose? ? 'yes' : 'no'
    printf fmt, 'NOHARM', no_harm? ? 'yes' : 'no'
  end

  # Get unresloved attribute.
  def [](name)
    instance_variable_get("@#{name}")
  end

  # Set attribute.
  def []=(name, value)
    instance_variable_set("@#{name}", value)
  end

  # Resolved attribute. (for paths)
  #def resolve(name)
  #  self[name].gsub(%r<\\$([^/]+)>){ self[$1] }
  #end

  # New ConfigTable
  def initialize(values=nil)
    initialize_defaults
    if values
      values.each{ |k,v| __send__("#{k}=", v) }
    end
    yeild(self) if block_given?
  end

  # Assign CONFIG defaults
  #
  # TODO: Does this handle 'nmake' on windows?

  def initialize_defaults
    prefix = RBCONFIG['prefix']

    rubypath = File.join(RBCONFIG['bindir'], RBCONFIG['ruby_install_name'] + RBCONFIG['EXEEXT'])

    # V > 1.6.3
    libruby         = "#{prefix}/lib/ruby"
    librubyver      = RBCONFIG['rubylibdir']
    librubyverarch  = RBCONFIG['archdir']
    siteruby        = RBCONFIG['sitedir']
    siterubyver     = RBCONFIG['sitelibdir']
    siterubyverarch = RBCONFIG['sitearchdir']

    if arg = RBCONFIG['configure_args'].split.detect {|arg| /--with-make-prog=/ =~ arg }
      makeprog = arg.sub(/'/, '').split(/=/, 2)[1]
    else
      makeprog = 'make'
    end

    parameterize = lambda do |path|
      val = RBCONFIG[path]
      val.sub(/\A#{Regexp.quote(prefix)}/, '$prefix')
    end

    self.prefix          = prefix
    self.bindir          = parameterize['bindir']
    self.libdir          = parameterize['libdir']
    self.datadir         = parameterize['datadir']
    self.mandir          = parameterize['mandir']
    self.docdir          = File.dirname(parameterize['docdir'])  # b/c of trailing $(PACKAGE)
    self.sysconfdir      = parameterize['sysconfdir']
    self.localstatedir   = parameterize['localstatedir']
    self.libruby         = libruby
    self.librubyver      = librubyver
    self.librubyverarch  = librubyverarch
    self.siteruby        = siteruby
    self.siterubyver     = siterubyver
    self.siterubyverarch = siterubyverarch
    self.rbdir           = '$siterubyver'
    self.sodir           = '$siterubyverarch'
    self.rubypath        = rubypath
    self.rubyprog        = rubypath
    self.makeprog        = makeprog
    self.shebang         = 'ruby'
    self.without_ext     = 'no'
    self.without_doc     = 'no'
    self.without_index   = 'no'
    self.installdirs     = 'site'
    self.rdoctemplate    = 'html'
    self.testrunner      = 'console'
    self.configopt       = ''
  end

  def show
    fmt = "%-20s %s\n"
    OPTIONS.each do |name|
      value = self[name]
      printf fmt, name, __send__(name)
    end
  end

  #
  def exec_config
    getenv
    save
    #create_makefiles if compiles?
    create_rakefile
    show unless quiet?
    puts "Configuration saved."
  end

  def extconfs
    @extconfs ||= Dir['ext/**/extconf.rb']
  end

  def extensions
    @extensions ||= extconfs.collect{ |f| File.dirname(f) }
  end

  def compiles?
    !extensions.empty?
  end

  #def create_makefiles
  #  extensions.each do |dir|
  #    Dir.chdir(dir) do
  #      ruby('extconf.rb', configopt)
  #    end
  #  end
  #end

  # Create rakefile, if it doesn't exist.
  def create_rakefile
    unless Dir['[Rr]akefile{,.rb}'].first
      File.open('Rakefile', 'w') do |f|
        f << DATA.read
      end
    end
  end

  def ruby(*args)
    command rubyprog, *args
  end

  def make(task = nil)
    command(*[makeprog, task].compact)
  end

  def command(*args)
    $stderr.puts args.join(' ') if $DEBUG
    system(*args) or raise RuntimeError, "system(#{args.map{|a| a.inspect }.join(' ')}) failed"
  end

  # Help output.

  HELP = <<-END
  The Uber Rakefile v#{Version.join('.')}

  Usage:

    #{File.basename($0)} [options]

  The Uber Rakefile is designed to install a Ruby package. It does this by breaking
  the steps involved down into individual rake tasks. This gives the installer the
  opportunity to adjust installation settings as required for a particular
  platform. A typical installation procedure is:

        $ rake config
        $ rake setup
        $ rake install

  If you are certain of the default configuration settings (which are usually correct),
  you can use the simple shortcut:

        $ rake all

  See rake -T for all available tasks.

  Below is the list of options available for the config task.

  Configuration options:
  END

    fmt = "     %-20s   %s\n"
    DESCRIPTIONS.each do |name, desc|
      HELP << fmt % ["#{name}", desc]
    end

  HELP << <<-END

  Other options:
     verbose              Provide extra ouput
     nowrite              Do not write to disk.
     noharm               Same as nowrite.

  Installdirs options correspond to: libruby, site_ruby and $HOME repsectively.

  END

#  Other options:
#    -q --quiet              Run silently
#    -h --help               Display this help information
#       --version            Show version
#       --copyright          Show copyright
#
#  END

  HELP.gsub!(/^\ \ /,'')

  # CLI runner. This uses OptionParser to parse
  # command line arguments. (May chnage to GetoptLong).

  def self.start_cli
    config = new

    opts = OptionParser.new

    DESCRIPTIONS.each do |name, desc|
      opts.on("--#{name}", desc) do |val|
        ENV[name.upcase] = val
      end
    end

    # Tail options (eg. commands in option form)

    opts.on("-q", "--quiet", "Run silently") do |val|
      config.quiet = true
    end

    opts.on_tail("-h", "--help", "Display help information") do
      puts HELP
      exit
    end

    opts.on_tail("--version", "Show version") do
      puts File.basename($0) + ' v' + Setup::Version.join('.')
      exit
    end

    opts.on_tail("--copyright", "Show copyright") do
      puts Setup::Copyright
      exit
    end

    begin
      opts.parse!(ARGV)
    rescue OptionParser::InvalidOption
      $stderr.puts $!.capitalize
      exit 1
    end

    begin
      config.exec_config
    rescue Configure::Error
      raise if $DEBUG
      $stderr.puts $!.message
      $stderr.puts "Try 'ruby #{$0} --help' for detailed usage."
      exit 1
    end
  end

end

# Command line run
if __FILE__ == $0
  Configure.start_cli
end

#
#
#

class Installer

  MANIFEST  = '.installedfiles'

  FILETYPES = %w( bin lib ext data conf man doc )

  # Has this been installed previously?
  def self.uninstallable?
    File.exist?(MANIFEST)
  end

  # Configuration
  attr :config

  attr_writer :no_harm
  attr_writer :verbose

  attr_accessor :install_prefix

  # New Installer.
  def initialize(config) #:yield:
    srcroot = '.'
    objroot = '.'

    @config = config

    @srcdir = File.expand_path(srcroot)
    @objdir = File.expand_path(objroot)
    @currdir = '.'

    @verbose = false

    #self.verbose = ENV['VERBOSE'] if ENV['VERBOSE']
    #self.no_harm = ENV['NO_HARM'] if ENV['NO_HARM']

    yield(self) if block_given?
  end

  def inspect
    "#<#{self.class} #{File.basename(@srcdir)}>"
  end

  # Do not write to disk.
  def no_harm? ; @no_harm; end

  # Verbose output?
  def verbose? ; @verbose || @no_harm; end

  # Yes, very very verbose output.
  def very_verbose? ; @very_verbose; end

  def verbose_off #:yield:
    begin
      save, @verbose = verbose?, false
      yield
    ensure
      @verbose = save
    end
  end

  # Are we running an installation?
  def installation?; @installation; end
  def installation!; @installation = true; end

  #
  # Hook Script API bases
  #

  def srcdir_root
    @srcdir
  end

  def objdir_root
    @objdir
  end

  def relpath
    @currdir
  end

  # Used as a null traversal.
  def noop(rel) ; end

  def update_shebang_line(path)
    return if no_harm?
    return if config.shebang == 'never'
    old = Shebang.load(path)
    if old
      if old.args.size > 1
        $stderr.puts "warning: #{path}"
        $stderr.puts "Shebang line has too many args."
        $stderr.puts "It is not portable and your program may not work."
      end
      new = new_shebang(old)
      return if new.to_s == old.to_s
    else
      return unless config.shebang == 'all'
      new = Shebang.new(config.rubypath)
    end
    $stderr.puts "updating shebang: #{File.basename(path)}" if verbose?
    open_atomic_writer(path) {|output|
      File.open(path, 'rb') {|f|
        f.gets if old   # discard
        output.puts new.to_s
        output.print f.read
      }
    }
  end

  def new_shebang(old)
    if /\Aruby/ =~ File.basename(old.cmd)
      Shebang.new(config.rubypath, old.args)
    elsif File.basename(old.cmd) == 'env' and old.args.first == 'ruby'
      Shebang.new(config.rubypath, old.args[1..-1])
    else
      return old unless config.shebang == 'all'
      Shebang.new(config.rubypath)
    end
  end

  def open_atomic_writer(path, &block)
    tmpfile = File.basename(path) + '.tmp'
    begin
      File.open(tmpfile, 'wb', &block)
      File.rename tmpfile, File.basename(path)
    ensure
      File.unlink tmpfile if File.exist?(tmpfile)
    end
  end

  class Shebang
    def Shebang.load(path)
      line = nil
      File.open(path) {|f|
        line = f.gets
      }
      return nil unless /\A#!/ =~ line
      parse(line)
    end

    def Shebang.parse(line)
      cmd, *args = *line.strip.sub(/\A\#!/, '').split(' ')
      new(cmd, args)
    end

    def initialize(cmd, args = [])
      @cmd = cmd
      @args = args
    end

    attr_reader :cmd
    attr_reader :args

    def to_s
      "#! #{@cmd}" + (@args.empty? ? '' : " #{@args.join(' ')}")
    end
  end

  #
  # TASK install
  #

  def exec_install
    installation!  # mark that we are installing
    #rm_f MANIFEST # we'll append rather then delete
    exec_task_traverse 'install'
  end

  def install_dir_bin(rel)
    install_files targetfiles(), "#{config.bindir}/#{rel}", 0755
  end

  def install_dir_lib(rel)
    install_files libfiles(), "#{config.rbdir}/#{rel}", 0644
  end

  def install_dir_ext(rel)
    return unless extdir?(curr_srcdir())
    install_files rubyextentions('.'),
                  "#{config.sodir}/#{File.dirname(rel)}", 0555
  end

  def install_dir_data(rel)
    install_files targetfiles(), "#{config.datadir}/#{rel}", 0644
  end

  def install_dir_doc(rel)
    return if config.without_doc?
    install_files targetfiles(), "#{config.docdir}/#{rel}", 0644
  end

  def install_dir_conf(rel)
    # FIXME: should not remove current config files
    # (rename previous file to .old/.org)
    install_files targetfiles(), "#{config.sysconfdir}/#{rel}", 0644
  end

  def install_dir_man(rel)
    install_files targetfiles(), "#{config.mandir}/#{rel}", 0644
  end

  def install_files(list, dest, mode)
    mkdir_p dest, install_prefix
    list.each do |fname|
      install fname, dest, mode, install_prefix
    end
  end

  def libfiles
    glob_reject(%w(*.y *.output), targetfiles())
  end

  def rubyextentions(dir)
    ents = glob_select("*.#{dllext}", targetfiles())
    if ents.empty?
      setup_rb_error "no ruby extention exists: 'ruby #{$0} setup' first"
    end
    ents
  end

  def dllext
    RBCONFIG['DLEXT']
  end

  def targetfiles
    mapdir(existfiles() - hookfiles())
  end

  def mapdir(ents)
    ents.map {|ent|
      if File.exist?(ent)
      then ent                         # objdir
      else "#{curr_srcdir()}/#{ent}"   # srcdir
      end
    }
  end

  # picked up many entries from cvs-1.11.1/src/ignore.c
  JUNK_FILES = %w( 
    core RCSLOG tags TAGS .make.state
    .nse_depinfo #* .#* cvslog.* ,* .del-* *.olb
    *~ *.old *.bak *.BAK *.orig *.rej _$* *$

    *.org *.in .*
  )

  def existfiles
    glob_reject(JUNK_FILES, (files_of(curr_srcdir()) | files_of('.')))
  end

  def hookfiles
    %w( pre-%s post-%s pre-%s.rb post-%s.rb ).map {|fmt|
      %w( config setup install clean ).map {|t| sprintf(fmt, t) }
    }.flatten
  end

  def glob_select(pat, ents)
    re = globs2re([pat])
    ents.select {|ent| re =~ ent }
  end

  def glob_reject(pats, ents)
    re = globs2re(pats)
    ents.reject {|ent| re =~ ent }
  end

  GLOB2REGEX = {
    '.' => '\.',
    '$' => '\$',
    '#' => '\#',
    '*' => '.*'
  }

  def globs2re(pats)
    /\A(?:#{
      pats.map {|pat| pat.gsub(/[\.\$\#\*]/) {|ch| GLOB2REGEX[ch] } }.join('|')
    })\z/
  end

  #
  # TASK uninstall
  #

  def exec_uninstall
    files = File.read(MANIFEST).split("\n")
    files.each do |file|
      next if /^\#/ =~ file  # skip comments
      rm_f(file) if File.exist?(file)
    end
  end

  #
  # Traversing
  #

  #
  def exec_task_traverse(task)
    run_hook "pre-#{task}"
    FILETYPES.each do |type|
      if type == 'ext' and config.without_ext == 'yes'
        $stderr.puts 'skipping ext/* by user option' if verbose?
        next
      end
      traverse task, type, "#{task}_dir_#{type}"
    end
    run_hook "post-#{task}"
  end

  #
  def traverse(task, rel, mid)
    dive_into(rel) {
      run_hook "pre-#{task}"
      __send__ mid, rel.sub(%r[\A.*?(?:/|\z)], '')
      directories_of(curr_srcdir()).each do |d|
        traverse task, "#{rel}/#{d}", mid
      end
      run_hook "post-#{task}"
    }
  end
  
  #
  def dive_into(rel)
    return unless File.dir?("#{@srcdir}/#{rel}")

    dir = File.basename(rel)
    Dir.mkdir dir unless File.dir?(dir)
    prevdir = Dir.pwd
    Dir.chdir dir
    $stderr.puts '---> ' + rel if very_verbose?
    @currdir = rel
    yield
    Dir.chdir prevdir
    $stderr.puts '<--- ' + rel if very_verbose?
    @currdir = File.dirname(rel)
  end

  #
  def run_hook(id)
    path = [ "#{curr_srcdir()}/#{id}",
             "#{curr_srcdir()}/#{id}.rb" ].detect {|cand| File.file?(cand) }
    return unless path
    begin
      instance_eval File.read(path), path, 1
    rescue
      raise if $DEBUG
      setup_rb_error "hook #{path} failed:\n" + $!.message
    end
  end

  # File Operations
  #
  # These use: #verbose? and #no_harm?

  def binread(fname)
    File.open(fname, 'rb'){ |f|
      return f.read
    }
  end

  def mkdir_p(dirname, prefix = nil)
    dirname = prefix + File.expand_path(dirname) if prefix
    $stderr.puts "mkdir -p #{dirname}" if verbose?
    return if no_harm?

    # Does not check '/', it's too abnormal.
    dirs = File.expand_path(dirname).split(%r<(?=/)>)
    if /\A[a-z]:\z/i =~ dirs[0]
      disk = dirs.shift
      dirs[0] = disk + dirs[0]
    end
    dirs.each_index do |idx|
      path = dirs[0..idx].join('')
      Dir.mkdir path unless File.dir?(path)
    end
  end

  def rm_f(path)
    $stderr.puts "rm -f #{path}" if verbose?
    return if no_harm?
    force_remove_file path
  end

  def rm_rf(path)
    $stderr.puts "rm -rf #{path}" if verbose?
    return if no_harm?
    remove_tree path
  end

  def remove_tree(path)
    if File.symlink?(path)
      remove_file path
    elsif File.dir?(path)
      remove_tree0 path
    else
      force_remove_file path
    end
  end

  def remove_tree0(path)
    Dir.foreach(path) do |ent|
      next if ent == '.'
      next if ent == '..'
      entpath = "#{path}/#{ent}"
      if File.symlink?(entpath)
        remove_file entpath
      elsif File.dir?(entpath)
        remove_tree0 entpath
      else
        force_remove_file entpath
      end
    end
    begin
      Dir.rmdir path
    rescue Errno::ENOTEMPTY
      # directory may not be empty
    end
  end

  def move_file(src, dest)
    force_remove_file dest
    begin
      File.rename src, dest
    rescue
      File.open(dest, 'wb') {|f|
        f.write binread(src)
      }
      File.chmod File.stat(src).mode, dest
      File.unlink src
    end
  end

  def force_remove_file(path)
    begin
      remove_file path
    rescue
    end
  end

  def remove_file(path)
    File.chmod 0777, path
    File.unlink path
  end

  def install(from, dest, mode, prefix = nil)
    $stderr.puts "install #{from} #{dest}" if verbose?
    return if no_harm?

    realdest = prefix ? prefix + File.expand_path(dest) : dest
    realdest = File.join(realdest, File.basename(from)) if File.dir?(realdest)
    str = binread(from)
    if diff?(str, realdest)
      verbose_off {
        rm_f realdest if File.exist?(realdest)
      }
      File.open(realdest, 'wb') {|f|
        f.write str
      }
      File.chmod mode, realdest

      File.open("#{objdir_root()}/#{MANIFEST}", 'a') {|f|
        if prefix
          f.puts realdest.sub(prefix, '')
        else
          f.puts realdest
        end
      }
    end
  end

  def diff?(new_content, path)
    return true unless File.exist?(path)
    new_content != binread(path)
  end

  def command(*args)
    $stderr.puts args.join(' ') if verbose?
    system(*args) or raise RuntimeError,
        "system(#{args.map{|a| a.inspect }.join(' ')}) failed"
  end

  def ruby(*args)
    command config.rubyprog, *args
  end

  def make(task = nil)
    command(*[config.makeprog, task].compact)
  end

  def extdir?(dir)
    File.exist?("#{dir}/MANIFEST") or File.exist?("#{dir}/extconf.rb")
  end

  def files_of(dir)
    Dir.open(dir) {|d|
      return d.select {|ent| File.file?("#{dir}/#{ent}") }
    }
  end

  DIR_REJECT = %w( . .. CVS SCCS RCS CVS.adm .svn )

  def directories_of(dir)
    Dir.open(dir) {|d|
      return d.select {|ent| File.dir?("#{dir}/#{ent}") } - DIR_REJECT
    }
  end

  #
  # Hook Script API
  #
  # These require: #srcdir_root, #objdir_root, #relpath
  #

  #
  def get_config(key)
    config.__send__(key)
  end

  # obsolete: use metaconfig to change configuration
  # TODO: what to do with?
  def set_config(key, val)
    config[key] = val
  end

  #
  # srcdir/objdir (works only in the package directory)
  #

  def curr_srcdir
    "#{srcdir_root()}/#{relpath()}"
  end

  def curr_objdir
    "#{objdir_root()}/#{relpath()}"
  end

  def srcfile(path)
    "#{curr_srcdir()}/#{path}"
  end

  def srcexist?(path)
    File.exist?(srcfile(path))
  end

  def srcdirectory?(path)
    File.dir?(srcfile(path))
  end

  def srcfile?(path)
    File.file?(srcfile(path))
  end

  def srcentries(path = '.')
    Dir.open("#{curr_srcdir()}/#{path}") {|d|
      return d.to_a - %w(. ..)
    }
  end

  def srcfiles(path = '.')
    srcentries(path).select {|fname|
      File.file?(File.join(curr_srcdir(), path, fname))
    }
  end

  def srcdirectories(path = '.')
    srcentries(path).select {|fname|
      File.dir?(File.join(curr_srcdir(), path, fname))
    }
  end

end

#
# Ruby extensions
#

unless File.respond_to?(:read)   # Ruby 1.6 and less
  def File.read(fname)
    open(fname) {|f|
      return f.read
    }
  end
end

unless Errno.const_defined?(:ENOTEMPTY)   # Windows?
  module Errno
    class ENOTEMPTY
      # We do not raise this exception, implementation is not needed.
    end
  end
end

# for corrupted Windows' stat(2)
def File.dir?(path)
  File.directory?((path[-1,1] == '/') ? path : path + '/')
end

#
# The End
#

UberTask.new(PACKAGE, GENERATE_DOCS)

