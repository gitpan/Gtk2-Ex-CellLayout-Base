#!/usr/bin/perl

# Copyright 2007, 2008 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Gtk2-Ex-CellLayout-Base',
   ABSTRACT     => 'Basic Gtk2::CellLayout interface implementation.',
   VERSION_FROM => 'lib/Gtk2/Ex/CellLayout/Base.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # Need 1.180 or higher for Gtk2::CellLayout as a
                    # GInterface from Perl.  Strictly speaking this is a
                    # prereq only of widgets which use CellLayout::Base, not
                    # ourself as such, but express it here to keep others
                    # out of trouble.
                    Gtk2 => 1.180,

                    # any version should be ok
                    Scope::Guard => 0,

                    # Gtk2 requires perl 5.8 which has List::Util and
                    # Scalar::Util builtin already actually
                    Scalar::Util => 0,
                    List::Util => 0,
                   },

   clean        => { FILES => "CellLayout-Base.html" },
  );


sub MY::postamble {
  return <<'MAKE_FRAG';

lint:
	perl -MO=Lint lib/Gtk2/Ex/CellLayout/Base.pm
	podchecker lib/Gtk2/Ex/CellLayout/Base.pm

myman:
	mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

CellLayout-Base.html: lib/Gtk2/Ex/CellLayout/Base.pm Makefile
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go \
	  lib/Gtk2/Ex/CellLayout/Base.pm >CellLayout-Base.html

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check: Gtk2-Ex-CellLayout-Base-$(VERSION).tar.gz
	year=`date +%Y`; \
	tar tvfz Gtk2-Ex-CellLayout-Base-$(VERSION).tar.gz \
	| grep $$year- \
	| sed 's:^.*Gtk2-Ex-CellLayout-Base-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat | debian/control \
	      | COPYING | MANIFEST | SIGNATURE | META.yml \
	      | t/pod.t) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i:1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(NAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(NAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(NAME)-`expr $(VERSION) - 1` \
	                       $(NAME)-$(VERSION) >tree.diff
	-less diff.tmp/tree.diff

MAKE_FRAG
}
