#
# tmail/Makefile
#

version = 0.10.8
datadir = $(HOME)/share
ardir   = $(HOME)/var/archive/tmail
sitedir = $(HOME)/var/www/tree

.PHONY: all lib ext doc dist site test clean

default: update all

all: lib ext

lib:
	cd lib/tmail; $(MAKE) DEBUG=true

ext:
	cd ext/tmail; $(MAKE)

update:
	update-version --version=$(version) lib/tmail/info.rb lib/tmail/scanner_r.rb ext/tmail/scanner_c/scanner_c.c

import:
	remove-cvsid amstd ../amstd/stringio.rb > lib/tmail/stringio.rb

doc:
	mkdir -p doc.ja doc.en
	compile-documents --ja --template=$(datadir)/template/manual.tmpl.ja --nocode=$(datadir)/NOCODE --refrdrc=$(datadir)/refrdrc.ja doc doc.ja
	compile-documents --en --template=$(datadir)/template/manual.tmpl.en --nocode=$(datadir)/NOCODE doc doc.en

clean:
	rm -rf doc.ja doc.en
	cd lib/tmail; make clean
	cd ext/tmail; make clean

dist:
	rm -rf tmp
	mkdir tmp
	cd tmp; cvs -Q export -r`echo V$(version) | tr . -` -d tmail-$(version) tmail
	cd tmp/tmail-$(version); rm -rf web
	cd tmp/tmail-$(version)/lib/tmail; make parser.rb
	cd tmp/tmail-$(version); make doc
	cp $(datadir)/setup.rb tmp/tmail-$(version)
	cp $(datadir)/LGPL tmp/tmail-$(version)/COPYING
	cd tmp; tar czf $(ardir)/tmail-$(version).tar.gz tmail-$(version)
	rm -rf tmp

site:
	erb web/tmail.ja.rhtml | wrap-html --template=$(datadir)/template/basic.tmpl.ja | nkf -Ej > $(sitedir)/ja/prog/tmail.html
	erb web/tmail.en.rhtml | wrap-html --template=$(datadir)/template/basic.tmpl.en > $(sitedir)/en/tmail.html
	rm -rf $(sitedir)/ja/man/tmail
	mkdir -p $(sitedir)/ja/man/tmail
	cp ChangeLog BUGS TODO $(sitedir)/ja/man/tmail
	compile-documents --ja --template=$(datadir)/template/basic.tmpl.ja --nocode=$(datadir)/NOCODE --refrdrc=$(datadir)/refrdrc.ja doc $(sitedir)/ja/man/tmail
	rm -rf $(sitedir)/en/man/tmail
	mkdir -p $(sitedir)/en/man/tmail
	cp ChangeLog BUGS TODO $(sitedir)/en/man/tmail
	compile-documents --en --template=$(datadir)/template/basic.tmpl.en --nocode=$(datadir)/NOCODE doc $(sitedir)/en/man/tmail
