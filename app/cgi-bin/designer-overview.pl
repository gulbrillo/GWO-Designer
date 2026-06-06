#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;
use List::Util qw( min max );

use utf8;
use CGI;

# READ INPUT FORM and DECODE from UTF8
$query = CGI ->new;
$in = {};  
foreach my $name ( $query ->param ) {
  my @val = $query ->param( $name );
  foreach ( @val ) {
     utf8::decode($_);

	if ($name eq "titles")	{
		$_ =~ s/[^\pL\pN\p{Zs}\pP\p{Sm}\|]//g;
	} else {
		$_ =~ s/[^A-Za-z0-9-.\,\|]//g;
	}

  }
  utf8::decode($name);
  if ( scalar @val == 1 ) {   
    $in{$name} = $val[0];
  } else {                      
    $in{$name} = \@val;  # save value as an array ref
  }
}

# #ENCODE PARAMETERS THAT WILL BE WRITTEN TO OTHER DOCUMENTS
# if (!$in{name}) {$in{namei} = "Your observatory";}
# utf8::encode($in{name});
# utf8::encode($in{plottitle});

@plots = split(/\|/, $in{plots});
@titles = split(/\|/, $in{titles});
@colors = ("e91e63", "673ab7", "5677fc", "00bcd4", "259b24", "cddc39", "ffc107", "ff5722");

#######

$stamp = $in{session};

print "Content-type: text/html\n\n";

if (-e "$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/tm.txt") {

$return = `rm $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/af.svg`;

}
else {

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/`;

}

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data`;
$return = `rm $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/LOCK`;
$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/elements`;
$return = `cp -rp $ENV{APP_ROOT}/designer/plotelements/* $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/elements/`;



@arme = split(/\,/, $in{arm});
$in{arm} = min @arme;

$armlength = $in{arm}*1e3;
given ($in{con}) {
        when ("two") {$in{two} = "checked"; $links="2"; }
        when ("oct") {$in{oct} = "checked"; $links="12"; }
        when ("tri") {$in{tri} = "checked"; $links="3";}
}

$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

#if Octahedron, remove acceleration noise
if ($links eq "2") {$tdis = "1";} elsif ($links eq "3") {$tdis = "3";} 
if ($links eq "12") {$noise = "sqrt(\$5**2+\$6**2+\$9**2)/sqrt($links)";}
else {$noise = "sqrt((\$7**2)*16+(sqrt(\$4**2)**2)*4)/sqrt($tdis)";}

open(GNU, ">", "$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/plot.overview.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/plot.overview.gnu: $!\n";
print GNU "set logscale\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";

print GNU "set encoding utf8\n";

print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set ylabel 'Strain sensitivity in 1/√Hz'\n";

print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";

print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";

print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/af.svg'\n";
print GNU "set yrange [*:1e-14]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";


$counter = 0;
foreach my $uuid (@plots) {

if (!$titles[$counter]) {$titles[$counter] = "Your observatory";}
utf8::encode($titles[$counter]);

print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$uuid/tf.txt $ENV{APP_ROOT}/htdocs/designer/results/$uuid/pm.txt' u (\$1):($noise/abs(\$2)) w l  title '$titles[$counter]' lw 3 lt 1 lc rgb '#$colors[$counter]', \\\n";
$counter++;
}

if ($counter == 1) {
print GNU "'$ENV{APP_ROOT}/designer/plotelements/elisa.txt' every 10 u 1:(\$2) w l title 'eLISA 2013 (numerical simulation)'  lw 2 lt 1 lc rgb '#$colors[3]', \\\n";
}

print GNU "1 title ''\n";

print GNU "unset output\n";

print GNU "unset logscale\n";
print GNU "unset format\n";

print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/overview.txt\"\n";
print GNU "replot\n";
print GNU "unset table\n\n";


print GNU "quit\n";

close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/plot.overview.gnu`;
$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/af.svg`;


$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/strain-sensitivity-overview.pdf $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/af.svg`;




open(GNU, ">", "$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/overview.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/data/overview.gnu: $!\n";

print GNU "# This work is licensed under a Creative Commons Attribution 4.0 International License.\n";
print GNU "# http://creativecommons.org/licenses/by/4.0/\n";
print GNU "# Licensees may copy, distribute, display and perform the work and make derivative works based\n";
print GNU "# on it only if they give the author or licensor the credits in the manner specified by these.\n";
print GNU "# \n";
print GNU "# Please cite: Simon Barke et al.\n";
print GNU "# Towards a Gravitational Wave Observatory Designer: Sensitivity Limits of Spaceborne Detectors.\n";
print GNU "# 2015 Class. Quantum Grav. 32 095004. (doi:10.1088/0264-9381/32/9/095004)\n\n\n";
print GNU "set logscale\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";

print GNU "set encoding utf8\n";

print GNU "set ylabel 'Strain sensitivity in 1/√Hz'\n";
print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";

print GNU "set term pngcairo size 1600,1000 enhanced font ',20'\n";
print GNU "set output 'overview.png'\n";

print GNU "set title 'http://spacegravity.org/designer/#rc=$stamp'\n";

print GNU "plot \\\n";

$counter = 0;
foreach my $uuid (@plots) {

if (!$titles[$counter]) {$titles[$counter] = "Your observatory - $plots[0]";}
utf8::encode($titles[$counter]);

print GNU "'overview.txt' index $counter u 1:2 w lines title '$titles[$counter] - $plots[$counter]' lw 3 lt 1 lc rgb '#$colors[$counter]', \\\n";
$counter++;

}

print GNU "'elements/elisa.txt' every 10 u 1:(\$2) w l title 'eLISA 2013 (numerical simulation)'  lw 2 lt 1 lc rgb '#$colors[$counter]'\n";

print GNU "unset output\n";

print GNU "quit\n";


close (GNU);




print '{"result":[{"uuid": "'.$stamp.'", "run": "0"}]}';

exit(0);


