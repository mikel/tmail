require 'mkmf'
require 'rbconfig'

extension_name = 'base64'

arch = Config::CONFIG['arch']

FailedMessage.replace("Could not create Makefile, probably for the lack of necessary libraries and/or headers. Check the mkmf.log file for more details. You may need configuration options (see below). TMail has a pure-ruby fallback mode, so you can still use this library. To do so, set the environment variable, export NORUBYEXT='true', and gem install again.\n\n")

if ENV['NORUBYEXT'] == 'true' || arch =~ /mswin/
  # Rubygems is sending all output to dev/null :(
  STDOUT << "Native extension will be omitted."
  File.open('Makefile', 'w') do |f|
    f << "all:\n"
    f << "install:\n"
  end
else
  if (/mswin/ =~ RUBY_PLATFORM) and ENV['make'].nil?
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
