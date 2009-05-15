package Demeter::UI::Wx::CheckListBook;

=for Copyright
 .
 Copyright (c) 2006-2009 Bruce Ravel (bravel AT bnl DOT gov).
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

use Regexp::Common;
use Readonly;
Readonly my $NUMBER => $RE{num}{real};

use Wx qw( :everything );
use Wx::Event qw(EVT_LISTBOX EVT_LEFT_DOWN EVT_MIDDLE_DOWN EVT_RIGHT_DOWN EVT_CHECKLISTBOX EVT_LEFT_DCLICK EVT_MOUSEWHEEL);

use base 'Wx::SplitterWindow';

## height, width, ratio
sub new {
  my ($class, $parent, $id, $position, $size) = @_;
  #print join(" ", $parent, $id, $position, $size), $/;
  $position = Wx::Size->new(@$position) if (ref($position) !~ m{Point});
  $size = Wx::Size->new(@$size) if (ref($size) !~ m{Size});
  my $self = $class->SUPER::new($parent, $id, $position, $size, wxSP_NOBORDER );
  my ($w, $h) = ($size->GetWidth, $size->GetHeight);

  if (($w <= 0) or ($h <= 0)) {
    ($w = 520) if ($w <= 0);
    ($h = 300) if ($h <= 0);
    $self -> SetSize($w, $h);
  };

  #$self->{LEFT} = Wx::Panel->new( $self, -1, wxDefaultPosition, Wx::Size->new(int($w/4),$h) );
  #my $box = Wx::BoxSizer->new( wxVERTICAL );
  #$self->{LEFT} -> SetSizerAndFit($box);

  $self->{LIST} = Wx::CheckListBox->new($self, -1, wxDefaultPosition, Wx::Size->new(int($w/4),$h), [ ], wxLB_SINGLE);
  $self->{LIST} -> SetFont( Wx::Font->new( 8, wxDEFAULT, wxNORMAL, wxNORMAL, 0, "" ) );
  $self->{LIST}->{PARENT} = $self;
  EVT_LEFT_DOWN($self->{LIST}, sub{OnLeftDown(@_)});
  EVT_LEFT_DCLICK($self->{LIST}, sub{OnLeftDclick(@_)});
  EVT_MIDDLE_DOWN($self->{LIST}, sub{OnMiddleDown(@_)});
  EVT_RIGHT_DOWN($self->{LIST}, sub{OnRightDown(@_)});
  EVT_LISTBOX($self, $self->{LIST}, sub{OnList(@_)});
  EVT_CHECKLISTBOX($self, $self->{LIST}, sub{OnCheck(@_)});
  EVT_MOUSEWHEEL($self->{LIST}, sub{OnWheel(@_)});

  #$box -> Add($self->{LIST}, 1, wxGROW|wxALL, 0);

  $self->{PAGE}  = Wx::Panel->new($self, -1, wxDefaultPosition, Wx::Size->new($w-int($w/4),$h));

  $self->SplitVertically($self->{LIST}, $self->{PAGE}, -int($w)-10);


  $self->{PAGEBOX} = Wx::BoxSizer->new( wxVERTICAL );
  $self->{PAGE} -> SetSizer($self->{PAGEBOX});

  $self->{W} = $w;
  $self->{H} = $h;
  $self->{CTRL}  = 0;
  $self->{SHIFT} = 0;
  $self->InitialPage;
  return $self;
};

sub InitialPage {
  my ($self) = @_;
  $self->{VIEW}->Hide if $self->{VIEW};
  $self->{LIST}->Clear;
  $self->{LIST}->Append('Path list');
  $self->{LIST}->Select(0);
  $self->{VIEW} = Wx::Panel->new($self->{PAGE}, -1, wxDefaultPosition, Wx::Size->new($self->{W}-int($self->{W}/4),$self->{H}));
  my $hh = Wx::BoxSizer->new( wxVERTICAL );
  $hh -> Add(Wx::StaticText -> new($self->{VIEW}, -1, "Drag paths from the Feff interpretation\nlist and drop them in this space\nto add paths to this data set.", [10,10], [300,300]),
	     0, wxALL, 5);
  $self->{PAGEBOX} -> Add($self->{VIEW}, 1, wxGROW|wxALL, 5);
  $self->{LIST} -> SetClientData($end, $self->{VIEW});
  $self->{LIST} -> Show;
};

sub AddPage {
  my ($self, $page, $text, $select, $imageid) = @_;
  my $end = $self->{LIST} -> GetCount;
  $self->{LIST} -> InsertItems([$text], $end);
  $self->{LIST} -> SetClientData($end, $page);
  $self->{LIST} -> Deselect($self->{LIST}->GetSelection);
  $self->{LIST} -> Select($end) if $select;

  $page->Reparent($self->{PAGE});
  $self->{VIEW} -> Hide if ($self->{VIEW} and $self->{VIEW}->IsShown);

  $self->{VIEW}  = $page;
  $self->{VIEW} -> Show(1);
  $self->{PAGEBOX} -> Layout;
};

sub RemovePage {
  my ($self, $page) = @_;
  my ($obj, $id) = $self->page_and_id($page);
  return 0 if ($id == -1);
  my $new = ($id == 0) ? $id : $id - 1;
  $self->{VIEW} -> Hide;
  $self->{LIST} -> GetClientData($new) -> Show;
  $self->{VIEW}  = ($self->{LIST}->IsEmpty) ? q{} : $self->{LIST}->GetClientData($new);
  $self->{LIST} -> Select($new);
  $self->{LIST} -> Delete($id);
  return 1;
};

sub DeletePage {
  my ($self, $page) = @_;
  my ($obj, $id) = $self->page_and_id($page);
  return 0 if ($id == -1);
  $self->RemovePage($id);
  $obj->Destroy;
  ($self->{VIEW} = q{}) if ($self->{LIST}->IsEmpty);
  return 1;
};

sub Clear {
  my ($self, $page) = @_;
  foreach my $i (reverse(0 .. $self->GetPageCount-1)) {
    $self->DeletePage($i);
  };
};

## take and page object or a page id and return both
sub page_and_id {
  my ($self, $arg) = @_;
  my ($id, $obj) = (-1,-1,q{});
  if (ref($arg) =~ m{Wx}) {
    foreach my $pos (0 .. $self->{LIST}->GetCount-1) {
      if ($arg eq $self->{LIST}->GetClientData($pos)) {
	$id = $pos;
	$obj = $arg;
	last;
      };
    };
  } else {
    $id = $arg;
    $obj = $self->{LIST}->GetClientData($arg)
  };
  return ($obj, $id);
};

sub DeleteAllPages {
  my ($self) = @_;
  $self->{LIST}->SetSelection(wxNOT_FOUND);
  $self->InitialPage;
};

sub GetCurrentPage {
  my ($self) = @_;
  return $self->{VIEW};
};

sub GetPage {
  my ($self, $pos) = @_;
  return $self->{LIST}->GetClientData($pos);
};

sub GetPageCount {
  my ($self) = @_;
  return $self->{LIST}->GetCount;
};

sub GetPageText {
  my ($self, $pos) = @_;
  return $self->{LIST}->GetString($pos);
};

sub GetSelection {
  my ($self) = @_;
  return $self->{LIST}->GetSelection;
};
sub SetSelection {
  my ($self, $pos) = @_;
  $self->{LIST} -> SetSelection($pos);
  $self->{VIEW} -> Hide;
  $self->{LIST} -> GetClientData($pos) -> Show;
  $self->{VIEW} = $self->{LIST} -> GetClientData($pos);
  $self->{PAGEBOX} -> Layout;
};
{
  no warnings 'once';
  # alternate names
  *ChangeSelection = \ &SetSelection;
}

sub SetPageText {
  my ($self, $arg, $text) = @_;
  my ($obj, $id) = $self->page_and_id($arg);
  $self->{LIST}->SetString($id, $text);
};

#  HitTest
#  InsertPage

sub AdvanceSelection {
  my ($self, $dir) = @_;
  my $sel = $self->{LIST}->GetSelection;

  return if (($sel == 0) and (not $dir)); # already at top
  return if (($sel == $self->GetPageCount-1) and $dir); # already at bottom

  my $new = ($dir) ? $sel+1 : $sel-1;
  $self->SetSelection($new);
};

sub GetThemeBackgroundColour {
  return wxNullColour;
};

sub Check {
  my ($self, $pos, $value) = @_;
  my ($obj, $id) = $self->page_and_id($pos);
  $self->{LIST}->Check($id, $value);
  return $pos;
};
sub IsChecked {
  my ($self, $pos) = @_;
  my ($obj, $id) = $self->page_and_id($pos);
  return $self->{LIST}->IsChecked($id);
};

sub one {
  return 1;
};
sub noop {
  return 1;
};
{
  no warnings 'once';
  # alternate names
  *AssignImageList = \ &noop;
  *GetImageList	   = \ &noop;
  *SetImageList	   = \ &noop;
  *GetPageImage	   = \ &noop;
  *SetPageImage	   = \ &noop;
  *SetPadding	   = \ &noop;
  *SetPageSize	   = \ &noop;

  *GetRowCount	   = \ &one;
  *OnSelChange	   = \ &one;
}


sub OnLeftDown {
  my ($self, $event) = @_;
  if ($event->ControlDown) {
    #print "control left clicking\n";
    $self->{PARENT}->{CTRL} = 1;
    $self->{PARENT}->{NOW}  = $self->GetSelection;
  };
  if ($event->ShiftDown) {
    #print "shift left clicking\n";
    $self->{PARENT}->{SHIFT} = 1;
    $self->{PARENT}->{NOW}  = $self->GetSelection;
  };
  $event->Skip;
};
sub OnLeftDclick {
  my ($self, $event) = @_;
  #print "left double click\n";
  $self->GetParent->RenameSelection;
};

sub RenameSelection {
  my ($self) = @_;
  my $check_state = $self->{LIST}->IsChecked($self->{LIST}->GetSelection);
  my $oldname = $self->{LIST}->GetStringSelection;
  my $ted = Wx::TextEntryDialog->new( $self, "Enter the new name for \"$oldname\"", "Rename item", $oldname, wxOK|wxCANCEL, Wx::GetMousePosition);
  return if ($ted->ShowModal == wxID_CANCEL);
  my $newname = $ted->GetValue;
  return if ($newname =~ m{\A\s*\z});
  $self->{LIST}->SetString($self->{LIST}->GetSelection, $newname);
  my $page = $self->{LIST}->GetClientData($self->{LIST}->GetSelection);
  $page->Rename($newname) if $page->can('Rename');
  $self->{LIST}->Check($self->{LIST}->GetSelection, $check_state);
};

sub OnRightDown {
  my ($self, $event) = @_;
  print "right clicking\n";
  ##$event->Skip;
}
sub OnMiddleDown {
  my ($self, $event) = @_;
  print "middle clicking\n";
  ##$event->Skip;
}

sub OnList {
  my ($self, $event) = @_;
  my $sel = $event->GetSelection;
  return if ($sel == -1);
  my ($ctrl, $shift, $now) = ($self->{CTRL}, $self->{SHIFT}, $self->{NOW});
  $self->{CTRL}  =  0;
  $self->{SHIFT} =  0;
  $self->{NOW}   = -1;
  if ($ctrl) {
    my $onoff = ($self->{LIST}->IsChecked($sel)) ? 0 : 1;
    $self->{LIST}->Check($sel,$onoff);
    $self->{LIST}->Select($now);
  } elsif ($shift) {
    my ($i, $j) = sort {$a <=> $b} ($now, $sel);
    foreach my $pos ($i .. $j) {
      $self->{LIST}->Check($pos,1);
    };
    $self->{LIST}->Select($now);
  } else {
    $self->{VIEW} -> Hide;
    $self->{LIST} -> GetClientData($sel) -> Show;
    $self->{VIEW} = $self->{LIST} -> GetClientData($sel);
    $self->{PAGEBOX} -> Layout;
  };
};

sub OnCheck {
  my ($self, $event) = @_;
  my $sel = $event->GetSelection;
  #print $sel, $/;
  $event->Skip;
};

sub OnWheel {
  my ($self, $event) = @_;
  if ($event->GetWheelRotation < 0) { # scroll down, inrease selection
    $self->{PARENT}->AdvanceSelection(1);
  } else {			      # scroll up, decrease selection
    $self->{PARENT}->AdvanceSelection(0);
  };

  $event->Skip;
};
1;
