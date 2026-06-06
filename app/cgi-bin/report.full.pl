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

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.full.pdf`;

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


$file = "$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/details.txt";
open FILE, $file or die "Could not open $file: $!";

while( my $line = <FILE>)  {   
@field = split(/;/, $line);   
$field[3] =~ s/\]$//g;
$field[3] =~ s/^\[//g;
$value{$field[3]}=$field[1];
$unit{$field[3]}=$field[2];
}

close(FILE);

if ($value{links} eq "2") {$detshape="two-arm"}
elsif ($value{links} eq "12") {$detshape="octahedral"}
else {$detshape="triangular"}

$value{links} = $value{links}*2;

$file = "$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/min.txt";
open FILE, $file or die "Could not open $file: $!";

while( my $line = <FILE>)  {
if ($line =~ /^\s\S/) {
@werte = split(/\s+/, $line);
$minval = sprintf("%e", $werte[2]);
$minval =~ s/e-0/e-/g;
$minval =~ s/e0/e/g;
$minfreq = sprintf("%e", $werte[1]);
$minfreq =~ s/e-0/e-/g;
$minfreq =~ s/e0/e/g;
}

}

close(FILE);



open REPORT, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.full.tex" or die $!;

print REPORT << "END";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stylish Article
% LaTeX Template
% Version 2.0 (13/4/14)
%
% This template has been downloaded from:
% http://www.LaTeXTemplates.com
%
% Original author:
% Mathias Legrand (legrand.mathias\@gmail.com)
%
% License:
% CC BY-NC-SA 3.0 (http://creativecommons.org/licenses/by-nc-sa/3.0/)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%----------------------------------------------------------------------------------------
%	PACKAGES AND OTHER DOCUMENT CONFIGURATIONS
%----------------------------------------------------------------------------------------

\\documentclass[fleqn,10pt]{SelfArx} % Document font size and equations flushed left

\\usepackage[english]{babel}
\\selectlanguage{english}

\\usepackage{lipsum} % Required to insert dummy text. To be removed otherwise

\\usepackage{textcomp} % \\upmu and Co.
\\usepackage[autolanguage]{numprint}

\\usepackage[table]{xcolor}
\\usepackage{verbatimbox}

%----------------------------------------------------------------------------------------
%	COLUMNS
%----------------------------------------------------------------------------------------

\\setlength{\\columnsep}{0.55cm} % Distance between the two columns of text
\\setlength{\\fboxrule}{0.75pt} % Width of the border around the abstract

%----------------------------------------------------------------------------------------
%	COLORS
%----------------------------------------------------------------------------------------

\\definecolor{color1}{RGB}{0,60,80} % Color of the article title and sections
\\definecolor{color2}{RGB}{70,130,140} % Color of the boxes behind the abstract and headings

%----------------------------------------------------------------------------------------
%	HYPERLINKS
%----------------------------------------------------------------------------------------

\\usepackage{hyperref} % Required for hyperlinks
\\hypersetup{hidelinks,colorlinks,breaklinks=true,urlcolor=color2,citecolor=color1,linkcolor=color1,bookmarksopen=false,pdftitle={Title},pdfauthor={Author}}

%----------------------------------------------------------------------------------------
%	ARTICLE INFORMATION
%----------------------------------------------------------------------------------------

\\JournalInfo{Auto generated on \\today} % Journal information
\\Archive{spacegravity.org/tools/sc/} % Additional notes (e.g. copyright, DOI, review/research article)

\\PaperTitle{$value{name} Detector Sensitivity} % Article title

\\Authors{Simon Barke\\textsuperscript{1}\\textsuperscript{2}*, Juan Jose Esteban Delgado\\textsuperscript{3}, Yan Wang\\textsuperscript{1}\\textsuperscript{2}, Michael Tr\\"obs\\textsuperscript{1}\\textsuperscript{2}, Gerhard Heinzel\\textsuperscript{1}\\textsuperscript{2}, Karsten Danzmann\\textsuperscript{1}\\textsuperscript{2}} % Authors
\\affiliation{\\textsuperscript{1}\\textit{Institute for Gravitational Physics, Leibniz Universit\\"at Hannover, Germany}} % Author affiliation
\\affiliation{\\textsuperscript{2}\\textit{Max Planck Institute for Gravitational Physics (Albert Einstein Institute) Hannover, Germany}} % Author affiliation
\\affiliation{\\textsuperscript{3}\\textit{Coherent LaserSystems GmbH \\& Co. KG, Hannover, Germany}} % Author affiliation
\\affiliation{*\\textbf{Corresponding author}: simon.barke\@gmail.com} % Corresponding author

\\Keywords{Gravitational Waves --- Laser Interferometer Space Antenna --- LISA} % Keywords - if you don't want any simply remove all the text between the curly brackets
\\newcommand{\\keywordname}{Keywords} % Defines the keywords heading name

%----------------------------------------------------------------------------------------
%	ABSTRACT
%----------------------------------------------------------------------------------------

\\Abstract{The most promising concept for low frequency gravitational wave observatories are laser interferometric detectors in space, designed to be limited by shot noise in the signal readout. For this to be true, a careful balance of mission parameters is necessary to keep all technical noise sources below shot noise. In this document, we feature an extensive overview of limiting and negligible noise sources for an exemplary $detshape ($value{links} link) detector with an interferometric arm length of \$\\textsf{\\numprint{$value{armlength}}}\$\\,$unit{armlength}. For a specific set of mission parameters this detector has its peak strain sensitivity of \\nprounddigits{1}\\numprint{$minval} \\npnoround at \\nprounddigits{1}\\numprint{$minfreq}\\npnoround\\,Hz.}

%----------------------------------------------------------------------------------------

\\setcounter{tocdepth}{2}

\\begin{document}

\\newcolumntype{L}[1]{>{\\raggedright\\arraybackslash}p{#1}}
\\newcolumntype{C}[1]{>{\\centering\\arraybackslash}p{#1}}
\\newcolumntype{R}[1]{>{\\raggedleft\\arraybackslash}p{#1}}
\\setlength{\\tabcolsep}{0pt}

\\flushbottom % Makes all text pages the same height

\\maketitle % Print the title and abstract box

\\tableofcontents % Print the contents section

\\thispagestyle{empty} % Removes page numbering from the first page

%----------------------------------------------------------------------------------------
%	ARTICLE CONTENTS
%----------------------------------------------------------------------------------------

\\section*{Introduction} % The \\section*{} command stops section numbering

\\addcontentsline{toc}{section}{Introduction} % Adds this section to the table of contents

Gravitational waves \\cite{einstein1937gravitational} are the next big thing in astronomy. In contrast to electromagnetic radiation, gravitational radiation travels unimpeded throughout the entire universe, and even electromagnetically dark objects are capable of producing gravitational waves. Their continuous observation will enable us to directly study these dark objects for the very first.\\\\

Alongside undeniable indirect proof of the existence of gravitational waves \\cite{taylor1989further}, evidence for gravitational waves produced during cosmic inflation (red-shifted to 10\$^{-16}\$\\,Hz) was recently found as static polarization pattern imprint in the cosmic microwave background radiation \\cite{ade2014bicep2}. Very low frequency gravitational waves below 1\\,\\textmu Hz produced by pairs of supermassive black holes can be detected when timing millisecond pulsars with arrays of radio telescopes \\cite{0264-9381-27-8-084013}.
High frequency gravitational waves above 10\\,Hz---as produced by rotating neutron stars or asymmetric supernovae---will be measured by sophisticated Earth-based laser interferometric detectors \\cite{harry2010advanced, accadia2011status, somiya2012detector, grote2008status}. 
Some of the most interesting sources of gravitational waves (like supermassive black hole mergers, dense stars captured by supermassive black holes, and pairs of dense stars) emit at frequencies between 10\\,\\textmu Hz and 1\\,Hz, see Figure~\\ref{fig:view}. Due to seismic disturbances, this frequency range is not accessible from Earth. 
 A laser interferometric gravitational wave observatory in space \\cite{seoane2013gravitational} is known to be the most promising option to detect gravitational waves in this frequency range and hence was recently selected by ESA to be launched in the 2030s as 3rd large mission of the Cosmic Vision program.\\\\
 
Concepts of such a space based gravitational wave detectors feature multiple spacecraft separated by millions of kilometers that form a giant laser interferometer, cf. Laser Interferometer Space Antenna (LISA) \\cite{danzmann2011lisa}, New Gravitational wave Observatory (NGO) \\cite{jenrich2012ngo}. A careful balance of the mission parameters is necessary to keep all technical noise sources below the interferometer's shot noise limit and within the capabilities of current metrology systems for the signal readout. In this document a detector's design sensitivity is simulated for one specific set of  mission parameters.

\\phantomsection
\\section*{Disclaimer} % The \\section*{} command stops section numbering

%\\addcontentsline{toc}{section}{Disclaimer} % Adds this section to the table of contents

All data in this document was generated automatically on SpaceGravity.org – no one can be held responsible for any errors or omissions or for the results obtained from the use of this information. If you publish results based on data obtained from this document, please cite the corresponding paper.

%------------------------------------------------

\\begin{figure*}[ht]\\centering % Using \\begin{figure*} makes the figure take up the entire width of the page
\\addvbuffer[0pt 8pt]{\\includegraphics[width=\\linewidth]{$ENV{APP_ROOT}/cgi-bin/spectrum}}
\\caption{Frequency range of gravitational wave sources and bandwidth of corresponding gravitational wave detectors on Earth and in space. A gravitational wave background generated during cosmic inflation should be present over the entire frequency spectrum.}
\\label{fig:view}
\\end{figure*}


\\section{Mission Parameters}


A laser interferometric gravitational wave detector in space consists of a virtual Michelson interferometer that measures changes in the distance between freely floating proof masses which form the end mirrors of the two interferometer arms. 
While a mimimum of four laser links between three spacecraft is required to build up the interferometer arms, more links will not only improove the detector's sensitivity but also produce other consequent benefits.
A three-arm (6 link) detector can discriminate between different gravitational wave polarizations instantainiously. An octahedral 12 arm (24 link) detector would in theory be able to supress acceleration noise alongside laser frequency noise. For this particular detector concept a $detshape ($value{links} link) configuration as illustrated in Figure~\\ref{fig:configuration} was chosen.\\\\

\\begin{figure}[h]\\centering
\\includegraphics[width=.7\\linewidth]{$ENV{APP_ROOT}/htdocs/tools/$shape.png}
\\caption{Interferometer topology, corner points mark the position of the different spacecraft.}
\\label{fig:configuration}
\\end{figure}


\\paragraph{Arm length}
Drifts in the spacecraft constellation result in Doppler shifts of the laser light. Hence the interferometer requires a readout that measures the phase of a high frequency heterodyne signal. A lower heterodyne frequency simplifies the phase readout.
Switchable offset frequency phase-locked loops between lasers minimize the maximum heterodyne frequency while at the same time avoiding zero crossings. This effort is limited by the orbit stability and the resulting magnitude of the Doppler shifts.

 The spacecraft separation distance has multiple effects on the detector's sensitivity. Longer arms make the detector more sensitive to lower gravitational wave frequencies but also reduce sensitivity at higher frequencies and decrease the received laser light power. Also the arm length has an impact on orbit stability.\\footnote{For an average separation distance (arm length) of \\numprint{5000000}\\,km simulations of heliocentric orbits \$20^\\circ\$ behind Earth predict a heterodyne frequency of less then 25\\,MHz. A smaller separation in heliocentric orbits would further reduce this value. The stability of geocentric orbits would greatly suffer from the proximity to the Earth-Moon system, amplifying the Doppler shifts and increasing the maximum heterodyne frequency. For octahedral (24 link) constellations, so far only short arm (\$< 1500\$\\,km) halo orbits near the Lagrangian point L1 has been found to be stable enough, with Doppler shifts being still under investigation.}

The present case deals with an average arm length of \$L_{arm}=\\numprint{$value{armlength}}\$\\,$unit{armlength} with a maximum heterodyne frequency of \$f_{het}=$value{fhet}\$\\,MHz. The feasibility of such a value should be subject to a more detailed study.\\\\

\\paragraph{Lasers} All lasers have to meet tough relative intensity noise requirements since any such noise at the interferometer heterodyne frequency translates directly to read-out noise. As of this writing space qualified lasers meeting all stability requirements are available only at 1064\\,nm wavelength. A shorter wavelength would improve the detector response to gravitational waves. \$\\lambda_{laser} = $value{laser}\$\\,nm, \$RIN = \\numprint{$value{rin}}\$\\,\$/\\sqrt{\\text{Hz}}\$ \\\\

\\paragraph{Telescopes} The fundamental sensitivity limit of the detector is shot noise in the heterodyne signal read out. A delicate trade-off between mission parameters is necessary. To minimise the influence of shot noise the signal strength can be improved with with more powerful laser amplifiers and larger telescopes with higher optical efficiency.

\$ P_{tel} =   $value{power} \$\\,W
\$ d_{tel} =   $value{diameter} \$\\,cm 
\$ \\eta_{opt} =  $value{oeff} \$\\,\\%\\\\

\\begin{table}[t]
\\rowcolors{2}{color2!10}{color2!20}
\\noindent
\\addvbuffer[0pt 8pt]{\\begin{tabular}{L{.5\\columnwidth}R{.2\\columnwidth}L{.3\\columnwidth}}
  \\textbf{Parameter} \& ~ \& ~\\textbf{Value}\\\\
\\hline
Number of links \& \$N_{links} =  \$ \& ~ \$ $value{links} \$  ~\\\\
Average arm length \& \$L_{arm} = \$ \& ~ \$ $value{armlength} \$  $unit{armlength} \\\\
Heterodyne frequency (max.) \& \$f_{het} =  \$ \& ~ \$ $value{fhet}\$  MHz \\\\
Laser wavelength \& \$\\lambda_{laser} =  \$ \& ~ \$ $value{laser}\$  nm \\\\
Relative intensity noise \& \$ RIN =  \$ \& ~ \$ \\numprint{$value{rin}}\$  \$/\\sqrt{\\text{Hz}}\$ \\\\
Optical power (to telescope) \& \$ P_{tel} =  \$ \& ~ \$ $value{power} \$  W \\\\
Telescope diameter \& \$ d_{tel} =  \$ \& ~ \$ $value{diameter} \$  cm \\\\
Optical efficiency \& \$ \\eta_{opt} =  \$ \& ~ \$ $value{oeff} \$  \\% \\\\
\\end{tabular}}
\\caption{Basic mission parameters (orbit, lasers and telescope systems)}
\\label{tab:basic}
\\end{table}

\\paragraph{Temperature} 

Due to the unequal arm length single link detection scheme (with free running reference clocks and lasers on each spacecraft) any such interferometer would be dominated by frequency noise.
Auxiliary functions of the laser links, sophisticated data post-processing methods, and a technique called time delay interferometry (TDI) to supress this excess noise below the shotnoise limit of the detector were studied in detail and are currently developed and tested. 12 link detector it was hypothesized that newly developed DFI algorithems might in principle remove everything.


\\begin{equation}
\\cos^3 \\theta =\\frac{1}{4}\\cos\\theta+\\frac{3}{4}\\cos 3\\theta
\\label{eq:refname2}
\\end{equation}

\\lipsum[5] % Dummy text

\\begin{enumerate}[noitemsep] % [noitemsep] removes whitespace between the items for a compact look
\\item First item in a list
\\item Second item in a list
\\item Third item in a list
\\end{enumerate}


%\\subsection{Temperature Stability}

\\lipsum[6] % Dummy text

\\subsection{Instrument}

\\lipsum[7] % Dummy text

\\paragraph{Paragraph} \\lipsum[8] % Dummy text

\\subsection{Metrology System}

\\lipsum[9] % Dummy text

\\begin{figure}[ht]\\centering
\\includegraphics[width=\\linewidth]{$ENV{APP_ROOT}/cgi-bin/spectrum}
\\caption{In-text Picture}
\\label{fig:results}
\\end{figure}

Reference to Figure \\ref{fig:results}.

%------------------------------------------------

\\section{Displacement Noise}

\\lipsum[10] % Dummy text

\\subsection{Shot Noise}

\\subsubsection{Carrier Readout}

\\subsubsection{Sideband Readout}

\\subsection{Other Contributions}

\\lipsum[11] % Dummy text

\\subsubsection{Jitter}

\\subsubsection{Sideband Signal Line}



\\lipsum[12] % Dummy text

\\begin{description}
\\item[Word] Definition
\\item[Concept] Explanation
\\item[Idea] Text
\\end{description}

\\subsubsection{Optical Bench}


\\lipsum[13] % Dummy text

\\begin{itemize}[noitemsep] % [noitemsep] removes whitespace between the items for a compact look
\\item First item in a list
\\item Second item in a list
\\item Third item in a list
\\end{itemize}

\\subsubsection{Measurement}
\\lipsum[14] % Dummy text

\\section{Strain Sensitivity}

\\subsection{Single Link}

\\subsection{Full Detector}

\\lipsum[15-23] % Dummy text

%------------------------------------------------



%\\phantomsection
%\\section*{Acknowledgement} % The \\section*{} command stops section numbering
%\\addcontentsline{toc}{section}{Acknowledgement} % Adds this section to the table of contents
%danke.


%----------------------------------------------------------------------------------------
%	REFERENCE LIST
%----------------------------------------------------------------------------------------
\\phantomsection
\\bibliographystyle{unsrt}
\\bibliography{$ENV{APP_ROOT}/cgi-bin/spacegravity}

%----------------------------------------------------------------------------------------

\\end{document}

END



close REPORT;

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt: $!\n";;
flock(LOCK, 2);
close LOCK;


#print "Content-type: text/html\n\n";
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.full.tex`;
$bibtex = `export HOME=$ENV{APP_ROOT} && cd $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ && /usr/bin/bibtex report.full.aux`;
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.full.tex`;
$pdflatex = `export HOME=$ENV{APP_ROOT} && /usr/bin/pdflatex -output-directory=$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/ $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.full.tex`;

$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/report.full.pdf?$time";
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

