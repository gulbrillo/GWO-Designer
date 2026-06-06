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

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.png`;
$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.big.png`;

}
else {

$URL = "http://spacegravity.org/lisa/files/2012/07/cooieerror.png";
print "Location: $URL\n\n";

exit();}

$pi = 3.1415926535897932384626433832795;

$armlength = $au{arm};
$links = $au{links}; #anzahl der arme
$detectorname = $au{name};

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

## strain sensitivity armlaenge
$lightsec = $armlength /299792458;

if ($links eq "12") {

open TRANSFER, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt" or die $!;

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

        for ($lambda = -0.35*$pi; $lambda <= 0.35*$pi; $lambda = $lambda + 2*1.0995574287564276334619251)
        {
                for ($beta = 0; $beta <= 0.15*$pi; $beta = $beta + 2*0.23561944901923449288469825)
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


open TRANSFER, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt" or die $!;

print TRANSFER "# Full detector Transfer Function (Sky Avarage)\n";

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

        $kv =  [[ -cos($beta)*cos($lambda), -cos($beta)*sin($lambda), -sin($beta)],];
        $uv =  [[ sin($beta)*cos($lambda), sin($beta)*sin($lambda),-cos($beta)],];
        $vv =  [[           sin($lambda),          -cos($lambda),         0],];
#       $test = $kv x $Nx; (for PDL, slow due to many instances)
        $kvNxV =  mmult($kv, $Nx); $kvNx = $kvNxV->[0]->[0];
        $uvNxV =  mmult($uv, $Nx); $uvNx = $uvNxV->[0]->[0];
        $vvNxV =  mmult($vv, $Nx); $vvNx = $vvNxV->[0]->[0];

        $Tgw =  abs(( 1.-exp(2*i*$pi*$lightsec*$f*(1-$kvNx)) ) / (2*i*$pi*$lightsec*$f*(1-$kvNx)) * ( ($uvNx)**2 - ($vvNx**2)**2 + 2*($uvNx)*($vvNx) )/2);
        $T2 = $T2 + $Tgw**2;
                }
        }

$T = sqrt($T2/$counter)*$armlength;
print TRANSFER "$f $T\n";

}
close TRANSFER;

}

#if Octahedron, remove acceleration noise
if ($links eq "12") {$noise = "\$4";}
else {$noise = "sqrt(\$4**2+\$7**2+\$11**2)";}


open(GNU, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.full.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.full.gnu: $!\n";
print GNU "set logscale\n";
print GNU "set grid\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set ylabel 'Strain in 1/{/Symbol Ö}Hz'\n";
print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";
print GNU "set terminal png enhanced transparent fontscale 0.6 size 351,197\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.png'\n";
print GNU "set yrange [*:1e-14]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/confusion.txt' u 1:2 w l title 'Binary confusion noise' lw 8 linecolor rgb 'gray',\\\n";
if ($links eq "12") {print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(sqrt(\$4**2+\$7**2+\$11**2)/$armlength./abs(\$2))/sqrt($links) w l  title '$detectorname (Standard TDI)' lw 1, \\\n";}
print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):($noise/abs(\$2)/sqrt($links)) w l  title 'Full detector stain sensitivity' lw 2  linecolor rgb 'red', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/verification.txt' u 1:2 title 'Verification binaries' w point ps 1 pt 1\n";
#print GNU "set terminal png enhanced transparent fontscale 0.8 size 560,320\n";
#print GNU "set term svg enhanced mouse size 530,340\n";
print GNU "set terminal png enhanced notransparent fontscale 0.8 size 540,360\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.big.png'\n";

print GNU "plot \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/confusion.txt' u 1:2 w l title 'Binary confusion noise' lw 8 linecolor rgb 'gray',\\\n";
if ($links eq "12") {print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):(sqrt(\$4**2+\$7**2+\$11**2)/$armlength./abs(\$2))/sqrt($links) w l  title '$detectorname (Standard TDI)' lw 1, \\\n";}
print GNU "'< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):($noise/abs(\$2)/sqrt($links)) w l  title 'Full detector stain sensitivity' lw 2  linecolor rgb 'red', \\\n";

print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/verification.txt' u 1:2:3 with labels left offset 1,0 point ps 1 pt 1   notitle\n\n";

print GNU "reset\n\n";
print GNU "set samples 2\n\n";

print GNU "stats '< paste $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt' u (\$1):($noise/abs(\$2)/sqrt($links)) prefix \"A\"\n";

print GNU "set table \"$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/min.txt\"\n";
print GNU "plot '+' u (A_pos_min_y):(A_min_y)\n";
print GNU "unset table\n";

print GNU "quit\n";
close (GNU);

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/sl.txt: $!\n";;
flock(LOCK, 2);
close LOCK;

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/plot.full.gnu`;

$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.png`;
$imagemagick = `convert $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.big.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/full.big.png`;


$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/full.png?$time";
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

