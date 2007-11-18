#
# ext/tmail/Makefile
#

.PHONY: scanner_c base64_c clean distclean

all: scanner_c base64

scanner_c: scanner_c/tmail/Makefile
	cd scanner_c/tmail; $(MAKE)

scanner_c/tmail/Makefile: scanner_c/tmail/extconf.rb
	cd scanner_c/tmail; ruby extconf.rb

base64_c: base64_c/tmail/Makefile
	cd base64_c/tmail; $(MAKE)

base64_c/tmail/Makefile: base64_c/tmail/extconf.rb
	cd base64_c/tmail; ruby extconf.rb

clean:
	cd base64_c/tmail; $(MAKE) clean
	cd scanner_c/tmail; $(MAKE) clean

distclean:
	cd base64_c/tmail; $(MAKE) distclean
	cd scanner_c/tmail; $(MAKE) distclean

