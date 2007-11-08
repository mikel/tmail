require 'mkmf'
require 'rbconfig'

extension_name = 'scanner_c'

arch = Config::CONFIG['arch']

windows = (/mswin/ =~ arch) #RUBY_PLATFORM

if (ENV['NORUBYEXT'] == 'true') || windows  # TEMPORARILY ADD WINDOWS HERE
  # LETS TRY FAKING IT OUT.
  if windows
    File.open('make.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
    File.open('nmake.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
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
