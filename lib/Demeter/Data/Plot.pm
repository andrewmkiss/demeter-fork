package Demeter::Data::Plot;
use Moose::Role;

use Regexp::Common;
use Readonly;
Readonly my $NUMBER   => $RE{num}{real};
use List::Util qw(max);

##-----------------------------------------------------------------
## plotting methods

sub plot {
  my ($self, $space) = @_;
  my $pf  = $self->mo->plot;
  $space ||= $pf->space;
  ($space = 'kq') if (lc($space) eq 'qk');
  my $which = (lc($space) eq 'e')   ? $self->_update('fft')
            : (lc($space) eq 'k')   ? $self->_update('fft')
            : (lc($space) eq 'r')   ? $self->_update('bft')
            : (lc($space) eq 'rmr') ? $self->_update('bft')
	    : (lc($space) eq 'q')   ? $self->_update('all')
	    : (lc($space) eq 'kq')  ? $self->_update('all')
            :                        q{};

  $self->plotRmr, $pf->increment, return if (lc($space) eq 'rmr');
  $self->co->set(plot_part=>q{});
  my $command = $self->_plot_command($space);
  $self->dispose($command, "plotting");
  $pf->increment if (lc($space) ne 'e');
  if ((ref($self) =~ m{Data}) and $self->fitting) {
    foreach my $p (qw(fit res bkg)) {
      my $pp = "plot_$p";
      next if not $pf->$pp;
      next if (($p eq 'bkg') and (not $self->fit_do_bkg));
      $self->part_plot($p, $space);
      $pf->increment;
    };
    if ($pf->plot_win) {
      $self->plot_window($space);
      $pf->increment;
    };
  };
  return $self;
};
sub _plot_command {
  my ($self, $space) = @_;
  if (not $self->plottable) {
    my $class = ref $self;
    croak("$class objects are not plottable");
  };
  if ((lc($space) eq 'e') and (not ref($self) =~ m{Data})) {
    my $class = ref $self;
    croak("$class objects are not plottable in energy");
  };
  my $string = (lc($space) eq 'e')   ? $self->_plotE_command
             : (lc($space) eq 'k')   ? $self->_plotk_command
             : (lc($space) eq 'r')   ? $self->_plotR_command
             : (lc($space) eq 'rmr') ? $self->_plotRmr_command
	     : (lc($space) eq 'q')   ? $self->_plotq_command
	     : (lc($space) eq 'kq')  ? $self->_plotkq_command
             : q{};
  return $string;
};

sub _plotk_command {
  my ($self, $space) = @_;
  if (not $self->plottable) {
    my $class = ref $self;
    croak("$class objects are not plottable");
  };
  $space ||= 'k';
  my $pf  = $self->mo->plot;
  my $string = q{};
  my $group = $self->group;
  my $kw = $pf->kweight;

  my ($xlorig, $ylorig) = ($pf->xlabel, $pf->ylabel);
  my $xl = "k (\\A\\u-1\\d)" if ((not defined($xlorig)) or ($xlorig =~ /^\s*$/));
  my $yl = ($kw and ($ylorig =~ /^\s*$/))       ? sprintf("k\\u%d\\d\\gx(k) (\\A\\u-%d\\d)", $kw, $kw)
         : ((not $kw) and ($ylorig =~ /^\s*$/)) ? "\\gx(k)" # special y label for kw=0
         :                                        $ylorig;
  (my $title = $self->name||q{}) =~ s{D_E_F_A_U_L_T}{Plot of paths};
  $pf->key($self->name);
  $pf->title(sprintf("%s in %s space", $title, $space));
  $pf->xlabel($xl);
  $pf->ylabel($yl);
  $string = ($pf->New)
          ? $self->template("plot", "newk")
          : $self->template("plot", "overk");
  ## reinitialize the local plot parameters
  $pf -> reinitialize($xlorig, $ylorig);
  return $string;
};

sub _plotR_command {
  my ($self) = @_;
  if (not $self->plottable) {
    my $class = ref $self;
    croak("$class objects are not plottable");
  };
  my $pf  = $self->mo->plot;
  my $string = q{};
  my $group = $self->group;
  my %open   = ('m'=>"|",        e=>"Env[",     r=>"Re[",     i=>"Im[",     p=>"Phase[");
  my %close  = ('m'=>"|",        e=>"]",        r=>"]",       i=>"]",       p=>"]");
  my %suffix = ('m'=>"chir_mag", e=>"chir_mag", r=>"chir_re", i=>"chir_im", p=>"chir_pha");
  my $part   = lc($pf->r_pl);
  my $kw = $pf->kweight;
  my ($xl, $yl) = ($pf->xlabel, $pf->ylabel);
  $pf->xlabel("R (\\A)") if ((not defined($xl)) or ($xl =~ /^\s*$/));
  $pf->ylabel(sprintf("%s\\gx(R)%s (\\A\\u-%.3g\\d)", $open{$part}, $close{$part}, $kw+1))
    if ($yl =~ /^\s*$/);
  (my $title = $self->name||q{}) =~ s{D_E_F_A_U_L_T}{Plot of paths};
  $pf->key($self->name);
  $pf->title(sprintf("%s in R space", $title));

  $string = ($pf->New)
          ? $self->template("plot", "newr")
          : $self->template("plot", "overr");
  if ($part eq 'e') {		# envelope
    my $pm = $self->plot_multiplier;
    $self->plot_multiplier(-1*$pm);
    my $this = $self->template("plot", "overr");
    my $datalabel = $self->name;
    ## (?<+ ) is the positive zero-width look behind -- it only # }
    ## replaces the label when it follows q{key="}, i.e. it won't get
    ## confused by the same text in the title for a newplot
    $this =~ s{(?<=key=")$datalabel}{};	# ") silly emacs!
    $string .= $this;
    $self->plot_multiplier($pm);
  };

  ## reinitialize the local plot parameters
  $pf -> reinitialize(q{}, q{});
  return $string;
};

sub _plotq_command {
  my ($self) = @_;
  if (not $self->plottable) {
    my $class = ref $self;
    croak("$class objects are not plottable");
  };
  my $pf  = $self->mo->plot;
  my $string = q{};
  my $group = $self->group;
  my %open   = ('m'=>"|",        e=>"Env[",     r=>"Re[",     i=>"Im[",     p=>"Phase["   );
  my %close  = ('m'=>"|",        e=>"]",        r=>"]",       i=>"]",       p=>"]"        );
  my $part   = lc($pf->q_pl);
  my $kw = $pf->kweight;
  my ($xl, $yl) = ($pf->xlabel, $pf->ylabel);
  $pf->xlabel("k (\\A\\u-1\\d)") if ($xl =~ /^\s*$/);
  $pf->ylabel(sprintf("%s\\gx(q)%s (\\A\\u-%.3g\\d)", $open{$part}, $close{$part}, $kw))
    if ($yl =~ /^\s*$/);
  (my $title = $self->name) =~ s{D_E_F_A_U_L_T}{Plot of paths};
  $pf->key($self->name);
  $pf->title(sprintf("%s in q space", $title));

  $string = ($pf->New)
          ? $self->template("plot", "newq")
          : $self->template("plot", "overq");
  if ($part eq 'e') {		# envelope
    my $pm = $self->plot_multiplier;
    $self->plot_multiplier(-1*$pm);
    my $this = $self->template("plot", "overr");
    my $datalabel = $self->name;
    ## (?<+ ) is the positive zero-width look behind -- it only # }
    ## replaces the label when it follows q{key="}, i.e. it won't get
    ## confused by the same text in the title for a newplot
    $this =~ s{(?<=key=")$datalabel}{};	# ") silly emacs!
    $string .= $this;
    $self->plot_multiplier($pm);
  };

  ## reinitialize the local plot parameters
  $pf -> reinitialize(q{}, q{});
  return $string;
};

sub _plotkq_command {
  my ($self) = @_;
  my $pf  = $self->po;
  if (not $self->plottable) {
    my $class = ref $self;
    croak("$class objects are not plottable");
  };
  my $string = q{};
  my $save = $self->name;
  $self->name($save . " in k space");
  $string .= $self->_plotk_command('k and q');
  $pf -> increment;
  $self->name($save . " in q space");
  $string .= $self->_plotq_command;
  $self->name($save);
  return $string;
};

sub plotRmr {
  my ($self) = @_;
  croak(ref $self . " objects are not plottable") if not $self->plottable;
  my $string = q{};
  my ($lab, $yoff, $up) = ( $self->name, $self->y_offset, $self->rmr_offset );
  $self -> y_offset($yoff+$up);
  my $rpart = $self->po->r_pl;
  $self -> mo -> plot -> r_pl('m');
  my $color = $self->po->color;
  my $inc   = $self->po->increm;
  #$string .= $self->_plotR_command;
  $self -> plot;
  $self -> po -> New(0);

  $self -> y_offset($yoff);
  $self -> name(q{});
  $self -> po -> r_pl('r');
  $self -> po -> color($color);
  $self -> po -> increm($inc);
  #$string .= $self->_plotR_command;
  $self -> plot;
  #$self -> dispose($string);
  $self -> name($lab);
  $self -> po -> r_pl($rpart);
  return $self;
};


## this is obviously wrong for data of variable signal size -- those
## numbers were chosen for Iron metal
sub rmr_offset {
  my ($self) = @_;
  $self->_update('bft');
  if ($self->po->plot_rmr_offset) {
    my $kw = $self -> po -> kweight;
    return 10**($kw-1) * $self->po->offset if ($kw == 1);
  };
  return 0.6*max($self->get_array("chir_mag"));
};


sub default_k_weight {
  my ($self) = @_;
  my $data = $self->data;
  carp("Not an Demeter::Data object"), return 1 if (ref($data) !~ /Data/);
  my $kw = 1;			# return 1 is no other selected
 SWITCH: {
    $kw = sprintf("%.3f", $data->fit_karb_value), last SWITCH
      if ($data->karb and ($data->karb_value =~ $NUMBER));
    $kw = 1, last SWITCH if $data->fit_k1;
    $kw = 2, last SWITCH if $data->fit_k2;
    $kw = 3, last SWITCH if $data->fit_k3;
  };
  return $kw;
};

sub plot_window {
  my ($self, $space) = @_;
  $self->fft if (lc($space) eq 'k');
  $self->bft if (lc($space) =~ m{\Ar});
  $self->dispose($self->_prep_window_command($space));
  #if (Demeter->get_mode('template_plot') eq 'gnuplot') {
  #  $self->get_mode('external_plot_object')->gnuplot_cmd($self->_plot_window_command($space));
  #  $self->get_mode('external_plot_object')->gnuplot_pause(-1);
  #} else {
  $self->dispose($self->_plot_window_command($space), "plotting");
  #};
  ## reinitialize the local plot parameters
  $self->po->reinitialize(q{}, q{});
  return $self;
};
sub _prep_window_command {
  my ($self, $sp) = @_;
  my $space   = lc($sp);
  #my %dsuff   = (k=>'chik', r=>'chir_mag', 'q'=>'chiq_mag');
  my $suffix  = ($space =~ m{\Ar}) ? 'rwin' : 'win';
  my $string  = "\n" . $self->hashes . " plot window ___\n";
  if ($space =~ m{\Ar}) {
    $string .= $self->template("process", "prep_rwindow");
  } else {
    $string .= $self->template("process", "prep_kwindow");
  };
  return $string;
};

sub _plot_window_command {
  my ($self, $sp) = @_;
  my $space   = lc($sp);
  $self -> co -> set(window_space => $space,
		     window_size  => sprintf("%.5g", Ifeffit::get_scalar("win___dow")),
		    );
  my $string = $self->template("plot", "window");
  return $string;
};

sub plot_marker {
  my ($self, $requested, $x) = @_;
  my $command = q{};
  my @list = (ref($x) eq 'ARRAY') ? @$x : ($x);
  foreach my $xx (@list) {
    my $y = $self->yofx($requested, "", $xx);
    $command .= $self->template("plot", "marker", { x => $xx, 'y'=> $y });
  };
  #if ($self->get_mode("template_plot") eq 'gnuplot') {
  #  $self->get_mode('external_plot_object')->gnuplot_cmd($command);
  #} else {
  $self -> dispose($command, "plotting");
  #};
  return $self;
};


1;

=head1 NAME

Demeter::Data::Plot - Data plotting methods for Demeter

=head1 VERSION

This documentation refers to Demeter version 0.2.

=head1 METHODS

=over 4

=item C<plot>

This method generates a plot of the data using its attributes and the
attributes of the plot object.  Because Demeter keeps track of what
processing chores need to be done, you can be sure that the object
being plotted will always be brought up-to-date with respect to
background removal and Fourier transforms before plotting.

  $dataobject -> plot($space);
  $pathobject -> plot($space);

This method returns a reference to invoking object, so method calls
can be chained:

  $dataobject -> plot($space) -> plot_window($space);

C<$space> can be any of the following and is case insensitive:

=over 4

=item E

Make the plot in energy.

=item k

Make the plot of chi(k) in wavenumber.

=item r

Make the plot of chi(R) in distance.

=item rmr

Make a stacked plot of the magnitude and real part of chi(R).  This is
a particularly nice plot to make after a fit.

=item q

Make the plot of chi(q) (back-transformed chi(k)) in wavenumber.

=item kq

Make the plot of chi(k) along with the real part of chi(q) in
wavenumber.

=back

=item C<plot_window>

Plot the Fourier transform window in k or R space.

  $dataobject->plot_window($space);
  $pathobject->plot_window($space);

=item C<plot_marker>

Mark an arbitrary point in the data.

  $data -> plot_marker($part, $x);

or

  $data -> plot_marker($part, \@x);

The C<$part> is the suffix of the array to be marked, for example
"xmu", "der", or "chi".  The second argument can be a point to mark or
a reference to a list of points.


=item C<default_k_weight>

This returns the value of the default k-weight for a Data or Path
object.  A Data object can have up to four k-weights associated with
it: 1, 2, 3, and an arbitrary value.  This method returns the
arbitrary value (if it is defined) or the lowest of the three
remaining values (if they are defined).  If none of the four are
defined, this returns 1.  For a Path object, the associated Data
object is used to determine the return value.  An exception is thrown
using Carp::carp for other objects and 1 is returned.

    $kw = $data_object -> default_k_weight;


=back

=head1 DEPENDENCIES

Demeter's dependencies are in the F<Bundle/DemeterBundle.pm> file.

L<Moose> is the basis of Demeter.  This module is implemented as a
role and used by the L<Demeter::Data> object.  I feel obloged to admit
that I am using Moose roles in the most trivial fashion here.  This is
mostly an organization tool to keep modules small and methods
organized by common functionality.

=head1 BUGS AND LIMITATIONS

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