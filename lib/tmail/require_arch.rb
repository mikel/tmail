require 'rbconfig'

# Attempts to require anative extension.
# Fallsback to pure-ruby versoin, if it fails.
#
# This uses Config::CONFIG['arch'] and Config::CONFIG['DLEXT']
# from rbconfig.

def require_arch(fname)
  #dext = Config::CONFIG['DLEXT']
  begin
    arch = Config::CONFIG['arch']
    #path = File.join("tmail", arch, "#{fname}.#{dext}")
    path = File.join("tmail", arch, fname)
    require path
  rescue LoadError
    require fname
  end
end


# def require_arch(fname)
#   dext = Config::CONFIG['DLEXT']
#   begin
#     if File.extname(fname) == dext
#       path = fname
#     else
#       path = File.join("tmail","#{fname}.#{dext}")
#     end
#     require path
#   rescue LoadError => e
#     begin
#       arch = Config::CONFIG['arch']
#       path = File.join("tmail", arch, "#{fname}.#{dext}")
#       require path
#     rescue LoadError
#       case path
#       when /i686/
#         path.sub!('i686', 'i586')
#       when /i586/
#         path.sub!('i586', 'i486')
#       when /i486/
#         path.sub!('i486', 'i386')
#       else
#         begin
#           require fname + '.rb'
#         rescue LoadError
#           raise e
#         end
#       end
#       retry
#     end
#   end
# end
