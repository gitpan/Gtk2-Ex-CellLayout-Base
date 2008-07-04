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
use Test::More tests => 16;

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

ok ($Gtk2::Ex::CellLayout::Base::VERSION >= 1);
ok (Gtk2::Ex::CellLayout::Base->VERSION >= 1);

{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 0);

  is ($viewer->{'myviewer-subclass'}, 'hello from MyViewer');
  is_deeply ([$viewer->GET_CELLS], [$renderer],
             'GET_CELLS one renderer');
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
  ok (! $viewer->{'cellinfo_list'}->[0]->{'expand'},
     'expand false');
}
{
  my $viewer = MyViewer->new;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 'true');
  ok ($viewer->{'cellinfo_list'}->[0]->{'expand'},
      'expand true');
}

{
  my $liststore = Gtk2::ListStore->new ('Glib::String');
  $liststore->set_value ($liststore->append, 0 => 'Foo');
  my $viewer = MyViewer->new;
  $viewer->{'model'} = $liststore;
  my $renderer = Gtk2::CellRendererText->new;
  $viewer->pack_start ($renderer, 1);

  my $iter = $liststore->get_iter_first;
  $viewer->_set_cell_data ($iter, weight => 123);
  is ($renderer->get('weight'), 123,
      'extra setting through _set_cell_data');

  $viewer->add_attribute ($renderer, text => 0);
  $viewer->_set_cell_data ($iter);
  is ($renderer->get('text'), 'Foo',
      'attribute setting from add_attribute()');

  $viewer->clear_attributes ($renderer);
  $renderer->set (text => 'Blah');
  $viewer->_set_cell_data ($iter);
  is ($renderer->get('text'), 'Blah',
      'attribute setting gone after clear_attributes()');
}

exit 0;
