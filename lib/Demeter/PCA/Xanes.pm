package Demeter::PCA::Xanes;
use Moose::Role;

use PDL;

has 'emin'  => (is => 'rw', isa => 'Num',    default => -30);
has 'emax'  => (is => 'rw', isa => 'Num',    default =>  70);
#has 'suffix' => (is => 'rw', isa => 'Str',    default => q{flat});
has 'space_description' => (is => 'rw', isa => 'Str',    default => q{normalized mu(E)});

sub update {
  my ($self, $data) = @_;
  $data -> _update('fft');
  return $data;
};

sub interpolate_data {
  my ($self, $data) = @_;
  $self->update($data);
  $self->data($data);
  $self->dispose($self->template('analysis', 'pca_interpolate', {suff=>$data->nsuff}));
  $self->data(q{});
  return $self;
};

sub interpolate_stack {
  my ($self) = @_;

  $self->xmin($self->emin);
  $self->xmax($self->emax);

  my @groups = @{ $self->stack };
  @groups = grep {ref($_) =~ m{Data\z}} @groups;

  my $first = shift @groups;
  $self->update($first);

  my $e1 = $first->bkg_e0 + $self->xmin;
  my $i1 = $first->iofx('energy', $e1);
  my $e2 = $first->bkg_e0 + $self->xmax;
  my $i2 = $first->iofx('energy', $e2);
  $self->observations($i2-$i1+1);
  $self->undersampled($self->observations <= $#{$self->stack});
  $first->standard;
  $self->dispose($self->template('analysis', 'pca_prep', {suff=>$first->nsuff, i1=>$i1, i2=>$i2}));

  foreach my $g (@groups) {
    $self->interpolate_data($g);
  };

  $first->unset_standard;
  $self->update_stack(0);
  return $self;
};

1;
