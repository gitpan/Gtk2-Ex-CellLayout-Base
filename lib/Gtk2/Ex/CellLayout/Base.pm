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

package Gtk2::Ex::CellLayout::Base;
use strict;
use warnings;
use Carp;
use List::Util;
use Scope::Guard;
use Gtk2;

our $VERSION = 1;


# gtk_cell_layout_pack_start
#
# Because calls here have been spun through GInterface, $expand will be a
# the usual Gtk2-Perl representation of a boolean, ie. either '' or 1.
#
sub PACK_START {
  my ($self, $cell, $expand) = @_;
  my $cellinfo_list = ($self->{'cellinfo_list'} ||= []);
  if (List::Util::first {$_->{'cell'} == $cell} @$cellinfo_list) {
    croak "this cell renderer already packed into this widget";
  }
  push @$cellinfo_list, { cell => $cell,
                          pack => 'start',
                          expand => $expand };
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_pack_end
sub PACK_END {
  my ($self, $cell, $expand) = @_;
  my $cellinfo_list = ($self->{'cellinfo_list'} ||= []);
  if (List::Util::first {$_->{'cell'} == $cell} @$cellinfo_list) {
    croak "this cell renderer already packed into this widget";
  }
  push @$cellinfo_list, { cell => $cell,
                          pack => 'end',
                          expand => $expand };
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_clear
sub CLEAR {
  my ($self) = @_;
  $self->{'cellinfo_list'} = [];
  $self->_cellinfo_list_changed;
}

# gtk_cell_layout_add_attribute
#
# The core widgets like Gtk2::TreeViewColumn seem a bit slack in their
# add_attributes() when the property name is the same as previously added.
# They do a list "prepend" and so end up with the oldest setting applied
# last and thus having priority.  It's hard to believe that's right, either
# an error or the latest setting would surely have to be right.  For now we
# plonk into the hash so a new setting overwrites any previous.
#
sub ADD_ATTRIBUTE {
  my ($self, $cell, $attribute, $column) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  $cellinfo->{'attributes'}->{$attribute} = $column;
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_set_cell_data_func
sub SET_CELL_DATA_FUNC {
  my ($self, $cell, $func, $userdata) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  $cellinfo->{'datafunc'} = $func;
  $cellinfo->{'datafunc_userdata'} = $userdata;
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_clear_attributes
sub CLEAR_ATTRIBUTES {
  my ($self, $cell) = @_;
  my $cellinfo =  $self->_get_cellinfo_for_cell ($cell);
  $cellinfo->{'attributes'} = {};
  $self->_cellinfo_attributes_changed;
}

# gtk_cell_layout_reorder
sub REORDER {
  my ($self, $cell, $position) = @_;
  my $cellinfo_list = $self->{'cellinfo_list'};
  foreach my $i (0 .. $#$cellinfo_list) {
    if ($cellinfo_list->[$i]->{'cell'} == $cell) {
      if ($i == $position) {
        return; # already in the right position
      }
      my $cellinfo = splice @$cellinfo_list, $i, 1;
      splice @$cellinfo_list, $position,0, $cellinfo;
      $self->_cellinfo_list_changed;
      return;
    }
  }
  croak "cell renderer not in this widget";
}

# gtk_cell_layout_get_cells (new in Gtk 2.12)
sub GET_CELLS {
  my ($self) = @_;
  return map {$_->{'cell'}} @{$self->{'cellinfo_list'}};
}


#------------------------------------------------------------------------------
# other functions

# For setting cell data, GtkCellView, GtkIconView and GtkTreeViewColumn all
# first apply attributes then run the function, so do the same here.
#
# The freeze/thaw too is the same as the core viewers.  Not sure why it's
# needed, maybe just a general principle of holding back advertising
# multiple property changes until all are done.
#
# The plain hash table used for $cellinfo->{'attributes'} will give the
# property name keys in no particular order.  That should be fine.  The
# freeze/thaw may even be a good thing in this case, if it stops anyone
# imagining they might see properties change successively in the order the
# "add_attributes" were given.
#
# The Scope::Guard for the thaw protects against an error throw leaving the
# renderer permanently frozen.  Probably there shouldn't be any errors, but
# if something strange happends don't want it wedged.  (Even if it's fairly
# unlikely anyone would be listening to notifies out of a mere renderer.)
#
sub _set_cell_data {
  my ($self, $iter) = @_;
  my $model = $self->{'model'} or return;

  foreach my $cellinfo (@{$self->{'cellinfo_list'}}) {
    my $cell = $cellinfo->{'cell'};

    if (my $ahash = $cellinfo->{'attributes'}) {
      $cell->freeze_notify;
      my $guard = Scope::Guard->new (sub { $cell->thaw_notify });
      $cell->set (map { ($_ => $model->get_value($iter,$ahash->{$_})) }
                  keys %$ahash);
    }
    if (my $func = $cellinfo->{'datafunc'}) {
      $func->($self, $cell, $model, $iter, $cellinfo->{'datafunc_userdata'});
    }
  }
}

# return the cellinfo record containing the renderer $cell
sub _get_cellinfo_for_cell {
  my ($self, $cell) = @_;
  return ((List::Util::first {$_->{'cell'} == $cell}
           @{$self->{'cellinfo_list'}})
          || croak "cell renderer not in this widget");
}



# Not yet 100% certain about these "changed" overridable call-out methods,
# it's probably going to be like the following ...

sub _cellinfo_list_changed {
  my ($self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}

sub _cellinfo_attributes_changed {
  my ($self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}

# =head1 METHOD OVERRIDES
#
# The recommended C<use base> shown in the synopsis above brings
# C<Gtk2::Ex::CellLayout::Base> into your C<@ISA> in the usual way, and also
# in the usual way you can override the functions in C<CellLayout::Base> with
# your own implementations, probably chaining up to the base ones, perhaps
# not.  The following methods in particular can be intercepted,
#
# =over 4
#
# =item C<< $self->_cellinfo_list_changed () >>
#
# This method is called by C<PACK_START>, C<PACK_END>, C<CLEAR> and C<REORDER>
# to indicate that the list of renderers has changed.  The default
# implementation does a C<queue_resize> and C<queue_draw>, expecting a new
# size for new renderers and of course new drawing.
#
# Viewer widget code might add to this if it for instance maintains additional
# data relating to the renderers.
#
# =item C<< $self->_cellinfo_attributes_changed () >>
#
# This method is called by C<ADD_ATTRIBUTE>, C<CLEAR_ATTRIBUTES> and
# C<SET_CELL_DATA_FUNC> to indicate that renderer attributes have changed.
# The default implementation does a C<queue_resize> and C<queue_draw>,
# expecting a possible new size or new drawing from different attributes.
#
# Viewer widget code might add to this, for instance to invalidate renderer
# display size data if maybe it tries to cache that for on-screen or nearby
# rows.
#
# =back


1;
__END__

=head1 NAME

Gtk2::Ex::CellLayout::Base -- basic Gtk2::CellLayout functions

=head1 SYNOPSIS

 package MyNewStyleViewer;
 use Gtk2;
 use base 'Gtk2::Ex::CellLayout::Base';

 use Glib::Object::Subclass
  Gtk2::Widget::,
  interfaces => [ 'Gtk2::CellLayout' ],
  properties => [ ... ];

 sub my_expose {
   my ($self, $event) = @_;
   $self->_set_cell_data;
   foreach my $cellinfo (@$self->{'cellinfo_list'}) {
     next unless $cell->{'pack'} eq 'start';
     $cellinfo->{'cell'}->render (...);
   }
   ...
 }

=head1 DESCRIPTION

C<Gtk2::Ex::CellLayout::Base> provides a basic set of functions for use by
new data viewer widgets written in Perl and wanting to implement the
C<Gtk2::CellLayout> interface.  This means

    PACK_START
    PACK_END
    CLEAR
    ADD_ATTRIBUTE
    CLEAR_ATTRIBUTES
    SET_CELL_DATA_FUNC
    REORDER
    GET_CELLS

The functions maintain a list of C<Gtk2::CellRenderer> objects packed into
the viewer widget, with associated attribute settings or data setup
function.

C<Gtk2::Ex::CellLayoutBase> is designed as a multiple-inheritance superclass
to be brought in with C<use base> as in the synopsis above (see L<base>).
Because of this you can enhance it or override it by writing your own
versions of the functions offered, chaining (or not) to the originals with
C<SUPER> in the usual way.

=head1 CELL INFO LIST

C<Gtk2::Ex::CellLayout::Base> keeps information on the added cell renderers
in C<< $self->{'cellinfo_list'} >> on the viewer widget.  This field is an
array reference, created when first needed.  Each element in the array is a
hash reference, with the hash containing

    cell               Gtk2::CellRenderer object
    pack               string 'start' or 'end'
    expand             boolean
    attributes         hash ref { propname => colnum }
    datafunc           code ref or undef
    datafunc_userdata  any scalar

C<cell> is the renderer object added in by C<pack_start> or C<pack_end>, and
C<expand> the flag passed in those calls.  The C<pack> field is C<"start">
or C<"end"> according to which function was used.  Those C<"start"> and
C<"end"> values are per the C<Gtk2::PackType> enumeration, though that enum
doesn't often arise in the context of a viewer widget.

C<attributes> is a hash table of property name to column number built by
C<add_attribute> or C<set_attributes>.  Likewise C<datafunc> and
C<datafunc_userdata> from C<set_cell_data_func>.  Both are used when
preparing the renderers to draw a particular row of the C<Gtk2::TreeModel>.

The widget C<size_request> and C<expose> operations are the two most obvious
places the cell information is needed.  Both will want to prepare the
renderers with data from the model then ask their size and in the case of
C<expose> do some drawing.  The following function is designed to prepare
the renderers

=over 4

=item C<< $self->_set_cell_data ($iter, [propname=>value]) >>

Set the property values in all the cell renderers packed into C<$self>,
ready to draw the model row given by C<$iter>.  The model object is expected
to be in C<< $self->{'model'} >> and the C<< $self->{'cellinfo_list'} >>
attributes described above are used.

Extra C<< propname=>value >> parameters can be given, to be applied to all
the renderers.  For example the C<is_expander> and C<is_expanded> properties
could be set according to the viewer's state (and whether the model row has
children and can be expanded).

=back

Here's a minimal C<size_request> handler for a viewer like the core
C<Gtk2::CellView> which displays a single row of a model, with each renderer
one after the other horizontally.  The width is the total of all renderers,
and the height is the maximum among them.  It could look like

    sub do_size_request {
      my ($self, $requisition) = @_;
      $iter = $self->{'model'}->get_nth_iter ($self->{'rownum'});
      my $total_width = 0;
      my $max_height = 0;

      $self->_set_cell_data ($iter);
      foreach my $cellinfo (@{$self->{'cellinfo_list'}}) {
        my $cell = $cellinfo->{'cell'};
        my (undef,undef, $width,$height) = $cell->get_size($self,undef);
        $total_width += $width;
        $max_height = max ($max_height, $height);
      }
      $requisition->width ($total_width);
      $requisition->height ($max_height);
    }
        
An C<expose> handler will be a little more complicated, firstly the cells
shouldn't drawn in C<cellinfo_list> order, but instead the C<pack_start>
ones from the left, then the C<pack_end> ones from the right.  And the
C<expand> flag is meant to indicate which cells (if any) should grow to fill
available space when there's more than needed.

=head1 OTHER NOTES

The C<cellinfo_list> idea is based on the similar cell info lists maintained
inside the core C<Gtk2::TreeViewColumn>, C<Gtk2::CellView> and
C<Gtk2::IconView> widgets.  With elements as hashes there's room for widget
code to hang extra information, like the "editing" flag of C<IconView>, or
the focus flag and calculated width C<TreeViewColumn> keeps.

The C<_set_cell_data> function provided above is also similar to what the
core widgets do.  C<Gtk2::TreeViewColumn> even makes its version of that
public as C<cell_set_cell_data>.  It's probably equally valid to setup one
renderer at a time as it's used, rather than all at once; so perhaps in the
future C<Gtk2::Ex::CellLayout::Base> might offer something for that, maybe
even as a method on the C<cellinfo_list> elements if they were blessed to
become objects.

The display layout intended by C<pack_start> and C<pack_end> isn't well
described in the C<GtkCellLayout> documentation, but it's the same as
C<GtkBox> so see there for details.  It might be wondered why
C<cellinfo_list> isn't maintained with starts and ends separated in the
first place, since that's what will be wanted for drawing.  The reason is
the C<reorder> method which works in terms of renderers added in sequence,
with C<pack_start> and C<pack_end> together, counting from 0.  This makes
more sense in C<GtkBox> where pack type can be changed later (something
C<CellLayout> doesn't do).

Perhaps in the future C<Gtk2::Ex::CellLayout::Base> could offer functions to
pick the start elements out from the ends.  But if your expose code uses two
loops in the style of say the core C<Gtk2::CellView> then it's just as easy
to skip the opposite ones as you go.  Otherwise a couple of greps and
reverse gives you all elements in display order if you really want that.
Eg.

  my @disps = (grep {$_->{'pack'} eq 'start'} @$cellinfo_list,
               reverse grep {$_->{'pack'} eq 'end'} @$cellinfo_list);

The C<GET_CELLS> method is always provided but only used if Gtk2-Perl was
compiled against Gtk version 2.12 or later where the
C<gtk_cell_layout_get_cells> function was introduced.  Within viewer widget
code if you want all the renderers (which is simply the C<cell> fields
picked out of C<cellinfo_list>) then it's suggested you call capital
C<GET_CELLS> rather than worry whether the lowercase C<get_cells> is
available or not.

=head1 SEE ALSO

C<Gtk2::CellLayout>, C<Gtk2::CellRenderer>