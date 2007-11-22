#
# ext/tmail/Makefile
#

.PHONY: scanner_c clean distclean

all: scanner_c

scanner_c: scanner_c/tmail/Makefile
	cd scanner_c/tmail; $(MAKE)

scanner_c/tmail/Makefile: scanner_c/tmail/extconf.rb
	cd scanner_c/tmail; ruby extconf.rb

clean:
	cd scanner_c/tmail; $(MAKE) clean

distclean:
	cd scanner_c/tmail; $(MAKE) distclean

