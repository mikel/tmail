require 'mkmf'
require 'rbconfig'

extension_name = 'tmailscanner'

arch = Config::CONFIG['sitearch']

windows = (/djgpp|(cyg|ms|bcc)win|mingw/ =~ arch)

# For now use pure Ruby tmailscanner if on Windows, since 
# most Window's users don't have developer tools needed.
EVN['NORUBYEXT'] = true if windows

if (ENV['NORUBYEXT'] == 'true')
  File.open('Makefile', 'w') do |f|
    f << "all:\n"
    f << "install:\n"
  end
else
  #dir_config(extension_name)
  if windows && ENV['make'].nil?
    $LIBS += " msvcprt.lib"
  else
    $CFLAGS += " -D_FILE_OFFSET_BITS=64"  #???
  end
  create_makefile(extension_name)
end

