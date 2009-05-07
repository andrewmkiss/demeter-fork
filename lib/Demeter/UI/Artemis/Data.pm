package  Demeter::UI::Artemis::Data;

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

use strict;
use warnings;

use Wx qw( :everything);
use base qw(Wx::Frame);
use Wx::Event qw(EVT_MENU EVT_CLOSE EVT_TOOL_ENTER EVT_CHECKBOX EVT_CHOICE EVT_BUTTON);
use Wx::DND;
use Wx::Perl::TextValidator;

use Demeter::UI::Artemis::Data::AddParameter;
use Demeter::UI::Wx::CheckListBook;

use List::MoreUtils qw(firstidx);

my $windows = [qw(hanning kaiser-bessel welch parzen sine)];
my $demeter = $Demeter::UI::Artemis::demeter;

use Regexp::Common;
use Readonly;
Readonly my $NUMBER => $RE{num}{real};

Readonly my $ID_DATA_RENAME  => Wx::NewId();
Readonly my $ID_DATA_DIFF    => Wx::NewId();
Readonly my $ID_DATA_TRANSFER => Wx::NewId();
Readonly my $ID_DATA_VPATH   => Wx::NewId();
Readonly my $ID_DATA_DEGEN_N => Wx::NewId();
Readonly my $ID_DATA_DEGEN_1 => Wx::NewId();
Readonly my $ID_DATA_DISCARD => Wx::NewId();
Readonly my $ID_DATA_KMAXSUGEST => Wx::NewId();
Readonly my $ID_DATA_EPSK    => Wx::NewId();
Readonly my $ID_DATA_NIDP    => Wx::NewId();

Readonly my $PATH_RENAME => Wx::NewId();
Readonly my $PATH_SHOW   => Wx::NewId();
Readonly my $PATH_ADD    => Wx::NewId();
Readonly my $PATH_CLONE  => Wx::NewId();

Readonly my $PATH_EXPORT_FEFF => Wx::NewId();
Readonly my $PATH_EXPORT_DATA => Wx::NewId();
Readonly my $PATH_EXPORT_EACH => Wx::NewId();
Readonly my $PATH_EXPORT_MARKED  => Wx::NewId();

Readonly my $PATH_SAVE_K  => Wx::NewId();
Readonly my $PATH_SAVE_R  => Wx::NewId();
Readonly my $PATH_SAVE_Q  => Wx::NewId();

Readonly my $MARK_ALL    => Wx::NewId();
Readonly my $MARK_NONE   => Wx::NewId();
Readonly my $MARK_INVERT => Wx::NewId();
Readonly my $MARK_REGEXP => Wx::NewId();
Readonly my $MARK_SS     => Wx::NewId();
Readonly my $MARK_HIGH   => Wx::NewId();
Readonly my $MARK_R      => Wx::NewId();
Readonly my $MARK_BEFORE => Wx::NewId();
Readonly my $MARK_INC    => Wx::NewId();
Readonly my $MARK_EXC    => Wx::NewId();

Readonly my $INCLUDE_ALL => Wx::NewId();
Readonly my $EXCLUDE_ALL => Wx::NewId();
Readonly my $INCLUDE_INVERT => Wx::NewId();
Readonly my $INCLUDE_MARKED => Wx::NewId();
Readonly my $EXCLUDE_MARKED => Wx::NewId();
Readonly my $EXCLUDE_AFTER => Wx::NewId();
Readonly my $INCLUDE_SS => Wx::NewId();
Readonly my $INCLUDE_HIGH => Wx::NewId();
Readonly my $INCLUDE_R => Wx::NewId();

Readonly my $DISCARD_ALL    => Wx::NewId();
Readonly my $DISCARD_MARKED => Wx::NewId();
Readonly my $DISCARD_UNMARKED => Wx::NewId();
Readonly my $DISCARD_EXCLUDED => Wx::NewId();
Readonly my $DISCARD_AFTER  => Wx::NewId();
Readonly my $DISCARD_MS     => Wx::NewId();
Readonly my $DISCARD_LOW    => Wx::NewId();
Readonly my $DISCARD_R      => Wx::NewId();

Readonly my $SUM_INCLUDED => Wx::NewId();
Readonly my $SUM_MARKED   => Wx::NewId();
Readonly my $SUM_IM       => Wx::NewId();


sub new {
  my ($class, $parent, $nset) = @_;

  my $this = $class->SUPER::new($parent, -1, "Artemis: Data controls",
				wxDefaultPosition, [860,520],
				wxCAPTION|wxMINIMIZE_BOX|wxSYSTEM_MENU|wxRESIZE_BORDER);
  $this ->{PARENT} = $parent;
  $this->make_menubar;
  $this->SetMenuBar( $this->{menubar} );
  EVT_MENU($this, -1, sub{OnMenuClick(@_)} );

  $this->{statusbar} = $this->CreateStatusBar;
  $this->{statusbar} -> SetStatusText(q{});
  #$this->{statusbar}->SetForegroundColour(Wx::Colour->new("#00ff00")); ??????
  my $hbox  = Wx::BoxSizer->new( wxHORIZONTAL );
  #my $splitter = Wx::SplitterWindow->new($this, -1, wxDefaultPosition, [900,-1], wxSP_3D);
  #$hbox->Add($splitter, 1, wxGROW|wxALL, 1);

  my $leftpane = Wx::Panel->new($this, -1, wxDefaultPosition, wxDefaultSize);
  my $left = Wx::BoxSizer->new( wxVERTICAL );
  $hbox->Add($leftpane, 0, wxGROW|wxALL, 0);

  #$left -> Add(Wx::StaticLine->new($this, -1, wxDefaultPosition, [-1, -1], wxLI_HORIZONTAL), 0, wxGROW|wxALL, 5);

  ## -------- name
  my $namebox  = Wx::BoxSizer->new( wxHORIZONTAL );
  $left    -> Add($namebox, 0, wxGROW|wxTOP|wxBOTTOM, 5);
  #$namebox -> Add(Wx::StaticText->new($leftpane, -1, "Name"), 0, wxLEFT|wxRIGHT|wxTOP, 5);
  $this->{name} = Wx::StaticText->new($leftpane, -1, q{}, wxDefaultPosition, wxDefaultSize, wxRAISED_BORDER );
  $this->{name}->SetFont( Wx::Font->new( 12, wxDEFAULT, wxNORMAL, wxBOLD, 0, "" ) );
  $namebox -> Add($this->{name}, 1, wxLEFT|wxRIGHT|wxTOP, 5);
  $namebox -> Add(Wx::StaticText->new($leftpane, -1, "CV"), 0, wxLEFT|wxRIGHT|wxTOP, 5);
  $this->{cv} = Wx::TextCtrl->new($leftpane, -1, $nset, wxDefaultPosition, [60,-1],);
  $namebox -> Add($this->{cv}, 0, wxGROW|wxLEFT|wxRIGHT|wxTOP, 3);

  ## -------- file name and record number
  my $filebox  = Wx::BoxSizer->new( wxHORIZONTAL );
  $left    -> Add($filebox, 0, wxGROW|wxALL, 0);
  $filebox -> Add(Wx::StaticText->new($leftpane, -1, "Data source: "), 0, wxALL, 5);
  $this->{datasource} = Wx::TextCtrl->new($leftpane, -1, q{}, wxDefaultPosition, wxDefaultSize, wxTE_READONLY);
  $filebox -> Add($this->{datasource}, 1, wxGROW|wxLEFT|wxRIGHT|wxTOP, 5);
  ##$this->{datasource} -> SetInsertionPointEnd;

  ## -------- single data set plot buttons
  my $buttonbox  = Wx::StaticBox->new($leftpane, -1, 'Plot this data set as ', wxDefaultPosition, [350,-1]);
  my $buttonboxsizer = Wx::StaticBoxSizer->new( $buttonbox, wxHORIZONTAL );
  $left -> Add($buttonboxsizer, 0, wxGROW|wxALL, 5);
  $this->{plot_rmr}  = Wx::Button->new($leftpane, -1, "R&mr",  wxDefaultPosition, [80,-1]);
  $this->{plot_k123} = Wx::Button->new($leftpane, -1, "&k123", wxDefaultPosition, [80,-1]);
  $this->{plot_r123} = Wx::Button->new($leftpane, -1, "&R123", wxDefaultPosition, [80,-1]);
  $this->{plot_kq}   = Wx::Button->new($leftpane, -1, "k&q",   wxDefaultPosition, [80,-1]);
  foreach my $b (qw(plot_k123 plot_r123 plot_rmr plot_kq)) {
    $buttonboxsizer -> Add($this->{$b}, 1, wxGROW|wxALL, 2);
    $this->{$b} -> SetForegroundColour(Wx::Colour->new("#000000"));
    $this->{$b} -> SetBackgroundColour(Wx::Colour->new($Demeter::UI::Artemis::demeter->co->default("happiness", "average_color")));
    $this->{$b} -> SetFont(Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, "" ) );
  };
  EVT_BUTTON($this, $this->{plot_rmr},  sub{$this->fetch_parameters;
					    $this->{data}->po->start_plot;
					    $this->{data}->plot('rmr');
					    $parent->{statusbar}->SetStatusText("Plotted \"" . $this->{data}->name . "\" as the magnitude and real part of chi(R).");
					  });
  EVT_BUTTON($this, $this->{plot_k123}, sub{$this->fetch_parameters;
					    $this->{data}->po->start_plot;
					    $this->{data}->plot('k123');
					    $parent->{statusbar}->SetStatusText("Plotted \"" . $this->{data}->name . "\" in k with three k-weights.");
					  });
  EVT_BUTTON($this, $this->{plot_r123}, sub{$this->fetch_parameters;
					    $this->{data}->po->start_plot;
					    $this->{data}->plot('r123');
					    $parent->{statusbar}->SetStatusText("Plotted \"" . $this->{data}->name . "\" in R with three k-weights.");
					  });
  EVT_BUTTON($this, $this->{plot_kq},   sub{$this->fetch_parameters;
					    $this->{data}->po->start_plot;
					    $this->{data}->plot('kqfit');
					    #$this->{data}->plot_window('k') if $this->{data}->po->plot_win;
					    $parent->{statusbar}->SetStatusText("Plotted \"" . $this->{data}->name . "\" in k- and q-space.");
					  });

  ## -------- title lines
  my $titlesbox      = Wx::StaticBox->new($leftpane, -1, 'Title lines ', wxDefaultPosition, wxDefaultSize);
  my $titlesboxsizer = Wx::StaticBoxSizer->new( $titlesbox, wxHORIZONTAL );
  $this->{titles}      = Wx::TextCtrl->new($leftpane, -1, q{}, wxDefaultPosition, [350,-1],
					   wxVSCROLL|wxHSCROLL|wxTE_MULTILINE|wxTE_READONLY|wxNO_BORDER);
  $titlesboxsizer -> Add($this->{titles}, 0, wxALL|wxALIGN_CENTER_HORIZONTAL, 0);
  $left           -> Add($titlesboxsizer, 0, wxALL|wxALIGN_CENTER_HORIZONTAL, 5);


  ## --------- toggles
  my $togglebox  = Wx::BoxSizer->new( wxHORIZONTAL );
  $left    -> Add($togglebox, 0, wxALIGN_CENTER_HORIZONTAL|wxALL, 0);
  $this->{include}    = Wx::CheckBox->new($leftpane, -1, "Include in fit", wxDefaultPosition, wxDefaultSize);
  $this->{plot_after} = Wx::CheckBox->new($leftpane, -1, "Plot after fit", wxDefaultPosition, wxDefaultSize);
  $this->{fit_bkg}    = Wx::CheckBox->new($leftpane, -1, "Fit background", wxDefaultPosition, wxDefaultSize);
  $togglebox -> Add($this->{include},    1, wxALL, 5);
  $togglebox -> Add($this->{plot_after}, 1, wxALL, 5);
  $togglebox -> Add($this->{fit_bkg},    1, wxALL, 5);
  $this->{include}    -> SetValue(1);
  $this->{plot_after} -> SetValue(1);

  ## -------- Fourier transform parameters
  my $ftbox      = Wx::StaticBox->new($leftpane, -1, 'Fourier transform parameters ', wxDefaultPosition, wxDefaultSize);
  my $ftboxsizer = Wx::StaticBoxSizer->new( $ftbox, wxVERTICAL );
  $left         -> Add($ftboxsizer, 0, wxGROW|wxALL|wxALIGN_CENTER_HORIZONTAL, 5);

  my $gbs = Wx::GridBagSizer->new( 5, 10 );

  my $label     = Wx::StaticText->new($leftpane, -1, "kmin");
  $this->{kmin} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("fft", "kmin"),
				      wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,      Wx::GBPosition->new(0,1));
  $gbs     -> Add($this->{kmin}, Wx::GBPosition->new(0,2));

  $label        = Wx::StaticText->new($leftpane, -1, "kmax");
  $this->{kmax} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("fft", "kmax"),
				      wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,      Wx::GBPosition->new(0,3));
  $gbs     -> Add($this->{kmax}, Wx::GBPosition->new(0,4));

  $label      = Wx::StaticText->new($leftpane, -1, "dk");
  $this->{dk} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("fft", "dk"),
				      wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,      Wx::GBPosition->new(0,5));
  $gbs     -> Add($this->{dk}, Wx::GBPosition->new(0,6));

  $label        = Wx::StaticText->new($leftpane, -1, "rmin");
  $this->{rmin} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("bft", "rmin"),
				      wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,        Wx::GBPosition->new(1,1));
  $gbs     -> Add($this->{rmin}, Wx::GBPosition->new(1,2));

  $label        = Wx::StaticText->new($leftpane, -1, "rmax");
  $this->{rmax} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("bft", "rmax"),
				      wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,        Wx::GBPosition->new(1,3));
  $gbs     -> Add($this->{rmax}, Wx::GBPosition->new(1,4));

  $label      = Wx::StaticText->new($leftpane, -1, "dr");
  $this->{dr} = Wx::TextCtrl  ->new($leftpane, -1, $demeter->co->default("bft", "dr"),
				    wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,      Wx::GBPosition->new(1,5));
  $gbs     -> Add($this->{dr}, Wx::GBPosition->new(1,6));

  $this->{kmin} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{kmax} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{dk}   -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{rmin} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{rmax} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{dr}   -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );

  $ftboxsizer -> Add($gbs, 0, wxALL, 5);

  my $windowsbox  = Wx::BoxSizer->new( wxHORIZONTAL );
  $ftboxsizer -> Add($windowsbox, 0, wxALIGN_LEFT|wxALL, 0);

  $label     = Wx::StaticText->new($leftpane, -1, "FT window");
  $this->{kwindow} = Wx::Choice  ->new($leftpane, -1, , wxDefaultPosition, wxDefaultSize, $windows);
  $windowsbox -> Add($label, 0, wxALL, 5);
  $windowsbox -> Add($this->{kwindow}, 0, wxALL, 2);
  $this->{kwindow}->SetSelection(firstidx {$_ eq $demeter->co->default("fft", "kwindow")} @$windows);

#   $label     = Wx::StaticText->new($leftpane, -1, "R window");
#   $this->{rwindow} = Wx::Choice  ->new($leftpane, -1, , wxDefaultPosition, wxDefaultSize, $windows);
#   $windowsbox -> Add($label, 0, wxALL, 5);
#   $windowsbox -> Add($this->{rwindow}, 0, wxALL, 2);
#   $this->{rwindow}->SetSelection(firstidx {$_ eq $demeter->co->default("bft", "rwindow")} @$windows);

  ## -------- k-weights
  my $kwbox      = Wx::StaticBox->new($leftpane, -1, 'Fitting k weights ', wxDefaultPosition, wxDefaultSize);
  my $kwboxsizer = Wx::StaticBoxSizer->new( $kwbox, wxHORIZONTAL );
  $left         -> Add($kwboxsizer, 0, wxALL|wxGROW|wxALIGN_CENTER_HORIZONTAL, 5);

  $this->{k1}   = Wx::CheckBox->new($leftpane, -1, "1",     wxDefaultPosition, wxDefaultSize);
  $this->{k2}   = Wx::CheckBox->new($leftpane, -1, "2",     wxDefaultPosition, wxDefaultSize);
  $this->{k3}   = Wx::CheckBox->new($leftpane, -1, "3",     wxDefaultPosition, wxDefaultSize);
  $this->{karb} = Wx::CheckBox->new($leftpane, -1, "other", wxDefaultPosition, wxDefaultSize);
  $this->{karb_value} = Wx::TextCtrl->new($leftpane, -1, $demeter->co->default('fit', 'karb_value'), wxDefaultPosition, wxDefaultSize);
  $kwboxsizer -> Add($this->{k1}, 1, wxALL, 5);
  $kwboxsizer -> Add($this->{k2}, 1, wxALL, 5);
  $kwboxsizer -> Add($this->{k3}, 1, wxALL, 5);
  $kwboxsizer -> Add($this->{karb}, 0, wxALL, 5);
  $kwboxsizer -> Add($this->{karb_value}, 0, wxALL, 5);
  $this->{k1}   -> SetValue($demeter->co->default('fit', 'k1'));
  $this->{k2}   -> SetValue($demeter->co->default('fit', 'k2'));
  $this->{k3}   -> SetValue($demeter->co->default('fit', 'k3'));
  $this->{karb} -> SetValue($demeter->co->default('fit', 'karb'));
  $this->{karb_value} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );

  ## -------- epsilon and phase correction
  my $extrabox  = Wx::BoxSizer->new( wxHORIZONTAL );
  $left        -> Add($extrabox, 0, wxALL|wxGROW|wxALIGN_CENTER_HORIZONTAL, 0);

  $extrabox -> Add(Wx::StaticText->new($leftpane, -1, "ε(k)"), 0, wxALL, 5);
  $this->{epsilon} = Wx::TextCtrl->new($leftpane, -1, 0, wxDefaultPosition, [50,-1]);
  $extrabox  -> Add($this->{epsilon}, 0, wxALL, 2);
  $extrabox  -> Add(Wx::StaticText->new($leftpane, -1, q{}), 1, wxALL, 5);
  $this->{pcplot}  = Wx::CheckBox->new($leftpane, -1, "Plot with phase correction", wxDefaultPosition, wxDefaultSize);
  $extrabox  -> Add($this->{pcplot}, 0, wxALL, 5);
  $this->{pcplot}->Enable(0);

  $this->{epsilon} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );

  $leftpane -> SetSizerAndFit($left);


  $hbox -> Add(Wx::StaticLine->new($this, -1, wxDefaultPosition, [4, -1], wxLI_VERTICAL), 0, wxGROW|wxALL, 5);


  ##-------- paths list for this data

  my $rightpane = Wx::Panel->new($this, -1, wxDefaultPosition, [-1,-1]);
  my $right = Wx::BoxSizer->new( wxVERTICAL );
  $hbox->Add($rightpane, 1, wxGROW|wxALL, 0);


  my $imagelist = Wx::ImageList->new( 1,1 );
  foreach my $i (0 .. 1) {
    my $icon = File::Spec->catfile($Demeter::UI::Artemis::artemis_base, 'Artemis', 'icons', "pixel.png");
    $imagelist->Add( Wx::Bitmap->new($icon, wxBITMAP_TYPE_PNG) );
  };

  $this->{pathlist} = Demeter::UI::Wx::CheckListBook->new( $rightpane, -1, wxDefaultPosition, wxDefaultSize, wxBK_LEFT );
  $right -> Add($this->{pathlist}, 1, wxGROW|wxALL, 5);
  #$this->{pathlist}->AssignImageList( $imagelist );
  #$this->{pathlist}->SetPageSize(Wx::Size->new(300,400));
  #$this->{pathlist}->SetPadding(Wx::Size->new(2,2));
  #$this->{pathlist}->SetIndent(0);



  $this->{pathlist}->SetDropTarget( Demeter::UI::Artemis::Data::DropTarget->new( $this, $this->{pathlist} ) );

  $rightpane -> SetSizerAndFit($right);


  #$splitter -> SplitVertically($leftpane, $rightpane, -500);
  #$splitter -> SetSashSize(10);

  $this -> SetSizerAndFit( $hbox );
  return $this;
};


sub make_menubar {
  my ($self) = @_;
  $self->{menubar}   = Wx::MenuBar->new;

  ## -------- chi(k) menu
  $self->{datamenu}  = Wx::Menu->new;
  $self->{datamenu}->Append($ID_DATA_RENAME,      "Rename this χ(k)",         "Rename this data set",  wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_DIFF,        "Make difference spectrum", "Make a difference spectrum using the marked paths", wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_TRANSFER,    "Transfer marked paths",    "Transfer marked paths to the plotting list", wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_VPATH,       "Make VPath",               "Make a virtual path from the set of marked paths", wxITEM_NORMAL );
  $self->{datamenu}->AppendSeparator;
  $self->{datamenu}->Append($ID_DATA_DEGEN_N,     "Set all degens to Feff",   "Set degeneracies for all paths in this data set to values from Feff",  wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_DEGEN_1,     "Set all degens to one",    "Set degeneracies for all paths in this data set to one (1)",  wxITEM_NORMAL );
  $self->{datamenu}->AppendSeparator;
  $self->{datamenu}->Append($ID_DATA_DISCARD,     "Discard this χ(k)",        "Discard this data set", wxITEM_NORMAL );
  $self->{datamenu}->AppendSeparator;
  $self->{datamenu}->Append($ID_DATA_KMAXSUGEST, "Set kmax to Ifeffit's suggestion", "Set kmax to Ifeffit's suggestion, which is computed based on the staistical noise", wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_EPSK,       "Show ε",                           "Show statistical noise for these data", wxITEM_NORMAL );
  $self->{datamenu}->Append($ID_DATA_NIDP,       "Show Nidp",                        "Show the number of independent points in these data", wxITEM_NORMAL );

  ## -------- sum menu
  $self->{summenu} = Wx::Menu->new;
  $self->{summenu}->Append($SUM_INCLUDED, "Sum included", "Make a summation of all paths for this χ(k) which are included in the fit", wxITEM_NORMAL );
  $self->{summenu}->Append($SUM_IM,       "Sum marked and included", "Make a summation of all marked paths for this χ(k) which are also included in the fit", wxITEM_NORMAL );
  $self->{summenu}->Append($SUM_MARKED,   "Sum marked",   "Make a summation of all marked paths for this χ(k) regardless of whether they are included in the fit", wxITEM_NORMAL );

  ## -------- paths menu
  my $export_menu   = Wx::Menu->new;
  $export_menu->Append($PATH_EXPORT_FEFF, "each path THIS Feff calculation",
		       "Export all path parameters from the currently displayed path to all paths in this Feff calculation", wxITEM_NORMAL );
  $export_menu->Append($PATH_EXPORT_DATA, "each path THIS data set",
		       "Export all path parameters from the currently displayed path to all paths in this data set", wxITEM_NORMAL );
  $export_menu->Append($PATH_EXPORT_EACH, "each path EVERY data set",
		       "Export all path parameters from the currently displayed path to all paths in every data set", wxITEM_NORMAL );
  $export_menu->Append($PATH_EXPORT_MARKED,  "each marked path",
		       "Export all path parameters from the currently displayed path to all marked paths", wxITEM_NORMAL );
  $export_menu->Enable($PATH_EXPORT_EACH, 0);

  my $save_menu     = Wx::Menu->new;
  $save_menu->Append($PATH_SAVE_K, "χ(k)", "Save the currently displayed path as χ(k) with all path parameters evaluated", wxITEM_NORMAL);
  $save_menu->Append($PATH_SAVE_R, "χ(R)", "Save the currently displayed path as χ(R) with all path parameters evaluated", wxITEM_NORMAL);
  $save_menu->Append($PATH_SAVE_Q, "χ(q)", "Save the currently displayed path as χ(q) with all path parameters evaluated", wxITEM_NORMAL);

  $self->{pathsmenu} = Wx::Menu->new;
  $self->{pathsmenu}->Append($PATH_RENAME, "Rename path",            "Rename the path currently on display", wxITEM_NORMAL );
  $self->{pathsmenu}->Append($PATH_SHOW,   "Show path",              "Evaluate and show the path parameters for the currently display path", wxITEM_NORMAL );
  $self->{pathsmenu}->AppendSeparator;
  $self->{pathsmenu}->Append($PATH_ADD,    "Add path parameter",     "Add path parameter to many paths", wxITEM_NORMAL );
  $self->{pathsmenu}->AppendSubMenu($export_menu, "Export all path parameters to");
  $self->{pathsmenu}->AppendSeparator;
  $self->{pathsmenu}->AppendSubMenu($save_menu, "Save this path as ..." );
  $self->{pathsmenu}->Append($PATH_CLONE, "Clone this path", "Make a copy of the currently displayed path", wxITEM_NORMAL );

  ## -------- marks menu
  $self->{markmenu}  = Wx::Menu->new;
  $self->{markmenu}->Append($MARK_ALL,    "Mark all",      "Mark all paths for this χ(k)",             wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_NONE,   "Unmark all",    "Unmark all paths for this χ(k)",           wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_INVERT, "Invert marks",  "Invert all marks for this χ(k)",           wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_REGEXP, "Mark regexp",   "Mark by regular expression for this χ(k)", wxITEM_NORMAL );
  $self->{markmenu}->AppendSeparator;
  $self->{markmenu}->Append($MARK_INC,    "Mark included", "Mark all paths included in the fit",   wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_EXC,    "Mark excluded", "Mark all paths excluded from the fit", wxITEM_NORMAL );
  $self->{markmenu}->AppendSeparator;
  $self->{markmenu}->Append($MARK_SS,     "Mark SS paths",         "Mark all single scattering paths for this χ(k)", wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_HIGH,   "Mark high importance",  "Mark all high importance paths for this χ(k)", wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_R,      "Mark paths < R",        "Mark all paths shorter than a specified path length for this χ(k)", wxITEM_NORMAL );
  $self->{markmenu}->Append($MARK_BEFORE, "Mark before current",   "Mark this path and all paths above it in the path list for this χ(k)", wxITEM_NORMAL );

  ## -------- include menu
  $self->{includemenu}  = Wx::Menu->new;
  $self->{includemenu}->Append($INCLUDE_ALL,    "Include all", "Include all paths in the fit",                     wxITEM_NORMAL );
  $self->{includemenu}->Append($EXCLUDE_ALL,    "Exclude all", "Exclude all paths from the fit",                   wxITEM_NORMAL );
  $self->{includemenu}->Append($INCLUDE_INVERT, "Invert all",  "Invert whether all paths are included in the fit", wxITEM_NORMAL );
  $self->{includemenu}->AppendSeparator;
  $self->{includemenu}->Append($INCLUDE_MARKED, "Include marked", "Include all marked paths in the fit",   wxITEM_NORMAL );
  $self->{includemenu}->Append($EXCLUDE_MARKED, "Exclude marked", "Exclude all marked paths from the fit", wxITEM_NORMAL );
  $self->{includemenu}->AppendSeparator;
  $self->{includemenu}->Append($EXCLUDE_AFTER,  "Exclude after current",   "Exclude all paths after the current from the fit", wxITEM_NORMAL );
  $self->{includemenu}->Append($INCLUDE_SS,     "Include all SS paths",    "Include all single scattering paths in the fit", wxITEM_NORMAL );
  $self->{includemenu}->Append($INCLUDE_HIGH,   "Include high importance", "Include all high importance paths in the fit", wxITEM_NORMAL );
  $self->{includemenu}->Append($INCLUDE_R,      "Include all paths < R",   "Include all paths shorter than a specified length in the fit", wxITEM_NORMAL );

  ## -------- discard menu
  $self->{discardmenu}  = Wx::Menu->new;
  $self->{discardmenu}->Append($DISCARD_ALL,      "Discard all",      "Discard all paths",          wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_MARKED,   "Discard marked",   "Discard all marked paths",   wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_UNMARKED, "Discard unmarked", "Discard all UNmarked paths", wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_EXCLUDED, "Discard excluded", "Discard all excluded paths", wxITEM_NORMAL );
  $self->{discardmenu}->AppendSeparator;
  $self->{discardmenu}->Append($DISCARD_AFTER,  "Discard after current",  "Discard all paths after the current from the fit", wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_MS,     "Discard all MS paths",   "Discard all multiple scattering paths in the fit", wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_LOW,    "Discard low importance", "Discard all low importance paths in the fit", wxITEM_NORMAL );
  $self->{discardmenu}->Append($DISCARD_R,      "Discard all paths > R",  "Discard all paths shorter than a specified length in the fit", wxITEM_NORMAL );


  $self->{menubar}->Append( $self->{datamenu},    "Da&ta" );
  $self->{menubar}->Append( $self->{summenu},     "&Sum" );
  $self->{menubar}->Append( $self->{pathsmenu},   "&Paths" );
  $self->{menubar}->Append( $self->{markmenu},    "M&arks" );
  $self->{menubar}->Append( $self->{includemenu}, "&Include" );
  $self->{menubar}->Append( $self->{discardmenu}, "Dis&card" );

  map { $self->{datamenu}   ->Enable($_,0) } ($ID_DATA_RENAME, $ID_DATA_DIFF, $ID_DATA_TRANSFER, $ID_DATA_VPATH, $ID_DATA_DISCARD);
  map { $self->{summenu}    ->Enable($_,0) } ($SUM_MARKED, $SUM_INCLUDED, $SUM_IM);
  map { $self->{pathsmenu}  ->Enable($_,0) } ($PATH_SHOW, $PATH_CLONE);
  map { $self->{discardmenu}->Enable($_,0) } ($DISCARD_ALL, $DISCARD_MARKED, $DISCARD_UNMARKED, $DISCARD_EXCLUDED,
					      $DISCARD_AFTER, $DISCARD_MS, $DISCARD_LOW, $DISCARD_R)

};

sub populate {
  my ($self, $data) = @_;
  $self->{data} = $data;
  $self->{name}->SetLabel($data->name);
  $self->{datasource}->SetValue($data->prjrecord);
  #$self->{datasource}->ShowPosition($self->{datasource}->GetLastPosition);
  $self->{titles}->SetValue(join("\n", @{ $data->titles }));
  $self->{kmin}->SetValue($data->fft_kmin);
  $self->{kmax}->SetValue($data->fft_kmax);
  $self->{dk}->SetValue($data->fft_dk);
  $self->{rmin}->SetValue($data->bft_rmin);
  $self->{rmin}->SetValue($data->bkg_rbkg + 0.05) if ($data->bft_rmin < $data->bkg_rbkg);
  $self->{rmax}->SetValue($data->bft_rmax);
  $self->{dr}->SetValue($data->bft_dr);

  EVT_CHECKBOX($self, $self->{include},    sub{$data->fit_include       ($self->{include}   ->GetValue)});
  EVT_CHECKBOX($self, $self->{plot_after}, sub{$data->fit_plot_after_fit($self->{plot_after}->GetValue)});
  EVT_CHECKBOX($self, $self->{fit_bkg},    sub{$data->fit_do_bkg        ($self->{fit_bkg}   ->GetValue)});

  EVT_CHECKBOX($self, $self->{k1},   sub{$data->fit_k1($self->{k1}->GetValue)});
  EVT_CHECKBOX($self, $self->{k2},   sub{$data->fit_k2($self->{k2}->GetValue)});
  EVT_CHECKBOX($self, $self->{k3},   sub{$data->fit_k3($self->{k3}->GetValue)});
  EVT_CHECKBOX($self, $self->{karb}, sub{$data->fit_karb($self->{karb}->GetValue)});

  EVT_CHECKBOX($self, $self->{pcplot}, sub{$data->fit_do_pcpath($self->{pcplot}->GetValue)});

  EVT_CHOICE($self, $self->{kwindow}, sub{$data->fft_kwindow($self->{kwindow}->GetStringSelection);
					  $data->bft_rwindow($self->{kwindow}->GetStringSelection);
					});
  #EVT_CHOICE($self, $self->{rwindow}, sub{$data->bft_rwindow($self->{rwindow}->GetStringSelection)});

  return $self;
}

sub fetch_parameters {
  my ($this) = @_;
  #$this->{data}->name($this->{name}->GetValue);

  my $titles = $this->{titles}->GetValue;
  my @list   = split(/\n/, $titles);
  $this->{data}->titles(\@list);

  $this->{data}->cv	            ($this->{cv}        ->GetValue	    );

  $this->{data}->fft_kmin	    ($this->{kmin}      ->GetValue	    );
  $this->{data}->fft_kmax	    ($this->{kmax}      ->GetValue	    );
  $this->{data}->fft_dk		    ($this->{dk}        ->GetValue	    );
  $this->{data}->bft_rmin	    ($this->{rmin}      ->GetValue	    );
  $this->{data}->bft_rmax	    ($this->{rmax}      ->GetValue	    );
  $this->{data}->bft_dr		    ($this->{dr}        ->GetValue	    );
  $this->{data}->fft_kwindow	    ($this->{kwindow}   ->GetStringSelection);
  $this->{data}->bft_rwindow	    ($this->{kwindow}   ->GetStringSelection);
  $this->{data}->fit_k1		    ($this->{k1}        ->GetValue	    );
  $this->{data}->fit_k2		    ($this->{k2}        ->GetValue	    );
  $this->{data}->fit_k3		    ($this->{k3}        ->GetValue	    );
  $this->{data}->fit_karb	    ($this->{karb}      ->GetValue	    );
  $this->{data}->fit_karb_value	    ($this->{karb_value}->GetValue	    );
  $this->{data}->fit_epsilon	    ($this->{epsilon}   ->GetValue	    );

  $this->{data}->fit_include	    ($this->{include}    ->GetValue         );
  $this->{data}->fit_plot_after_fit ($this->{plot_after} ->GetValue         );
  $this->{data}->fit_do_bkg	    ($this->{fit_bkg}    ->GetValue         );
  $this->{data}->fit_do_pcpath	    ($this->{pcplot}     ->GetValue         );


  ## toggles, kweights, epsilon, pcpath
};


sub OnMenuClick {
  my ($datapage, $event)  = @_;
  my $id = $event->GetId;
  #print "1  $id  $PATH_ADD\n";
 SWITCH: {

    (($id == $ID_DATA_DEGEN_N) or ($id == $ID_DATA_DEGEN_1)) and do {
      $datapage->set_degens($id);
      last SWITCH;
    };

    ($id == $ID_DATA_KMAXSUGEST) and do {
      $datapage->fetch_parameters;
      $datapage->{data}->chi_noise;
      $datapage->{kmax}->SetValue($datapage->{data}->recommended_kmax);
      $datapage->{data}->fft_kmax($datapage->{data}->recommended_kmax);
      my $text = sprintf("The number of independent points in this data set is now %.2f", $datapage->{data}->nidp);
      $datapage->{statusbar}->SetStatusText($text);
      last SWITCH;
    };
    ($id == $ID_DATA_EPSK) and do {
      $datapage->fetch_parameters;
      $datapage->{data}->chi_noise;
      my $text = sprintf("Statistical noise: ε(k) = %.2e and ε(R) = %.2e", $datapage->{data}->epsk, $datapage->{data}->epsr);
      $datapage->{statusbar}->SetStatusText($text);
      last SWITCH;
    };
    ($id == $ID_DATA_NIDP) and do {
      $datapage->fetch_parameters;
      my $text = sprintf("The number of independent points in this data set is %.2f", $datapage->{data}->nidp);
      $datapage->{statusbar}->SetStatusText($text);
      last SWITCH;
    };

    ($id == $PATH_RENAME) and do {
      $datapage->{pathlist}->RenameSelection;
      last SWITCH;
    };

    ($id == $PATH_ADD) and do {
      my $param_dialog = Demeter::UI::Artemis::Data::AddParameter->new($datapage);
      my $result = $param_dialog -> ShowModal;
      if ($result == wxID_CANCEL) {
	$datapage->{statusbar}->SetStatusText("Path parameter editing cancelled.");
	return;
      };
      my ($param, $me, $how) = ($param_dialog->{param}, $param_dialog->{me}->GetValue, $param_dialog->{apply}->GetSelection);
      $datapage->add_parameters($param, $me, $how);
      last SWITCH;
    };

    (($id == $PATH_EXPORT_FEFF) or ($id == $PATH_EXPORT_DATA) or ($id == $PATH_EXPORT_EACH) or ($id == $PATH_EXPORT_MARKED)) and do {
      $datapage->export_pp($id);
      last SWITCH;
    };

    (($id == $SUM_INCLUDED) or ($id == $SUM_MARKED) or ($id == $SUM_IM)) and do {
      $datapage->sum($id);
      last SWITCH;
    };

    (($id == $MARK_ALL) or ($id == $MARK_NONE) or ($id == $MARK_INVERT) or ($id == $MARK_REGEXP) or
     ($id == $MARK_SS)  or ($id == $MARK_HIGH) or ($id == $MARK_R)      or ($id == $MARK_BEFORE) or
     ($id == $MARK_INC) or ($id == $MARK_EXC)) and do {
      $datapage->mark($id);
      last SWITCH;
    };

    (($id == $INCLUDE_ALL)    or ($id == $EXCLUDE_ALL)    or ($id == $INCLUDE_INVERT) or
     ($id == $INCLUDE_MARKED) or ($id == $EXCLUDE_MARKED) or ($id == $EXCLUDE_AFTER) or
     ($id == $INCLUDE_SS)     or ($id == $INCLUDE_HIGH)   or ($id == $INCLUDE_R)) and do {
       $datapage->include($id);
       last SWITCH;
    };

    (($id == $DISCARD_ALL)      or ($id == $DISCARD_MARKED) or ($id == $DISCARD_UNMARKED) or 
     ($id == $DISCARD_EXCLUDED) or ($id == $DISCARD_AFTER) or
     ($id == $DISCARD_MS)       or ($id == $DISCARD_LOW)    or ($id == $DISCARD_R)) and do {
       $datapage->discard($id);
       last SWITCH;
    };

  };
};

sub set_degens {
  my ($self, $how) = @_;
  foreach my $n (0 .. $self->{pathlist}->GetPageCount-1) {
    my $page = $self->{pathlist}->GetPage($n);
    my $pathobject = $self->{pathlist}->{LIST}->GetClientData($n)->{path};
    my $value = ($how eq $ID_DATA_DEGEN_N) ? $pathobject->degen : 1;
    $page->{pp_n} -> SetValue($value);
    $pathobject->n($value);
  };
};

## how = 0 : each path this feff
## how = 1 : each path this data
## how = 2 : each path each data   (not yet)
## how = 3 : marked paths          (not yet)
sub add_parameters {
  my ($self, $param, $me, $how) = @_;
  my $displayed_path = $self->{pathlist}->GetCurrentPage;
  my $displayed_feff = $displayed_path->{path}->parent->group;
  my $which = q{};
  if ($how < 2) {
    foreach my $n (0 .. $self->{pathlist}->GetPageCount-1) {
      my $pagefeff = $self->{pathlist}->GetPage($n)->{path}->parent->group;
      next if (($how == 0) and ($pagefeff ne $displayed_feff));
      $self->{pathlist}->GetPage($n)->{"pp_$param"}->SetValue($me);
    };
    $which = ($how == 0) ? "every path in this Feff calculation" : "every path in this data set";
  } elsif ($how == 2) {
    $which = "every path in every data set";
  } else {
    foreach my $n (0 .. $self->{pathlist}->GetPageCount-1) {
      next if (not $self->{pathlist}->IsChecked($n));
      $self->{pathlist}->GetPage($n)->{"pp_$param"}->SetValue($me);
    };
    $which = "the marked paths";
  };
  $self->{statusbar}->SetStatusText("Set $param to \"$me\" for $which." );
};

sub export_pp {
  my ($self, $mode) = @_;
  my $how = ($mode == $PATH_EXPORT_FEFF)   ? 0
          : ($mode == $PATH_EXPORT_DATA)   ? 1
          : ($mode == $PATH_EXPORT_EACH)   ? 2
          : ($mode == $PATH_EXPORT_MARKED) ? 3
	  :                                  $mode;
  my $npaths = $self->{pathlist}->GetPageCount-1;
  my $displayed_path = $self->{pathlist}->GetCurrentPage;
  my $displayed_feff = $displayed_path->{path}->parent->group;

  foreach my $i (0 .. $npaths) {
    next if ($self->{pathlist}->GetSelection == $i);
    foreach my $pp (qw(s02 e0 delr sigma2 ei third fourth)) {
      $self->add_parameters($pp, $displayed_path->{"pp_$pp"}->GetValue, $how);
    };
  };
  my $which = ('each path in this Feff calculation',
	       'each path in this data set',
	       'each path in each data set',
	       'the marked paths')[$how];
  $self->{statusbar}->SetStatusText("Exported these path parameters to $which." );
};


sub mark {
  my ($self, $mode) = @_;
  my $how = ($mode == $MARK_ALL)    ? 'all'
          : ($mode == $MARK_NONE)   ? 'none'
          : ($mode == $MARK_INVERT) ? 'invert'
          : ($mode == $MARK_REGEXP) ? 'regexp'
          : ($mode == $MARK_SS)     ? 'ss'
          : ($mode == $MARK_HIGH)   ? 'high'
          : ($mode == $MARK_R)      ? 'r'
          : ($mode == $MARK_BEFORE) ? 'before'
          : ($mode == $MARK_INC)    ? 'included'
          : ($mode == $MARK_EXC)    ? 'excluded'
          :                            $mode;
 SWITCH: {
    (($how eq 'all') or ($how eq 'none')) and do {
      my $onoff = ($how eq 'all') ? 1 : 0;
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	$self->{pathlist}->Check($i, $onoff);
      };
      my $word = ($how eq 'all') ? 'Marked' : 'Unmarked';
      $self->{statusbar}->SetStatusText("$word all paths.");
      last SWITCH;
    };
    ($how eq 'invert') and do {
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $this = $self->{pathlist}->IsChecked($i);
	$self->{pathlist}->Check($i, not $this);
      };
      $self->{statusbar}->SetStatusText("Inverted all marks.");
      last SWITCH;
    };
    ($how eq 'regexp') and do {
      my $regex = q{};
      my $ted = Wx::TextEntryDialog->new( $self, "Mark paths matching this regular expression:", "Enter a regular expression", q{}, wxOK|wxCANCEL, Wx::GetMousePosition);
      if ($ted->ShowModal == wxID_CANCEL) {
	$self->{statusbar}->SetStatusText("Path marking cancelled.");
	return;
      };
      $regex = $ted->GetValue;
      my $re;
      my $is_ok = eval '$re = qr/$regex/';
      if (not $is_ok) {
	$self->{PARENT}->{statusbar}->SetStatusText("Oops!  \"$regex\" is not a valid regular expression");
	return;
      };
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	$self->{pathlist}->Check($i, 1) if ($self->{pathlist}->GetPageText($i) =~ m{$re});
      };
      $self->{statusbar}->SetStatusText("Marked all paths matching /$regex/.");
      last SWITCH;
    };

    ($how eq 'ss') and do {
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $path = $self->{pathlist}->GetPage($i)->{path};
	$self->{pathlist}->Check($i, 1) if ($path->sp->nleg == 2);
      };
      $self->{statusbar}->SetStatusText("Marked all single scattering paths.");
      last SWITCH;
    };
    ($how eq 'high') and do {
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $path = $self->{pathlist}->GetPage($i)->{path};
	$self->{pathlist}->Check($i, 1) if ($path->sp->weight==2);
      };
      $self->{statusbar}->SetStatusText("Marked all high importance paths.");
      last SWITCH;
    };
    ($how eq 'r') and do {
      my $ted = Wx::TextEntryDialog->new( $self, "Mark paths shorter than this path length:", "Enter a path length", q{}, wxOK|wxCANCEL, Wx::GetMousePosition);
      if ($ted->ShowModal == wxID_CANCEL) {
	$self->{statusbar}->SetStatusText("Path marking cancelled.");
	return;
      };
      my $r = $ted->GetValue;
      if ($r !~ m{$NUMBER}) {
	$self->{statusbar}->SetStatusText("Oops!  That wasn't a number.");
	return;
      };
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $path = $self->{pathlist}->GetPage($i)->{path};
	$self->{pathlist}->Check($i, 1) if ($path->sp->fuzzy<$r);
      };
      $self->{statusbar}->SetStatusText("Marked all paths shorter than $r " . chr(197) . '.');
      last SWITCH;
    };

    ($how eq 'before') and do {
      my $sel = $self->{pathlist}->GetSelection;
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	last if ($i > $sel);
	$self->{pathlist}->Check($i, 1);
      };
      $self->{statusbar}->SetStatusText("Marked this path and all paths before this one.");
      last SWITCH;
    };

    ($how eq 'included') and do {
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $path = $self->{pathlist}->GetPage($i)->{path};
	$self->{pathlist}->Check($i, 1) if $path->include;
      };
      $self->{statusbar}->SetStatusText("Marked all paths included in the fit.");
      last SWITCH;
    };

    ($how eq 'excluded') and do {
      foreach my $i (0 .. $self->{pathlist}->GetPageCount-1) {
	my $path = $self->{pathlist}->GetPage($i)->{path};
	$self->{pathlist}->Check($i, 1) if not $path->include;
      };
      $self->{statusbar}->SetStatusText("Marked all paths excluded from the fit.");
      last SWITCH;
    };
  };
};

sub include {
  my ($self, $mode) = @_;
  my $how = ($mode == $INCLUDE_ALL)    ? 'all'
          : ($mode == $EXCLUDE_ALL)    ? 'none'
          : ($mode == $INCLUDE_INVERT) ? 'invert'
          : ($mode == $INCLUDE_MARKED) ? 'marked'
          : ($mode == $EXCLUDE_MARKED) ? 'marked_none'
          : ($mode == $EXCLUDE_AFTER)  ? 'after'
          : ($mode == $INCLUDE_SS)     ? 'ss'
          : ($mode == $INCLUDE_HIGH)   ? 'high'
          : ($mode == $INCLUDE_R)      ? 'r'
          :                              $mode;

  my $npaths = $self->{pathlist}->GetPageCount-1;
 SWITCH: {
    ($how eq 'all') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	$pathpage->{include}->SetValue(1);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Included all paths in the fit.");
      last SWITCH;
    };

    ($how eq 'none') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	$pathpage->{include}->SetValue(0);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Excluded all paths from the fit.");
      last SWITCH;
    };

    ($how eq 'invert') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	my $onoff = ($pathpage->{include}->IsChecked) ? 0 : 1;
	$pathpage->{include}->SetValue($onoff);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Inverted which paths are included in the fit.");
      last SWITCH;
    };

    ($how eq 'marked') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	next if not $self->{pathlist}->IsChecked($i);
	$pathpage->{include}->SetValue(1);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Included marked paths in the fit.");
      last SWITCH;
    };

    ($how eq 'marked_none') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	next if not $self->{pathlist}->IsChecked($i);
	$pathpage->{include}->SetValue(0);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Excluded marked paths from the fit.");
      last SWITCH;
    };

    ($how eq 'after') and do {
      my $sel = $self->{pathlist}->GetSelection;
      foreach my $i (0 .. $npaths) {
	next if ($i <= $sel);
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	$pathpage->{include}->SetValue(0);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Excluded all paths after the one currently displayed from the fit.");
      last SWITCH;
    };

    ($how eq 'ss') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	my $path = $pathpage->{path};
	next if not ($path->sp->nleg == 2);
	$pathpage->{include}->SetValue(1);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Included all single scattering paths in the fit.");
      last SWITCH;
    };

    ($how eq 'high') and do {
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	my $path = $pathpage->{path};
	next if not ($path->sp->weight == 2);
	$pathpage->{include}->SetValue(1);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Included all high importance paths in the fit.");
      last SWITCH;
    };

    ($how eq 'r') and do {
      my $ted = Wx::TextEntryDialog->new( $self, "Include shorter than this path length:", "Enter a path length", q{}, wxOK|wxCANCEL, Wx::GetMousePosition);
      if ($ted->ShowModal == wxID_CANCEL) {
	$self->{statusbar}->SetStatusText("Path inclusion cancelled.");
	return;
      };
      my $r = $ted->GetValue;
      if ($r !~ m{$NUMBER}) {
	$self->{statusbar}->SetStatusText("Oops!  That wasn't a number.");
	return;
      };
      foreach my $i (0 .. $npaths) {
	my $pathpage = $self->{pathlist}->{LIST}->GetClientData($i);
	my $path = $pathpage->{path};
	next if ($path->sp->fuzzy > $r);
	$pathpage->{include}->SetValue(1);
	$pathpage->include_label(0,$i);
      };
      $self->{statusbar}->SetStatusText("Included all paths shorter than $r " . chr(197) . '.');
      last SWITCH;
    };


  };
};

sub discard {
  my ($self, $mode) = @_;
  my $how = ($mode == $DISCARD_ALL)      ? 'all'
          : ($mode == $DISCARD_MARKED)   ? 'marked'
          : ($mode == $DISCARD_UNMARKED) ? 'unmarked'
          : ($mode == $DISCARD_EXCLUDED) ? 'excluded'
	  : ($mode == $DISCARD_AFTER)    ? 'after'
	  : ($mode == $DISCARD_MS)       ? 'ms'
          : ($mode == $DISCARD_LOW)      ? 'low'
          : ($mode == $DISCARD_R)        ? 'r'
          :                                $mode;
  print "discarding $how\n";
};

sub sum {
  my ($self, $mode) = @_;
  my $how = ($mode == $SUM_INCLUDED) ? 'included'
          : ($mode == $SUM_MARKED)   ? 'marked'
          : ($mode == $SUM_IM)       ? 'included and marked'
          :                            $mode;
  print "summing $how\n";
};

package Demeter::UI::Artemis::Data::DropTarget;

use Wx qw( :everything);
use base qw(Wx::DropTarget);
use Demeter::UI::Artemis::DND::PathDrag;
use Demeter::UI::Artemis::Path;

use Regexp::List;
my $opt  = Regexp::List->new;

sub new {
  my $class = shift;
  my $this = $class->SUPER::new;

  my $data = Demeter::UI::Artemis::DND::PathDrag->new();
  $this->SetDataObject( $data );
  $this->{DATA} = $data;
  $this->{PARENT} = $_[0];
  $this->{BOOK}   = $_[1];

  return $this;
};

#sub data { $_[0]->{DATA} }
#sub textctrl { $_[0]->{TEXTCTRL} }

sub OnData {
  my ($this, $x, $y, $def) = @_;
  $this->GetData;		# this line is what transfers the data from the Source to the Target
  my $book  = $this->{BOOK};
  $book->DeletePage(0) if $book->GetPage(0) =~ m{Panel};
  my $spref = $this->{DATA}->{Data};
  my @sparray = map { $demeter->mo->fetch("ScatteringPath", $_) } @$spref;
  foreach my $sp ( @sparray ) {
    my $thispath = Demeter::Path->new(
				      parent => $sp->feff,
				      data   => $this->{PARENT}->{data},
				      sp     => $sp,
				      degen  => $sp->n,
				     );
    my $label = $thispath->label;

    my $page = Demeter::UI::Artemis::Path->new($book, $thispath, $this->{PARENT});

    $book->AddPage($page, $label, 1, 0);
    $page->include_label;
  };

  return $def;
};


1;