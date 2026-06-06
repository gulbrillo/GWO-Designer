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

	if ($name eq "name" || $name eq "plottitle" || $name eq "con")	{
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

$return = `rm $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sa.svg`;
$return = `cp $ENV{APP_ROOT}/htdocs/designer/results/$stamp/details.json $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/parameters.json`; 


}
else {

print '{"result":[{"uuid": "", "illegal": "true"}]}';
exit();

}

###
### Single link Sky Avarage Nx = [ 1; 0; 0]; % unit vector along the arm
### 

$Nx =  [
[1],
[0],
[0],
];

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


open SINGLET, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt" or die $!;

flock(SINGLET, 2);

print SINGLET "# Single Link Transfer Function (Sky Avarage)\n";

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

        $kv =  -cos($beta)*cos($lambda);
        $uv =  sin($beta)*cos($lambda);
        $vv =  sin($lambda);

        $Tgw =  abs(( 1.-exp(2*i*$pi*$lightsec*$f*(1-$kv)) ) / (2*i*$pi*$lightsec*$f*(1-$kv)) * ( ($uv)**2 - ($vv)**2 + 2*($uv)*($vv) )/2);
	#$Tgw =  abs(( 1.-exp(2*i*$pi*$lightsec*$f*(1-$kv)) ) / (2*i*$pi*$lightsec*$f*(1-$kv)));
        $T2 = $T2 + $Tgw**2;
                }
        }

$T = sqrt($T2/$counter);

print SINGLET "$f $T\n";

}


close SINGLET;


open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.single.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.single.gnu: $!\n";
print GNU "set logscale\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";

print GNU "set encoding utf8\n";

print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set ylabel 'Strain sensitivity in 1/√Hz'\n";

print GNU "set xlabel 'Gravitational wave frequency in Hz'\n";

print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";

print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/sa.svg'\n";
print GNU "set yrange [*:1e-14]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";

if ($links eq "12") {print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(sqrt(\$5**2+\$6**2+\$9**2)/$armlength./abs(\$2)) w l  title 'With DFI suppression' lw 2 lt 1 lc rgb '#00bcd4', \\\n";} else {

print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(sqrt((\$5+\$10)**2)/$armlength./abs(\$2)) w l  title \"Read-out noise (i.a. shot noise)\" lw 2 lt 1 lc rgb '#00bcd4', \\\n";
print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(sqrt(\$7**2)/$armlength./abs(\$2)) w l  title \"Acceleration noise (proof mass)\" lw 2 lt 1 lc rgb '#cddc39', \\\n";

}

print GNU "'< paste $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sl.txt $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(sqrt(\$4**2+\$7**2)/$armlength./abs(\$2)) w l  title \"Single link $detectorname sensitivity\" lw 3 lt 1 lc rgb '#e00032'\n";

print GNU "\n";

print GNU "unset output\n";
print GNU "quit\n";

close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.single.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sa.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/singlearm-strain-sensitivity.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/sa.svg`;

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

