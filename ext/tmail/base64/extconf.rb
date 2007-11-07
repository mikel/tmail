require 'mkmf'
require 'rbconfig'

extension_name = 'base64'

FailedMessage = "Could not create Makefile, probably for the lack of necessary libraries and/or headers. Check the mkmf.log file for more details. You may need configuration options (see below). TMail has a pure-ruby fallback mode, so you can still use this library.
To do so, set the environment variable, export RUBYGEMS_NO_COMPILE='true', and gem install again."

if ENV['RUBYGEMS_NO_COMPILE'] == 'true'
  dummy_makefile(extension_name
else
  if (/mswin/ =~ RUBY_PLATFORM) and ENV['make'].nil?
    $LIBS += " msvcprt.lib"
    #dir_config(extension_name)
    #create_makefile(extension_name, "tmail")
    create_makefile(extension_name, "tmail/#{Config::CONFIG['arch']}")
  else
    $CFLAGS += " -D_FILE_OFFSET_BITS=64"  #???
    #dir_config(extension_name)
    #create_makefile(extension_name, "tmail")
    create_makefile(extension_name, "tmail/#{Config::CONFIG['arch']}")
  end
end
