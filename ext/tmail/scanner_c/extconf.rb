require 'mkmf'
require 'rbconfig'

extension_name = 'scanner_c'

arch = Config::CONFIG['arch']

windows = (/mswin/ =~ arch) #RUBY_PLATFORM)

FailedMessage.replace("Could not create Makefile, probably for the lack of necessary libraries and/or headers. Check the mkmf.log file for more details. You may need configuration options (see below). TMail has a pure-ruby fallback mode, so you can still use this library. To do so, set the environment variable, export NORUBYEXT='true', and gem install again.\n\n")

if (ENV['NORUBYEXT'] == 'true') || windows  # TEMPORARILY ADD WINDOWS HERE
  # Rubygems is sending all output to dev/null :(
  #STDOUT << "Native extension will be omitted."
  #ENV['make'] = 'echo' # THIS DOESN"T GET TO THE PARENT PROCESS!!!

  if windows
    # LETS TRY FAKING IT OUT.
    File.open('make.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
    File.open('nmake.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
    File.chmod(0755, "make.bat", "nmake.bat")  # need?
  end
  File.open('Makefile', 'w') do |f|
    f << "all:\n"
    f << "install:\n"
  end
else
  if windows && ENV['make'].nil?
    $LIBS += " msvcprt.lib"
    #dir_config(extension_name)
    #create_makefile(extension_name, "tmail")
    create_makefile(extension_name, "tmail/#{arch}")
  else
    $CFLAGS += " -D_FILE_OFFSET_BITS=64"  #???
    #dir_config(extension_name)
    #create_makefile(extension_name, "tmail")
    create_makefile(extension_name, "tmail/#{arch}")
  end
end
