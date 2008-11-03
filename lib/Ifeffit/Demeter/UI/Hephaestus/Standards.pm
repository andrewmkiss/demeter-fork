package Ifeffit::Demeter::UI::Hephaestus::Standards;
use strict;
use warnings;
use Carp;
use Chemistry::Elements qw(get_Z get_name get_symbol);

use Wx qw( :everything );
use base 'Wx::Panel';
use Wx::Event qw(EVT_LIST_ITEM_ACTIVATED EVT_LIST_ITEM_SELECTED EVT_LISTBOX
		 EVT_BUTTON EVT_KEY_DOWN EVT_RADIOBOX EVT_FILEPICKER_CHANGED);

use Ifeffit::Demeter::UI::Standards;
my $standards = Ifeffit::Demeter::UI::Standards->new();
$standards -> ini(q{});

use Ifeffit::Demeter::UI::Hephaestus::PeriodicTable;

sub new {
  my ($class, $page, $echoarea) = @_;
  my $self = $class->SUPER::new($page, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );
  $self->{echo} = $echoarea;

  my $pt = Ifeffit::Demeter::UI::Hephaestus::PeriodicTable->new($self, 'standards_get_data');
  foreach my $i (1 .. 109) {
    my $el = get_symbol($i);
    $pt->{$el}->Disable if not $standards->element_exists($el);
  };
  $pt->{Mt}->Disable;
  my $vbox = Wx::BoxSizer->new( wxVERTICAL );
  $self->SetSizer($vbox);
  $vbox -> Add($pt, 0, wxALIGN_CENTER_HORIZONTAL|wxALL, 5);

  $vbox -> Add( 20, 10, 0, wxGROW );

  ## horizontal box for containing the rest of the controls
  my $hbox = Wx::BoxSizer->new( wxHORIZONTAL );

  $self->{databox} = Wx::StaticBox->new($self, -1, 'Standards', wxDefaultPosition, wxDefaultSize);
  $self->{databoxsizer} = Wx::StaticBoxSizer->new( $self->{databox}, wxVERTICAL );
  $self->{data} = Wx::ListBox->new($self, -1, wxDefaultPosition, wxDefaultSize,
				   [], wxLB_SINGLE|wxLB_ALWAYS_SB);
  $self->{databoxsizer} -> Add($self->{data}, 1, wxEXPAND|wxALL, 0);
  $hbox -> Add($self->{databoxsizer}, 2, wxEXPAND|wxALL, 5);
  EVT_LISTBOX( $self, $self->{data}, sub{echo_comment(@_, $self)} );

  my $controlbox = Wx::BoxSizer->new( wxVERTICAL );
  $hbox -> Add($controlbox, 1, wxEXPAND|wxALL, 5);

  $self->{howtoplot} = Wx::RadioBox->new( $self, -1, '', wxDefaultPosition, wxDefaultSize,
				     ['Show XANES', 'Show derivative'], 1, wxRA_SPECIFY_COLS);
  $controlbox -> Add($self->{howtoplot}, 0, wxEXPAND|wxALL, 5);

  $self->{plot} = Wx::Button->new($self, -1, 'Plot standard', wxDefaultPosition, [120,-1]);
  EVT_BUTTON( $self, $self->{plot}, sub{make_standards_plot(@_, $self)} );
  $controlbox -> Add($self->{plot}, 0, wxEXPAND|wxALL, 5);
  $self->{plot}->Disable;

  ## finish up
  $vbox -> Add($hbox, 1, wxEXPAND|wxALL);
  $self -> SetSizerAndFit( $vbox );

  return $self;
};

sub standards_get_data {
  my ($self, $el) = @_;
  my $z = get_Z($el);

  my @choices;
  foreach my $data ($standards->material_list) {
    next if ($data eq 'config');
    next if (lc($el) ne $standards->get($data, 'element'));
    push @choices, ucfirst($data);
  };
  return 0 unless @choices;
  $self->{plot} -> Enable;
  $self->{data} -> Set(\@choices);
  $self->{data} -> SetSelection(0);
  my $comment = join(': ', $standards->get(lc($choices[0]), 'tag'), $standards->get(lc($choices[0]), 'comment'));
  $self->{echo}->echo($comment);
  return 1;
};

sub make_standards_plot {
  my ($self, $event, $parent) = @_;
  my $busy    = Wx::BusyCursor->new();
  #my $demeter = Ifeffit::Demeter->new;
  #$demeter  -> plot_with('gnuplot');
  my $which   = ($parent->{howtoplot}->GetStringSelection =~ m{XANES}) ? 'mu' : 'deriv';
  my $choice  = $parent->{data}->GetStringSelection;
  $standards -> plot($choice, $which, 'plot');
  undef $busy;
  #undef $demeter;
  return 1;
};

sub echo_comment {
  my ($self, $event, $parent) = @_;
  my $which = lc($event->GetString);
  return if not $which;
  my $comment = join(': ', $standards->get($which, 'tag'), $standards->get($which, 'comment'));
  $self->{echo}->echo($comment);
  return 1;
};

1;


=head1 NAME

Ifeffit::Demeter::UI::Hephaestus::Standards - Hephaestus' XAS data standards utility

=head1 VERSION

This documentation refers to Ifeffit::Demeter version 0.2.

=head1 SYNOPSIS

The contents of Hephaestus' absorption utility can be added to any Wx
application.

  my $page = Ifeffit::Demeter::UI::Hephaestus::Standards->new($parent,$echoarea);
  $sizer -> Add($page, 1, wxGROW|wxEXPAND|wxALL, 0);

The arguments to the constructor method are a reference to the parent
in which this is placed and a reference to a mechanism for displaying
progress and warning messages.  The C<$echoarea> object must provide a
method called C<echo>.

C<$page> contains most of what is displayed in the main part of the
Hephaestus frame.  Only the label at the top is not included in
C<$page>.

=head1 DESCRIPTION

This utility uses a periodic table as the interface to a collection of
XAS data standards.  Each element which has data in the collection
will have an enabled button on the periodic table.  When an element's
button is pressed, each data standard with that element as the central
atom will be placed in the standards list.  The standard selected from
the list can then be plotted as XANES or derivative data.  Energies of
peaks in the XANES or derivative spectra will be marked and their
energies placed on the plot as text.  In this way, data measured at a
beamline can be compared to data standards in the collection.

=head1 CONFIGURATION


=head1 DEPENDENCIES

Demeter's dependencies are in the F<Bundle/DemeterBundle.pm> file.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

It would be nice to save the standard(s) as files or as Athena
projects.

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
