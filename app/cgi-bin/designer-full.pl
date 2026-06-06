#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;

use utf8;
use CGI;

# READ INPUT FORM and DECODE from UTF8
$query = CGI ->new;
$in = {};
foreach my $name ( $query ->param ) {
  my @val = $query ->param( $name );
  foreach ( @val ) {
    utf8::decode($_);

        if ($name eq "name" || $name eq "plottitle" || $name eq "con")  {
                $_ =~ s/[^\pL\pN\p{Zs}\pP\p{Sm}]//g;
        } else {
                $_ =~ s/[^A-Za-z0-9-.]//g;
        }
  }
  utf8::decode($name);
  if ( scalar @val == 1 ) {
    $in{$name} = $val[0];
  } else {
    $in{$name} = \@val;  # save value as an array ref
  }
}

#ENCODE PARAMETERS THAT WILL BE WRITTEN TO OTHER DOCUMENTS
if (!$in{name}) {$in{name} = "Your observatory";}
utf8::encode($in{name});
utf8::encode($in{plottitle});

#######

($sek,$min,$hour,$day,$mno,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
$time = sprintf("%02d:%02d:%02d",$hour,$min, $sek);

$stamp = $in{uuid};

#binmode(STDOUT, ":utf8");

print "Content-type: text/html\n\n";

if (-e "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.svg") {

$return = `rm $ENV{APP_ROOT}/htdocs/designer/results/$stamp/fl.svg`;

}
else {

print '{"result":[{"uuid": "", "illegal": "true"}]}';
exit();

}

$pi = 3.1415926535897932384626433832795;

$detectorname = $in{name};

if ($in{plottitle}) {$detectorname = $detectorname." ($in{plottitle})";}

$armlength = $in{arm}*1e3;
given ($in{con}) {
        when ("two") {$in{two} = "checked"; $links="2"; }
        when ("oct") {$in{oct} = "checked"; $links="12"; }
        when ("tri") {$in{tri} = "checked"; $links="3";}
}

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

## strain sensitivity armlaenge
$lightsec = $armlength /299792458;

if ($links eq "12") {

open TRANSFER, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt" or die $!;

flock(TRANSFER, 2);

print TRANSFER "# Full detector Transfer Function (Sky Avarage - Octahedron)\n";

$Tsn2 = "16"; # Shotnoise Transfer Function squared (for TDI Y1 combination it's constant!)

#UNIT VECTOR ALONG THE ARM

for ($jj = 1; $jj <= 6; $jj++)
        {
                for ($kk = 1; $kk <= 6; $kk++)
                {

$Nx->{$jj}{$kk} = [
[0],
[0],
[0],
];

		}
	}

$Nx->{2}{1} =  [
[1/sqrt(2)],
[-1/sqrt(2)],
[0],
];

$Nx->{5}{1} =  [
[1/sqrt(2)],
[1/sqrt(2)],
[0],
];

$Nx->{3}{1} = [
[1/sqrt(2)],
[0],
[-1/sqrt(2)],
];

$Nx->{6}{1} = [
[1/sqrt(2)],
[0],
[1/sqrt(2)],
];

$Nx->{3}{2} = [
[0],
[1/sqrt(2)],
[-1/sqrt(2)],
];

$Nx->{4}{2} = [
[1/sqrt(2)],
[1/sqrt(2)],
[0],
];

$Nx->{6}{2} = [
[0],
[1/sqrt(2)],
[1/sqrt(2)],
];

$Nx->{4}{3} = [
[1/sqrt(2)],
[0],
[1/sqrt(2)],
];

$Nx->{5}{3} = [
[0],
[1/sqrt(2)],
[1/sqrt(2)],
];

$Nx->{5}{4} = [
[-1/sqrt(2)],
[1/sqrt(2)],
[0],
];

$Nx->{6}{4} = [
[-1/sqrt(2)],
[0],
[1/sqrt(2)],
];

$Nx->{6}{5} = [
[0],
[-1/sqrt(2)],
[1/sqrt(2)],
];

$Nx->{1}{2} =  [
[-1/sqrt(2)],
[1/sqrt(2)],
[0],
];

$Nx->{1}{5} =  [
[-1/sqrt(2)],
[-1/sqrt(2)],
[0],
];

$Nx->{1}{3} = [
[-1/sqrt(2)],
[0],
[1/sqrt(2)],
];

$Nx->{1}{6} = [
[-1/sqrt(2)],
[0],
[-1/sqrt(2)],
];

$Nx->{2}{3} = [
[0],
[-1/sqrt(2)],
[1/sqrt(2)],
];

$Nx->{2}{4} = [
[-1/sqrt(2)],
[-1/sqrt(2)],
[0],
];

$Nx->{2}{6} = [
[0],
[-1/sqrt(2)],
[-1/sqrt(2)],
];

$Nx->{3}{4} = [
[-1/sqrt(2)],
[0],
[-1/sqrt(2)],
];

$Nx->{3}{5} = [
[0],
[-1/sqrt(2)],
[-1/sqrt(2)],
];

$Nx->{4}{5} = [
[1/sqrt(2)],
[-1/sqrt(2)],
[0],
];

$Nx->{4}{6} = [
[1/sqrt(2)],
[0],
[-1/sqrt(2)],
];

$Nx->{5}{6} = [
[0],
[1/sqrt(2)],
[-1/sqrt(2)],
];



#########################################

# Y1 combination W1s which are not zero

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);

for ($jj = 1; $jj <= 6; $jj++)
        {
                for ($kk = 1; $kk <= 6; $kk++)
                {
$W1->{$jj}{$kk}{$f} = 0;
                }
        }


$Df = exp(-2*i*$pi*$f*$lightsec);

$W1->{2}{1}{$f} = 1.;
$W1->{5}{1}{$f} = 1.;
$W1->{3}{1}{$f} = -1.;
$W1->{6}{1}{$f} = -1.;

$W1->{2}{4}{$f} = -1.;
$W1->{5}{4}{$f} = -1.;
$W1->{3}{4}{$f} = 1.;
$W1->{6}{4}{$f} = 1.;

$W1->{1}{2}{$f} = -$Df;
$W1->{4}{2}{$f} = $Df;
$W1->{1}{5}{$f} = -$Df;
$W1->{4}{5}{$f} = $Df;
$W1->{1}{3}{$f} = $Df;
$W1->{4}{3}{$f} = -$Df;
$W1->{1}{6}{$f} = $Df;
$W1->{4}{6}{$f} = -$Df;

}

#########################################

#SPACECRAFT POSITION
$Xx{1} = [
[$lightsec/sqrt(2)],
[0],
[0],
];

$Xx{2} = [
[0],
[$lightsec/sqrt(2)],
[0],
];

$Xx{3} = [
[0],
[0],
[$lightsec/sqrt(2)],
];

$Xx{4} = [
[-1*$lightsec/sqrt(2)],
[0],
[0],
];

$Xx{5} = [
[0],
[-1*$lightsec/sqrt(2)],
[0],
];

$Xx{6} = [
[0],
[0],
[-1*$lightsec/sqrt(2)],
];


########################################

#print "Content-type: text/html\n\n";

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{

$f = 10**($e/100);
$XXX = 0;
$counter = 0;

        for ($lambda = 0; $lambda <= 0.5*$pi; $lambda = $lambda + 2*2.3561944901923449288469825)
        {
                for ($beta = -0.35*$pi; $beta <= 0.35*$pi; $beta = $beta + 2*1.0995574287564276334619251)
                        {
        $counter++;


        $kv =  [[ -cos($beta)*cos($lambda), -cos($beta)*sin($lambda), -sin($beta)],];
        $uv =  [[ sin($beta)*cos($lambda), sin($beta)*sin($lambda),-cos($beta)],];
	$vv =  [[           sin($lambda),          -cos($lambda),         0],];

	$Tgw = 0;

		for ($jj = 1; $jj <= 6; $jj++)
		        {
                	for ($kk = 1; $kk <= 6; $kk++)
                		{

if ($W1->{$jj}{$kk}{$f})  {	
$kvNxV =  mmult($kv, $Nx->{$jj}{$kk}); $kvNx = $kvNxV->[0]->[0];
$kvXxV = mmult($kv, $Xx{$jj}); $kvXx = $kvXxV->[0]->[0];
$uvNxV =  mmult($uv, $Nx->{$jj}{$kk}); $uvNx = $uvNxV->[0]->[0];
$vvNxV =  mmult($vv, $Nx->{$jj}{$kk}); $vvNx = $vvNxV->[0]->[0];


$Tgw =  $Tgw + ($W1->{$jj}{$kk}{$f} * (exp(2*i*$pi*$lightsec*$f*(1-$kvNx)) -1. ) / 2 / $pi / $f / (1*i*(1 - ($kvNx) ))   * exp(-2 *i*$pi*$f*($kvXx)) * ( ($uvNx)**2 - ($vvNx)**2)/2 );
#$Tgw =  $Tgw + ((exp(2*i*$pi*$lightsec*$f*(1.-$kvNx)) -1. ) / 2 / pi / $f / (1*i*(1 - ($kvNx) ))  * exp(-2 *i*$pi*$f*($kvXx))  * ($vvNx*$vvNx)/2 ) ;
#$Tgw = $Tgw + $vvNx;


}

				}
			}


	$XXX = $XXX + abs($Tgw)**2;

		}
	}

$Tsn2Tgw = sqrt( $XXX / ($counter * $Tsn2))*299792458;
print TRANSFER "$f $Tsn2Tgw\n";

}

close TRANSFER;

}

###################### NON OCTAHEDRAL #################################

else {

###
### Full link Sky Avarage Nx = [ 1; 0; 0]; % unit vector along the arm and other Nxes!! (fehlt noch)
###

$Nx =  [
[1],
[0],
[0],
];


open TRANSFER, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt" or die $!;

print TRANSFER "# Full detector Transfer Function (Sky Avarage)\n";

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);
$counter = 0;
$T2 = 0;
	for ($lambda = 0; $lambda <= 1.9*$pi; $lambda = $lambda + 2*0.9948376736367678588465037)
        {
		for ($beta = -0.45*$pi; $beta <= 0.45*$pi; $beta = $beta + 2*0.47123889803846898576939650)
                        {        
	$counter++;

        $kv =  [[ -cos($beta)*cos($lambda), -cos($beta)*sin($lambda), -sin($beta)],]; #prop direction of GW (z)
        $uv =  [[ sin($beta)*cos($lambda), sin($beta)*sin($lambda),-cos($beta)],];
        $vv =  [[           sin($lambda),          -cos($lambda),         0],];
#       $test = $kv x $Nx; (for PDL, slow due to many instances)
        $kvNxV =  mmult($kv, $Nx); $kvNx = $kvNxV->[0]->[0];
        $uvNxV =  mmult($uv, $Nx); $uvNx = $uvNxV->[0]->[0];
        $vvNxV =  mmult($vv, $Nx); $vvNx = $vvNxV->[0]->[0];

        $Tgw =  abs(( 1.-exp(2*i*$pi*$lightsec*$f*(1-$kvNx)) ) / (2*i*$pi*$lightsec*$f*(1-$kvNx)) * ( ($uvNx)**2 - ($vvNx)**2 + 2*($uvNx)*($vvNx) )/2);
        $T2 = $T2 + $Tgw**2;
                }
        }

$T = sqrt($T2/$counter)*$armlength;
print TRANSFER "$f $T\n";

}
close TRANSFER;

}

#combined noise is sum plus acceleration and jitter for normal detectors, only litte contribution for OGO
if ($links eq "2") {$tdis = "1";} elsif ($links eq "3") {$tdis = "3";}
if ($links eq "12") {$noise ="sqrt(\$5**2+\$6**2+\$9**2)/sqrt($links)"; $linewidth = "2";}
#else {$noise = "sqrt(\$4**2+\$7**2+\$11**2)"; $linewidth = "3";}
else {$noise = "sqrt((\$7**2)*16+(sqrt(\$4**2)**2)*4)/sqrt($tdis)"; $linewidth = "3";}


open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.full.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.full.gnu: $!\n";
print GNU "set logscale\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";

print GNU "set encoding utf8\n";

print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set ylabel 'Characteristic strain amplitude'\n";


print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";

print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesignerSrc'\n";

print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/fl.svg'\n";
print GNU "set yrange [*:1e-14]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "c = 3E8 # speed of light\n";
print GNU "L = $armlength    # [m] arm-length\n";
print GNU "ConvTLNC(f,L) = (f>3e-4?(5./3.) / (  sin(2.*pi*f*L/c) )**2.:1/0)\n";

print GNU "max(x,y) = (x > y) ? x : y\n\n";

#print GNU "set label 'M_{tot} = 7 M_☉' at first 1.8e-4,2.0e-17 left front textcolor rgb '#512da8' font 'RobotoDraft,12'\n";
#print GNU "set label 'M_{tot} = 6 M_☉' at first 1.8e-3,2.0e-18 left front textcolor rgb '#512da8' font 'RobotoDraft,12'\n";
#print GNU "set label '10^5 M_☉ + 10 M_☉' at first 1.5e-2,2.0e-19 left front textcolor rgb '#0097a7' font 'RobotoDraft,12'\n";

print GNU "plot \\\n";

print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):($noise/abs(\$2)*sqrt(\$1)) w l  title '$detectorname detection limit' lw 3 lt 1 lc rgb '#e00032', \\\n";

#is this correct? this should not be sl.txt but the tf.txt for non-dfi!
if ($links eq "12") {print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):((sqrt(\$4**2+\$7**2)/$armlength./abs(\$2))/sqrt($links)*sqrt(\$1)) w l  title 'Standard TDI' lw 1 lt 1 lc rgb '#e00032', \\\n";}
else {print GNU "1  notitle, \\\n";}

print GNU "'$ENV{APP_ROOT}/designer/plotelements/smbh-m7z3.txt' every 20 u 1:5 title 'Black-hole binaries at redshift of z=3' w l lw 2 lt 1 lc rgb '#673ab7', \\\n";
print GNU "'+' using (\$0 == 0 ? 1e-4 : NaN):(2.0e-17):('M_{tot} = 10^7 M_☉') with labels offset char 0,0 left textcolor rgb '#512da8' font 'RobotoDraft,12' notitle, \\\n";
print GNU "'$ENV{APP_ROOT}/designer/plotelements/smbh-m6z3.txt' every 20 u 1:5 title '' w l lw 2 lt 1 lc rgb '#673ab7', \\\n";
print GNU "'+' using (\$0 == 0 ? 1e-3 : NaN):(2.0e-18):('M_{tot} = 10^6 M_☉') with labels offset char 0,0 left textcolor rgb '#512da8' font 'RobotoDraft,12' notitle, \\\n";
# print GNU "'$ENV{APP_ROOT}/designer/plotelements/smbh-m5z3.txt' every 20 u 1:5 title '' w l lw 2 lt 1 lc rgb '#673ab7', \\\n";
# print GNU "'+' using (\$0 == 0 ? 1e-2 : NaN):(2.0e-19):('M_{tot} = 10^5 M_☉') with labels offset char 0,0 left textcolor rgb '#512da8' font 'RobotoDraft,12' notitle, \\\n";

print GNU "'$ENV{APP_ROOT}/designer/plotelements/emri.txt' using 2:3 w lines lc rgb '#00bcd4' lw 2 lt 1 title 'EMRI with harmonics at 200 MPc', \\\n";
print GNU "     '' using 5:6 w l lc rgb '#26c6da' lw 2 lt 1 title '', \\\n";
print GNU "     '' using 8:9 w l lc rgb '#4dd0e1' lw 2 lt 1 title '', \\\n";
print GNU "     '' using 11:12 w l lc rgb '#80deea' lw 2 lt 1 title '', \\\n";
print GNU "     '' using 14:15 w l lc rgb '#b2ebf2' lw 2 lt 1 title '', \\\n";
print GNU "'+' using (\$0 == 0 ? 1e-2 : NaN):(2.0e-19):('10^5 M_☉ + 10 M_☉') with labels offset char 0,0 left textcolor rgb '#0097a7' font 'RobotoDraft,11' notitle, \\\n";

#print GNU "'$ENV{APP_ROOT}/designer/plotelements/confusion.txt' every 20 u 1:(max((sqrt(\$3*ConvTLNC(\$1,L)*\$1)), 1e-22))  w filledcurves below fill transparent solid 0.25 title 'Galactic binary confusion noise' lw 0  lt 1 lc rgb '#795548',\\\n";

print GNU "1 w l  notitle, \\\n";

print GNU "'$ENV{APP_ROOT}/designer/plotelements/verification-dwd.txt'  u (\$1):2:3 with labels left offset 0.3,0 point ps 1 pt 7 lc rgb '#8bc34a' tc rgb '#689f38' font 'RobotoDraft,12' notitle, \\\n";
print GNU "'$ENV{APP_ROOT}/designer/plotelements/verification-xrb.txt'  u (\$1):2:3 with labels left offset 0.3,0 point ps 1 pt 7 lc rgb '#cddc39' tc rgb '#afb42b' font 'RobotoDraft,12' notitle, \\\n";
print GNU "'$ENV{APP_ROOT}/designer/plotelements/verification-acs.txt'  u (\$1):2:3 with labels left offset 0.3,0 point ps 1 pt 7 lc rgb '#ffeb3b' tc rgb '#fbc02d' font 'RobotoDraft,12' notitle, \\\n";
print GNU "'$ENV{APP_ROOT}/designer/plotelements/verification-oth.txt'  u (\$1):2:3 with labels left offset 0.3,0 point ps 1 pt 7 lc rgb '#ffc107' tc rgb '#ffa000' font 'RobotoDraft,12' notitle, \\\n";
print GNU "1 with points ps 1 pt 7 lc rgb '#8bc34a' t 'Double white dwarfs', \\\n";
print GNU "1 with points ps 1 pt 7 lc rgb '#cddc39' t 'Ultra-compact X-ray binaries', \\\n";
print GNU "1 with points ps 1 pt 7 lc rgb '#ffeb3b' t 'AM CVn stars', \\\n";
print GNU "1 with points ps 1 pt 7 lc rgb '#ffc107' t 'Other galactic binaries'\n\n";
print GNU "unset output\n";

print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesignerSrc'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/flsmall.svg'\n";
print GNU "replot\n\n";
print GNU "unset output\n";

print GNU "unset logscale\n";
print GNU "unset format\n";

print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/full.txt\"\n";
print GNU "replot\n";
print GNU "unset table\n\n";


print GNU "reset\n\n";
print GNU "set samples 2\n\n";

print GNU "stats '< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):($noise/abs(\$2)) prefix \"A\"\n";

print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/results/$stamp/min.txt\"\n";
print GNU "plot '+' u (A_pos_min_y):(A_min_y)\n";
print GNU "unset table\n";

print GNU "unset output\n";


print GNU "quit\n";

close (GNU);

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tf.txt: $!\n";;
flock(LOCK, 2);
close LOCK;

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.full.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/fl.svg`;
$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/flsmall.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/characteristic-strain-amplitude.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/flsmall.svg`;


print '{"result":[{"uuid": "'.$stamp.'", "run": "'.$in{run}.'"}]}';

exit(0);


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

