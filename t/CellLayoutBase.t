# Copyright 2008 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 11;


package MyViewer;
use strict;
use warnings;
use Gtk2 1.180;
use base 'Gtk2::Ex::CellLayout::Base';
use Glib::Object::Subclass
  Gtk2::DrawingArea::,
  interfaces => [ 'Gtk2::CellLayout' ];

sub PACK_START {
  my ($self, $cell, $expand) = @_;
  $self->{'myviewer-subclass'} = 'hello from MyViewer';
  $self->SUPER::PACK_START ($cell, $expand);
}

package main;
use Gtk2;

{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);

  is ($viewer->{'myviewer-subclass'}, 'hello from MyViewer');
  is_deeply ([$viewer->GET_CELLS], [$renderer]);
}

{
  my $viewer = MyViewer->new;
  my $r1 = Gtk2::CellRendererText->new;
  my $r2 = Gtk2::CellRendererText->new;
  $viewer->pack_start ($r1, 0);
  $viewer->pack_start ($r2, 0);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2]);

  $viewer->reorder ($r1, 1);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1]);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2]);
}

{
  my $viewer = MyViewer->new;
  my $r1 = Gtk2::CellRendererText->new;
  my $r2 = Gtk2::CellRendererText->new;
  my $r3 = Gtk2::CellRendererText->new;
  $viewer->pack_start ($r1, 0);
  $viewer->pack_start ($r2, 0);
  $viewer->pack_start ($r3, 0);

  $viewer->reorder ($r1, 0);
  is_deeply ([$viewer->GET_CELLS], [$r1, $r2, $r3]);

  $viewer->reorder ($r1, 1);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1, $r3]);

  $viewer->reorder ($r3, 0);
  is_deeply ([$viewer->GET_CELLS], [$r3, $r2, $r1]);

  $viewer->reorder ($r3, 2);
  is_deeply ([$viewer->GET_CELLS], [$r2, $r1, $r3]);
}

{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);
  is ($viewer->{'cellinfo_list'}->[0]->{'expand'}, '');
}
{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 'true');
  is ($viewer->{'cellinfo_list'}->[0]->{'expand'}, 1);
}

exit 0;
