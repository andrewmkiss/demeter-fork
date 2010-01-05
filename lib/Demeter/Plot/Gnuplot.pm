package Demeter::Plot::Gnuplot;

=for Copyright
 .
 Copyright (c) 2006-2010 Bruce Ravel (bravel AT bnl DOT gov).
 All rights reserved.
 .
 This file is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See The Perl
 Artistic License.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

use autodie qw(open close);

use Moose;
extends 'Demeter::Plot';

use Carp;
use File::Spec;
use Regexp::List;
use Regexp::Optimizer;
use Regexp::Common;
use Readonly;
Readonly my $NUMBER => $RE{num}{real};
use String::Random qw(random_string);

has 'error_log' => (is => 'ro', isa => 'Str',  default => File::Spec->catfile($Demeter::mode->iwd,
									      $Demeter::mode->external_plot_object->{__error_log}));
has '+backend'  => (default => q{gnuplot});

before start_plot => sub {
  my ($self) = @_;
  $self->cleantemp;
  my $command = $self->template("plot", "start");
  $command .= $self->copyright_text;
  $self->dispose($command, "plotting");
  $self->lastplot(q{});
};

override end_plot => sub {
  my ($self) = @_;
  $self->cleantemp;
  unlink $self->error_log;
  #unlink $self->mode->external_plot_object->{__error_log}; # WTF is this for, anyway?
  $self -> mo -> external_plot_object->gnuplot_cmd("quit")
    if ($self->mo
	and
	$self->mo->external_plot_object
	and
	($self->mo->external_plot_object =~ m{Gnuplot}));
  $self -> mo -> external_plot_object( q{} );
  return $self;
};

override tempfile => sub {
  my ($self) = @_;
  my $this = File::Spec->catfile($self->stash_folder, 'gp_'.random_string('cccccccc'));
  $self->add_tempfile($this);
  return $this;
};

override legend => sub {
  my ($self, @arguments) = @_;
  my %args = @arguments;
  foreach my $which (qw(dy y x)) {
    my $kk = "key_".$which;
    $args{$which} ||= $args{$kk};
    $args{$which} ||= $self -> po -> $kk;
  };

  foreach my $key (keys %args) {
    next if ($key !~ m{\A(?:dy|x|y)\z});
    my $kk = "key_".$key;
    carp("$key must be a positive number.\n\n"), ($args{$key}=$self->po->$kk) if ($args{$key} !~ m{$NUMBER});
    carp("$key must be a positive number.\n\n"), ($args{$key}=$self->po->$kk) if ($args{$key} < 0);
    $self->$kk($args{$key});
  };
  ## this is wrong!!!
  #$self->mo->external_plot_object->gnuplot_cmd("set key inside left top");
  return $self;
};

sub file {
  my ($self, $type, $file) = @_;
  my $old = $self->get('lastplot');
  ## need to parse $old to replace replot commands with
  ## continuations so that the plot ends up in a single image
  my $command = $self->template("plot", "file", { device => $type,
						  file   => $file });
  $self -> dispose($command, "plotting");
  #$self -> dispose($old, "plotting");
  #$command = $self->template("plot", "restore");
  #$self -> dispose($command, "plotting");
  $self -> set(lastplot=>$old);
  return $self;
};

override 'font' => sub {
  my ($self, @arguments) = @_;
  my %args = @arguments;
  $args{font} ||= $args{charfont};
  $args{size} ||= $args{charsize};
  $args{font} ||= $self->co->default('gnuplot','font');
  $args{size} ||= $self->co->default('gnuplot','fontsize');
  ## need to verify that font exists...
  $self->co->set_default('gnuplot', 'font',     $args{font});
  $self->co->set_default('gnuplot', 'fontsize', $args{size});
  $self->dispose($self->template("plot", "start"), "plotting");
  return $self;
};

sub replot {
  my ($self) = @_;
  carp("Demeter::Plot::Gnuplot: Cannot replot, there is no previous plot.\n\n"), return $self if ($self->get('lastplot') =~ m{\A\s*\z});
  $self -> dispose($self->get('lastplot'), "plotting");
  return $self;
};

sub gnuplot_kylabel {
  my ($self) = @_;
  my $w = $self->kweight;
  if ($w == 1) {
    return 'k {\267} {/Symbol c}(k)&{aa}({\101})';
  } elsif ($w == 0) {
    return '{/Symbol c}(k)';
  } else {
    return sprintf('k^%s {\267} {/Symbol c}(k)&{aa}({\305}^{-%s})', $w, $w);
  };
};

sub gnuplot_rylabel {
  my ($self) = @_;
  my $w = $self->kweight;
  my $part = $self->r_pl;
  my ($open, $close) = ($part eq 'm') ? ('{/*1.25 |}',    '{/*1.25 |}')
                     : ($part eq 'r') ? ('{/*1.25 Re[}',  '{/*1.25 ]}')
                     : ($part eq 'i') ? ('{/*1.25 Im[}',  '{/*1.25 ]}')
                     : ($part eq 'p') ? ('{/*1.25 Pha[}', '{/*1.25 ]}')
		     :                  ('{/*1.25 Env[}', '{/*1.25 ]}');
  return sprintf('%s{/Symbol c}(R)%s&{aa}({\305}^{-%s})', $open, $close, $w+1);
};
sub gnuplot_qylabel {
  my ($self) = @_;
  my $w = $self->kweight;
    my $part = $self->q_pl;
  my ($open, $close) = ($part eq 'm') ? ('{/*1.25 |}',    '{/*1.25 |}')
                     : ($part eq 'r') ? ('{/*1.25 Re[}',  '{/*1.25 ]}')
                     : ($part eq 'i') ? ('{/*1.25 Im[}',  '{/*1.25 ]}')
                     : ($part eq 'p') ? ('{/*1.25 Pha[}', '{/*1.25 ]}')
		     :                  ('{/*1.25 Env[}', '{/*1.25 ]}');
  return sprintf('%s{/Symbol c}(q)%s&{aa}({\305}^{-%s})', $open, $close, $w);
};

override i0_text => sub {
  return 'I_0';
};

override copyright_text => sub {
  my ($self) = @_;
  my $string = ($self->co->default("plot", "showcopyright"))
             ? $self->template("plot", "copyright")
	     : q{};
  return $string;
};

## avoid repeating the legend entry twice for the envelope function
override fix_envelope => sub {
  my ($self, $string, $datalabel) = @_;
  ## (?<= ) is the positive zero-width look behind -- it only
  ## replaces the label when it follows q{key="}, i.e. it won't get
  ## confused by the same text in the title for a newplot
  $string =~ s{(?<=title ")$datalabel"}{"};
  return $string;
};



# this gives problems during cleanup:
#        (in cleanup) Can't call method "execute" on an undefined
#        value at /usr/local/share/perl/5.10.0/Moose/Object.pm line 53
#        during global destruction.
#__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Demeter::Plot::Gnuplot - Using Gnuplot with Demeter

=head1 VERSION

This documentation refers to Demeter version 0.4.

=head1 SYNOPSIS

  use Demeter (:plotwith=gnuplot);

or

  use Demeter;
   ... and later ...
  Demeter -> plot_with("gnuplot");

=head1 DESCRIPTION

This base class of Demeter::Plot contains methods for
interacting with Gnuplot via L<Graphics::GnuplotIF>.

=head1 METHODS

=over 4

=item C<gnuplot_start>

=item C<gnuplot_kylabel>

=item C<gnuplot_rylabel>

=item C<gnuplot_qylabel>

=back

=head1 CONFIGURATION AND ENVIRONMENT

See L<Demeter::Config> for a description of the configuration
system.  The plot and ornaments configuration groups control the
attributes of the Plot object.

=head1 DEPENDENCIES

This module requires L<Graphics::GnuplotIF> and gnuplot itself.  On a
linux machine, I strongly recommend a version of gnuplot at 4.2 or
higher so you can use the wonderful wxt terminal type.

Also

=over 4

=item L<File::Spec>

=item L<Regexp::List>

=item L<Regexp::Optimizer>

=item L<Regexp::Common>

=item L<Readonly>

=item L<String::Random>

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item *

Breakage if trying to plot a path with no data

=item *

The file method is broken -- need to replace replot commands with
continuations

=item *

Plotting parts other than fit in an rmr plot has repeated labels

=item *

Quadplot cannot currently do pre, post, or bkg dues to extensive use
of replot not being consistent with multiplot

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2010 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

