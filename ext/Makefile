#
# ext/tmail/Makefile
#

.PHONY: mailscanner clean distclean

all: mailscanner

mailscanner: mailscanner/tmail/Makefile
	cd mailscanner/tmail; $(MAKE)

mailscanner/tmail/Makefile: mailscanner/tmail/extconf.rb
	cd mailscanner/tmail; ruby extconf.rb

clean:
	cd mailscanner/tmail; $(MAKE) clean

distclean:
	cd mailscanner/tmail; $(MAKE) distclean

