#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;

&DATA;

($sek,$min,$hour,$day,$mno,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
$time = sprintf("%02d:%02d:%02d",$hour,$min, $sek);

use CGI;

$q = new CGI;
$ip = $q->remote_addr(); ## print the user ip address

$stamp = $ip.$au{user};
$stamp =~ s/\.//g;
$stamp =~ s/\://g;
$stamp = sprintf("%x", $stamp);

if (-e "$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/") {

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.overview.pdf`;

}
else {

$URL = "http://www.google.com/";
print "Location: $URL\n\n";

exit();}

$armlength = $au{arm};
$links = $au{links}; #anzahl der arme
$detectorname = $au{name};

if ($links eq "2") {$shape="two"}
elsif ($links eq "12") {$shape="oct"}
else {$shape="tri"}

open REPORT, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.overview.tex" or die $!;

print REPORT << "END";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Short Sectioned Assignment
% LaTeX Template
% Version 1.0 (5/5/12)
%
% This template has been downloaded from:
% http://www.LaTeXTemplates.com
%
% Original author:
% Frits Wenneker (http://www.howtotex.com)
%
% License:
% CC BY-NC-SA 3.0 (http://creativecommons.org/licenses/by-nc-sa/3.0/)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%----------------------------------------------------------------------------------------
%	PACKAGES AND OTHER DOCUMENT CONFIGURATIONS
%----------------------------------------------------------------------------------------

\\documentclass[paper=a4, fontsize=11pt]{scrartcl} % A4 paper and 11pt font size

\\usepackage{geometry}
\\geometry{a4paper,left=28mm,right=28mm, top=32mm, bottom=4.8cm} 

\\usepackage[T1]{fontenc} % Use 8-bit encoding that has 256 glyphs
\\usepackage{fourier} % Use the Adobe Utopia font for the document - comment this line to return to the LaTeX default
\\usepackage[english]{babel} % English language/hyphenation
\\usepackage{amsmath,amsfonts,amsthm} % Math packages

\\usepackage{lipsum} % Used for inserting dummy 'Lorem ipsum' text into the template

\\usepackage{graphicx}

\\usepackage[pdftex]{hyperref}

\\hypersetup
{%
pdftitle = {$detectorname Detector Sensitivity},
pdfsubject = {automatically generated document},
pdfauthor = {SpaceGravity.org},
colorlinks = {true},
pdffitwindow = {true},
pdfcreator = {TeX Live - pdflatex}
}

\\usepackage{sectsty} % Allows customizing section commands
\\allsectionsfont{\\centering \\normalfont\\scshape} % Make all sections centered, the default font and small caps

\\usepackage{fancyhdr} % Custom headers and footers

\\fancyhead[L]{\\ifnum\\thepage=1  \\else \\emph{$detectorname Detector Sensitivity}\\\\\\ \\fi}
\\fancyhead[R]{\\ifnum\\thepage=1 \\today\\\\\\ \\else \\thepage\\\\\\ \\fi} % No page header for first page
\\fancyhead[C]{} % No page header for first page
\\fancyfoot[R]{\\ \\\\\\begin{minipage}[t]{55mm}\\vspace{-20pt}\\includegraphics{$ENV{APP_ROOT}/htdocs/tools/spacegravity.pdf}\\\\\\tiny\\textsf{This report was generated automatically by the private internet platform SpaceGravity.org - no one can be held responsible for any errors or omissions or for the results obtained from the use of this information.}\\end{minipage}} % Empty left footer
%\\fancyfoot[C]{\\begin{minipage}[t]{\\textwidth}\\vspace{-20pt}\\horrule{0.5pt}\\end{minipage}\\\\\\begin{minipage}[t]{19mm}\\vspace{-20pt}\\includegraphics{$ENV{APP_ROOT}/htdocs/tools/qr.pdf}\\end{minipage}} % Empty center footer
\\fancyfoot[C]{}
\\fancyfoot[L]{\\ \\\\\\begin{minipage}[t]{55mm}\\vspace{-20pt}\\RTLpar\\includegraphics{$ENV{APP_ROOT}/htdocs/tools/institutions.pdf}\\\\\\tiny\\textsf{Cite as: Barke S, Tröbs M, Wang Y, Esteban JJ, Heinzel G, Danzmann K. AEI Sensitivity Calculator. In \\emph{SpaceGravity.org}. Retrieved \\today, from http://spacegravity.org/tools/sc/.}\\end{minipage}} % Page numbering for right footer


\\pagestyle{fancyplain} % Makes all pages in the document conform to the custom headers and footers

\\renewcommand{\\headrulewidth}{0pt} % Remove header underlines
\\renewcommand{\\footrulewidth}{0pt} % Remove footer underlines
\\setlength{\\headheight}{30pt} % Customize the height of the header

\\numberwithin{equation}{section} % Number equations within sections (i.e. 1.1, 1.2, 2.1, 2.2 instead of 1, 2, 3, 4)
\\numberwithin{figure}{section} % Number figures within sections (i.e. 1.1, 1.2, 2.1, 2.2 instead of 1, 2, 3, 4)
\\numberwithin{table}{section} % Number tables within sections (i.e. 1.1, 1.2, 2.1, 2.2 instead of 1, 2, 3, 4)

\\setlength\\parindent{0pt} % Removes all indentation from paragraphs - comment this line for an assignment with lots of text

%----------------------------------------------------------------------------------------
%	TITLE SECTION
%----------------------------------------------------------------------------------------

\\newcommand{\\horrule}[1]{\\rule{\\linewidth}{#1}} % Create horizontal rule command with 1 argument of height

\\newcommand{\\RTLpar}{% right-to-left paragraph alignment
  \\leftskip=0pt plus .5fil%
  \\rightskip=0pt plus -.5fil%
  \\parfillskip=0pt plus .5fil%
}

\\title{	
\\normalfont \\normalsize 
\\textsc{\\includegraphics[width=60mm]{$ENV{APP_ROOT}/htdocs/tools/$shape.png}} \\\\ [25pt] % Your university, school and/or department name(s)
\\horrule{0.5pt} \\\\[0.45cm] % Thin top horizontal rule
\\huge $detectorname Detector Sensitivity \\\\ % The assignment title
\\horrule{0.5pt} \\\\[0.5cm] % Thick bottom horizontal rule
}

\\author{{\\normalsize Based on work by}\\\\Barke S, Tröbs M, Wang Y, Esteban JJ, Heinzel G, Danzmann K\\\\{\\normalsize AEI Hannover, Germany}} % Your name

\\date{} % Today's date or a custom date

\\usepackage[onehalfspacing]{setspace}

\\begin{document}

\\maketitle % Print the title



%----------------------------------------------------------------------------------------
%	PROBLEM 1
%----------------------------------------------------------------------------------------

\\section*{Introduction}

This is a document automatically generated by a beta (LISA Symposium X preview) version of the AEI Sensitivity Calculator. There will be more content added during the conference. Please stay tuned.
\\newpage

\\section{Displacement Noise}

\\begin{figure}[h!]
  \\centering
  \\fbox{
    \\includegraphics[width=.7\\textwidth]{$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/{pm.big}.png}
  }
  \\caption{Overview of noise sources (expressed as corresponding displacement noise)}
  \\label{img:pm}
\\end{figure}


\\section{Single Link}

\\begin{figure}[h!]
  \\centering
  \\fbox{
    \\includegraphics[width=.7\\textwidth]{$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/{single.big}.png}
  }
  \\caption{Single link strain sensitivity (sky avarage) with Classic LISA sensitivity for comparison)}
  \\label{img:single}
\\end{figure}


\\section{Network}


\\begin{figure}[h!]
  \\centering
  \\fbox{
    \\includegraphics[width=.7\\textwidth]{$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/{full.big}.png}
  }
  \\caption{Full detector network strain sensitivity with astronomical sources}
  \\label{img:full}
\\end{figure}



\\end{document}

END



close REPORT;

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt: $!\n";;
flock(LOCK, 2);
close LOCK;


#print "Content-type: text/html\n\n";
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.overview.tex`;
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.overview.tex`;
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.overview.tex`;

$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/report.overview.pdf?$time";
print "Location: $URL\n\n";

exit(0);

sub DATA
{

$aufruf = "$ENV{'QUERY_STRING'}";
      $aufruf =~ tr/+/ /;
      $aufruf =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
@key_value_pairs = split (/&/, $aufruf);

foreach $key_value (@key_value_pairs)
        {
        ($key, $value) = split (/=/, $key_value);

        $value =~ tr/+/ /;
        $value =~ tr/\///;
        $value =~ tr/\#//;
        $value =~ tr/\;//;
        $value =~ s/\/\.\.//g;
        $value =~ s/\.\.\///g;
        $value =~ tr/^\///;
	$value =~ s/[^a-zA-Z0-9\-\.]//g;

$au{$key} = $value;

        }

$size_of_form_information = $ENV{'CONTENT_LENGTH'};
read (STDIN, $form_info, $size_of_form_information);
@key_value_pairs = split (/&/, $form_info);

foreach $key_value (@key_value_pairs)
        {
        ($key, $value) = split (/=/, $key_value);

        $value =~ tr/+/ /;
        $value =~ tr/\///;
        $value =~ tr/\#//;
        $value =~ tr/\;//;
        $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
        $value =~ s/\n//g;
	$value =~ s/,/\./g;
	$value =~ s/\s//g;
        $value =~ s/^\ +//g; $value =~ s/\ +$//g; $value =~ s/\&/\ und\ /g; $value =~ s/\ +/\ /g;
	$value =~ s/[^a-zA-Z0-9\-\.]//g;

$in{$key} = $value;

        }

}


# mmult contributed by Tony Bowden

sub mmult { my ($m1,$m2) = @_;
	    my ($m1rows,$m1cols
	       ) = (scalar @$m1, scalar @{$m1->[0]});
	    my ($m2rows,$m2cols) = (scalar @$m2, scalar @{$m2->[0]});
	    unless ($m1cols == $m2rows) { # raise exception, actually
	      die "IndexError: matrices don't match: $m1cols != $m2rows";
	    }
	    my $result = [];
	    my ($i, $j, $k);
	    for $i (0 .. ($m1rows - 1 )) {
	      for $j (0 .. ($m2cols - 1 )) {
		for $k ( 0 .. ($m1cols - 1)) {
		  $result->[$i]->[$j] += $m1->[$i]->[$k] * $m2->[$k]->[$j];
		}
	      }
	    }
	    return $result;
	  }

