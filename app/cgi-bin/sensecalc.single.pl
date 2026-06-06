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

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.png`;
$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.big.png`;

}
else {

$URL = "http://spacegravity.org/lisa/files/2012/07/cooieerror.png";
print "Location: $URL\n\n";

exit();}

###
### Single link Sky Avarage Nx = [ 1; 0; 0]; % unit vector along the arm
### 

$Nx =  [
[1],
[0],
[0],
];

$pi = 3.1415926535897932384626433832795;

$detectorname = $au{name};
$armlength = $au{arm};
$links = $au{links}; #anzahl der arme

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;


## strain sensitivity armlaenge
$lightsec = $armlength /299792458;


open SINGLET, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt" or die $!;

flock(SINGLET, 2);

print SINGLET "# Single Link Transfer Function (Sky Avarage)\n";

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);
$counter = 0;
$T2 = 0;
        for ($lambda = -0.45*$pi; $lambda <= 0.45*$pi; $lambda = $lambda + 1.5*0.47123889803846898576939650)
        {
                for ($beta = 0; $beta <= 0.19*$pi; $beta = $beta + 1.5*0.09948376736367678588465037)
                        {
        $counter++;

        $kv =  -cos($beta)*cos($lambda);
        $uv =  sin($beta)*cos($lambda);
        $vv =  sin($lambda);

        $Tgw =  abs(( 1.-exp(2*i*$pi*$lightsec*$f*(1-$kv)) ) / (2*i*$pi*$lightsec*$f*(1-$kv)) * ( ($uv)**2 - ($vv**2)**2 + 2*($uv)*($vv) )/2);
        $T2 = $T2 + $Tgw**2;
                }
        }

$T = sqrt($T2/$counter);

print SINGLET "$f $T\n";

}


close SINGLET;


open(GNU, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.single.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.single.gnu: $!\n";
print GNU "set logscale\n";
print GNU "set grid\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set ylabel 'Strain in 1/{/Symbol Ö}Hz'\n";
print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";
print GNU "set terminal png enhanced transparent fontscale 0.6 size 351,197\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.png'\n";
print GNU "set yrange [*:1e-14]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";
print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/lisa.sl.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/lisa.pm.txt' u (\$1):(sqrt(\$4**2)/5000000000./abs(\$2)) w l  title 'Classic LISA' lw 6 linecolor rgb 'gray', \\\n";
print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(sqrt(\$4**2+\$7**2+\$11**2)/$armlength./abs(\$2)) w l  title '$detectorname' lw 2 linecolor rgb 'red'";

if ($links eq "12") {print GNU ", \\\n '< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(sqrt(\$4**2)/$armlength./abs(\$2)) w l  title 'without acceleration / jitter' lw 1\n";} else {print GNU "\n";}
print GNU "\n";

#print GNU "set terminal png enhanced transparent fontscale 0.8 size 560,320\n";
#print GNU "set term svg enhanced mouse size 530,340\n";
print GNU "set terminal png enhanced notransparent fontscale 0.8 size 540,360\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.big.png'\n";

print GNU "replot\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.single.gnu`;

$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.png`;
$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.big.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/single.big.png`;


$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/single.png?$time";
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

