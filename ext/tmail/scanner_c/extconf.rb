require 'mkmf'

extension_name = 'scanner_c'

dir_config(extension_name)

#create_makefile(extension_name, 'tmail')

# Will copy to arch subdir.
require 'rbconfig'
create_makefile(extension_name, "tmail/#{Config::CONFIG['arch']}")

