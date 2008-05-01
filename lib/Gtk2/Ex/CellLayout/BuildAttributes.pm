# Copyright 2007, 2008 Kevin Ryde

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

package Gtk2::Ex::CellLayout::BuildAttributes;
use strict;
use warnings;
use Gtk2;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub START_ELEMENT {
  my ($self, $context, $element_name, $attributes) = @_;

  if ($element_name eq 'attributes') {
    # nothing to do in the intro bit

  } elsif ($element_name eq 'attribute') {
    $self->{'attr_name'} = $attributes->{'name'};

  } else {
    # this is a g_warning like GtkCellLayout attributes_start_element() uses,
    # not sure if a "carp" would be more helpful
    Glib->warning (undef, "Unsupported tag for Gtk2::Ex::CellLayout::Base \"$element_name\"\n");
  }
}

sub TEXT {
  my ($self, $context, $text) = @_;
  if ($self->{'attr_name'}) {
    # add_attribute will complain for us if $text isn't a string of digits
    if (DEBUG) { print $self->{'cell_layout'}," build add_attribute ",
                   $self->{'attr_name'},"=>",$text,"\n"; }
    $self->{'cell_layout'}->add_attribute ($self->{'cell_renderer'},
                                           $self->{'attr_name'}, $text);
    $self->{'attr_name'} = undef;
  }
}

# This is called at each closing </attribute> etc.  We don't need to do
# anything, but the Gtk2-Perl code in Gtk2::Buildable insists we provide a
# method.
#
sub END_ELEMENT {
}

1;
__END__

=head1 NAME

Gtk2::Ex::CellLayout::BuildAttributes -- builder parser for renderer attributes

=head1 SYNOPSIS

 use Gtk2::Ex::CellLayout::BuildAttributes;
 my $parser = Gtk2::Ex::CellLayout::BuildAttributes->new
     (cell_layout   => $my_cell_layout_widget,
      cell_renderer => $my_cell_renderer_widget);

=head1 DESCRIPTION

C<Gtk2::Ex::CellLayout::BuildAttributes> is a C<Gtk2::Buildable> parser for
reading C<attributes> for a C<Gtk2::CellRenderer> child of a
C<Gtk2::CellLayout> type widget.

Normal use is to return a BuildAttributes object from a C<CUSTOM_TAG_START>
method of a C<Gtk2::Buildable> interface implementation, giving the
containing layout widget and the renderer just added which is to get
associated attributes.  In fact that's pretty much the sole use, and since
C<Gtk2::Ex::CallLayout::Base> already sets up to use this you're unlikely to
want it explicitly unless perhaps extending the syntax accepted, or wanting
the same attributes specification in a different context.

For reference, the syntax parsed is the C<< <attributes> >> part of the
following, in this case doing the equivalent of
C<< $viewer->add_attribute (text => 0) >>.

    <object class="MyViewer" id="foo">
      <child>
        <object class="GtkCellRendererText" id="firstrenderer"/>
        <attributes>
          <attribute name="text">0</attribute>
        </attributes>

=head1 SEE ALSO

C<Gtk2::Ex::CellLayout::Base>, C<Gtk2::CellLayout>, C<Gtk2::CellRenderer>
