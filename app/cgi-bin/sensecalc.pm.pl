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

$plotlowpm = $au{low};
$armlength = $au{arm};
$links = $au{links}; #anzahl der arme

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

if (-e "$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/") {

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.png`;
$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.big.png`;

}
else {

$URL = "http://spacegravity.org/lisa/files/2012/07/cooieerror.png";
print "Location: $URL\n\n";

exit();}


open(GNU, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.gnu: $!\n";
print GNU "set terminal png enhanced transparent fontscale 0.6 size 351,197\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.png'\n";
print GNU "set logscale\n";
print GNU "set grid\n";
print GNU "set ylabel 'Displacement in m/{/Symbol Ö}Hz'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$plotlowpm:1e-6]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";

if ($links eq "12") {$noise ="\$2"; $linewidth = "1";} else {$noise = "sqrt(\$2**2+\$5**2+\$9**2)"; $linewidth = "2";}

print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):($noise) w l  title 'Combined displacement noise' lw 8 linecolor rgb 'gray',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$3) w l  title 'Carrier phase noise (i.e. shot noise)' lw 2,\\\n";

if ($links ne "12") {
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$8) w l  title 'Sideband phase noise (i.e. shot noise)' lw 2,\\\n"; }

print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$4) w l  title 'Other contributions (i.e. phasemeter)' lw 2,\\\n";

if ($links ne "12") {
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$6) w l  title 'Sideband signal line noise' lw 2,\\\n";
}

print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$7) w l  title 'Zerodur / Fused Silica noise' lw 2, \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$9) w l  title 'Spacecraft jitter' lw $linewidth, \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(\$5) w l  title 'Acceleration noise' lw $linewidth\n";
#print GNU "set terminal png enhanced transparent fontscale 0.8 size 560,320\n";
#print GNU "set term svg enhanced mouse size 530,340\n";
print GNU "set terminal png enhanced notransparent fontscale 0.8 size 540,360\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.big.png'\n";
# print GNU "set ylabel 'Displacement in m/Hz^{-0.5}'\n";
print GNU "replot\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.gnu`;

$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.png`;
$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.big.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.big.png`;

sleep(1);

$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/pm.png?$time";
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

