#
# ext/tmail/Makefile
#

.PHONY: scanner_c base64 clean distclean

all: scanner_c base64

scanner_c: scanner_c/Makefile
	cd scanner_c; $(MAKE)
scanner_c/Makefile: scanner_c/extconf.rb
	cd scanner_c; ruby extconf.rb

base64: base64/Makefile
	cd base64; $(MAKE)
base64/Makefile: base64/extconf.rb
	cd base64; ruby extconf.rb

clean:
	cd base64; $(MAKE) clean
	cd scanner_c; $(MAKE) clean

distclean:
	cd base64; $(MAKE) distclean
	cd scanner_c; $(MAKE) distclean
