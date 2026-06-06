#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;
use Scalar::Util qw(looks_like_number);

use utf8;

&DATA;

binmode(STDOUT, ":utf8");
print "Content-type: text/html\n\n";

#if nothing that must not be null is not null, do the plots
if ( !$in{tef2} || !looks_like_number($in{tef2}) || !$in{tof2} || !looks_like_number($in{tof2}) || 
	!$in{tef1} || !looks_like_number($in{tef1}) || !$in{tof1} || !looks_like_number($in{tof1}) ||
	!$in{ten2} || !looks_like_number($in{ten2}) || !$in{ton2} || !looks_like_number($in{ton2}) ||
	!$in{ten1} || !looks_like_number($in{ten1}) || !$in{ton1} || !looks_like_number($in{ton1}) ||
	!$in{ten3} || !looks_like_number($in{ten3}) || !$in{ton3} || !looks_like_number($in{ton3}) ||
	!looks_like_number($in{tes1}) || !looks_like_number($in{tos1}) ||
	!looks_like_number($in{tes3}) || !looks_like_number($in{tos3})  
) {

print '{"result":[{"uuid": "", "illegal": "true"}]}';

exit(0);

}



#check if an armlength is given, else just take a standard one
if ( !$in{arm} || !looks_like_number($in{arm}) ) { $in{arm} = "3000000"; }

($sek,$min,$hour,$day,$mno,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
$time = sprintf("%02d:%02d:%02d",$hour,$min, $sek);
$year = $year+1900;
$mno = $mno+1;
$date = sprintf("%04d/%02d/%02d",$year, $mno, $day);

use CGI;
use CGI::Cookie;

$q = new CGI;
$ip = $q->remote_addr(); ## print the user ip address
$host = $q->remote_host();
$user = $q->user_agent();
$lang = $q->http("Accept-language");

%c = CGI::Cookie->fetch;


if ($ip ne $cip) {$cip = $ip; $cid = $time}
if (!$cid) {$cid = $time}

if ($in{session} =~ /[0-9a-zA-Z]+/ && $in{session} ne "undefined") {
$stamp = $in{session};
} else {
$stamp = $cip.$cid;
$stamp =~ s/\.//g;
$stamp =~ s/\://g;
$stamp = sprintf("%x", $stamp);
}

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/`;

open ID, ">:utf8", "$ENV{APP_ROOT}/designer/identification/$stamp.id" or die $!;
print ID "$time\n$ip\n$host\n$user\n$lang\n";
close ID;


$armlength = $in{arm}*1e3;

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

## TEMPERATURE DATA
open PLOTTM, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/tm.txt" or die $!;
print PLOTTM "#\"frequency [Hz]\"	\"Temperature stability at electronics [K/sqrt(Hz)]\"	 \"Temperature stability at optical bench [K/sqrt(Hz)]\"\n";

$ten1 = $in{ten1} * 1e-3;
$ton1 = $in{ton1} * 1e-3;
$ten2 = $in{ten2} * 1e-3;
$ton2 = $in{ton2} * 1e-3;
$ten3 = $in{ten3} * 1e-3;
$ton3 = $in{ton3} * 1e-3;


$in{tes1} = -1 * $in{tes1};
$in{tos1} = -1 * $in{tos1};
$in{tes2} = -1 * log($ten2/$ten1) / log(($in{tef2}/$in{tef1}));
$in{tos2} = -1 * log($ton2/$ton1) / log(($in{tof2}/$in{tof1}));
$in{tes3} = -1 * $in{tes3} - $in{tes2};
$in{tos3} = -1 * $in{tos3} - $in{tos2};

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);
#Temperature noise at electronics
$tne = ($ten1*$in{tef1}**$in{tes1}/$f**$in{tes1} + $ten1*$in{tef1}**$in{tes2}/$f**$in{tes2}) / (1+$f**$in{tes3}/$in{tef2}**$in{tes3}) + $ten3 ;

#Temperature noise at optical bench
$tno = ($ton1*$in{tof1}**$in{tos1}/$f**$in{tos1} + $ton1*$in{tof1}**$in{tos2}/$f**$in{tos2}) / (1+$f**$in{tos3}/$in{tof2}**$in{tos3}) + $ton3 ;
print PLOTTM "$f	$tne	$tno\n";
$enoise{$f}=$tne;
$onoise{$f}=$tno;
}

close PLOTTM;


## TEMPERATURE NOISE PLOT

open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/temp.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/temp.gnu: $!\n";
print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/temp.svg'\n";
print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";

print GNU "set ylabel 'Temperature noise in K/√Hz'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$ton3/5:1e1]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "set label 'Noise floor (electronics)' at (1.5e-5),($ten3*2) textcolor rgb '#00bcd4' font 'RobotoDraft,14'\n";
print GNU "set label 'Noise floor (optics)' at (1.5e-5),($ton3*2) textcolor rgb '#ffc107' font 'RobotoDraft,14'\n";

print GNU "set arrow 10 from ($in{tef1}),($ten1/2.5) to ($in{tef1}),($ten1*5) nohead\n";
print GNU "set arrow 11 from ($in{tef1}/2.2),($ten1) to ($in{tef1}*2.2),($ten1) nohead\n";
print GNU "set label 'f1' at ($in{tef1}),($ten1/5.) center textcolor rgb '#000000' font 'RobotoDraft,14'\n";

print GNU "set arrow 12 from ($in{tof1}),($ton1/2.5) to ($in{tof1}),($ton1*5) nohead\n";
print GNU "set arrow 13 from ($in{tof1}/2.2),($ton1) to ($in{tof1}*2.2),($ton1) nohead\n";
print GNU "set label 'f1' at ($in{tof1}),($ton1/5.) center textcolor rgb '#000000' font 'RobotoDraft,14'\n";

print GNU "set arrow 14 from ($in{tef2}),($ten2/2.5) to ($in{tef2}),($ten2*5) nohead\n";
print GNU "set arrow 15 from ($in{tef2}/2.2),($ten2) to ($in{tef2}*2.2),($ten2) nohead\n";
print GNU "set label 'f2' at ($in{tef2}),($ten2/5.) center textcolor rgb '#000000' font 'RobotoDraft,14'\n";

print GNU "set arrow 16 from ($in{tof2}),($ton2/2.5) to ($in{tof2}),($ton2*5) nohead\n";
print GNU "set arrow 17 from ($in{tof2}/2.2),($ton2) to ($in{tof2}*2.2),($ton2) nohead\n";
print GNU "set label 'f2' at ($in{tof2}),($ton2/5.) center textcolor rgb '#000000' font 'RobotoDraft,14'\n";


print GNU "plot \\\n";
print GNU "$ten3 w l title '' lw 1 lt 3 lc rgb '#00bcd4', \\\n";
print GNU "$ton3 w l title '' lw 1 lt 3 lc rgb '#ffc107', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/tm.txt' u (\$1):(\$2) w l  title 'Electronics' lw 3 lt 1 lc rgb '#00bcd4', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/tm.txt' u (\$1):(\$3) w l  title 'Optics' lw 3 lt 1 lc rgb '#ffc107'\n";

print GNU "unset output\n";
print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/temp.gnu`;


print '{"result":[{"uuid": "'.$stamp.'", "run": "0"}]}';

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

