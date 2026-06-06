#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;
use Math::Trig;

use utf8;

#use UUID::Generator::PurePerl;
use Data::UUID;

use CGI;

$ug    = new Data::UUID;
$uuid1 = $ug->create_str();

#$ug = UUID::Generator::PurePerl->new();
#$uuid1 = $ug->generate_v1();

#&DATA;

# READ INPUT FORM and DECODE from UTF8
$query = CGI ->new;
$in = {};
foreach my $name ( $query ->param ) {
  my @val = $query ->param( $name );
  foreach ( @val ) {
    utf8::decode($_);

        if ($name eq "name")  {
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

$in{oe} = (100 - $in{oe});

($sek,$min,$hour,$day,$mno,$year,$wday) = (localtime(time))[0,1,2,3,4,5,6];
$time = sprintf("%02d:%02d:%02d",$hour,$min, $sek);
$year = $year+1900;
$mno = $mno+1;
$date = sprintf("%04d/%02d/%02d",$year, $mno, $day);

use CGI::Cookie;

$q = new CGI;
$ip = $q->remote_addr(); ## print the user ip address
$host = $q->remote_host();
$user = $q->user_agent();
$lang = $q->http("Accept-language");

%c = CGI::Cookie->fetch;


if ($ip ne $cip) {$cip = $ip; $cid = $time}
if (!$cid) {$cid = $time}

#TODO: PRINT in{values} to session template directory for later recovery - NICHT HIER!
#$session = $in{session};

$stamp = $cip.$cid;
$stamp =~ s/\.//g;
$stamp =~ s/\://g;
$stamp = sprintf("%x", $stamp);

$stamp   = $uuid1;

#$stamp =  $uuid1->as_string();

#binmode(STDOUT, ":utf8");

print "Content-type: text/html\n\n";

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/results/$stamp/`;
$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/`;
$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/results/$stamp/data/`;

if (-e "$ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data") {
	if (-e "$ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/LOCK") { }
		else {$return = `rm -r $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/*`;}
} else {
$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data`;
}
$return = `touch $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/LOCK`;

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp`;


open ID, ">:utf8", "$ENV{APP_ROOT}/designer/identification/$stamp.id" or die $!;
print ID "$time\n$ip\n$host\n$user\n$lang\n";
close ID;



given ($in{con}) {
	when ("two") {$in{two} = "checked"; $links="2"; }
	when ("oct") {$in{oct} = "checked"; $links="12"; }
	when ("tri") {$in{tri} = "checked"; $links="3";}
}


$armlength = $in{arm}*1e3;

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

## TEMPERATURE DATA
open PLOTTM, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tm.txt" or die $!;
print PLOTTM "#\"frequency [Hz]\"	\"Temperature stability at electronics [K/sqrt(Hz)]\"	 \"Temperature stability at optical bench [K/sqrt(Hz)]\"\n";

$ten1 = $in{ten1} * 1e-3;
$ton1 = $in{ton1} * 1e-3;
$ten2 = $in{ten2} * 1e-3;
$ton2 = $in{ton2} * 1e-3;
$ten3 = $in{ten3} * 1e-3;
$ton3 = $in{ton3} * 1e-3;

$tes1 = $in{tes1};
$tos1 = $in{tos1};
$tes3 = $in{tes3};
$tos3 = $in{tos3};

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
$tne = ($ten1*$in{tef1}**$in{tes1}/$f**$in{tes1} + $ten1*$in{tef1}**$in{tes2}/$f**$in{tes2}) / (1+$f**$in{tes3}/$in{tef2}**$in{tes3})  + $ten3;
#Temperature noise at optical bench
$tno = ($ton1*$in{tof1}**$in{tos1}/$f**$in{tos1} + $ton1*$in{tof1}**$in{tos2}/$f**$in{tos2}) / (1+$f**$in{tos3}/$in{tof2}**$in{tos3})  + $ton3;
print PLOTTM "$f	$tne	$tno\n";
$enoise{$f}=$tne;
$onoise{$f}=$tno;
}

close PLOTTM;


## TEMPERATURE NOISE PLOT

open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.gnu: $!\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded dashed size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.svg'\n";
print GNU "set logscale\n";

print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";

print GNU "set ylabel 'Temperature noise in K/√Hz'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$ton3/5:1e1]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tm.txt' u (\$1):(\$2) w l  title 'Electronics' lw 3 lt 1 lc rgb '#00bcd4', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tm.txt' u (\$1):(\$3) w l  title 'Optical bench' lw 3 lt 1 lc rgb '#ffc107'\n";

print GNU "unset output\n";
print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/temperature-noise.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/temp.svg`;

$pi = 3.1415926535897932384626433832795;

$res{imp} = 1/(2*$pi*$in{cap}*1e-12*$in{freq}*1e6);
$ires{imp} = int(100*($res{imp})+0.5)/100;
$res{pden} = sqrt(((($in{vn}*1e-9)/($res{imp}))**2)+($in{cn}*1e-12)**2)*1e12;
$ires{pden}  = int(100*($res{pden})+0.5)/100;
$res{gau} = 0.892*$in{tel}/2;
$ires{gau}  = int(100*($res{gau})+0.5)/100;
$res{ray} = $pi*($res{gau}*1e-2)**2/($in{wave}*1e-9)*1e-3;
$ires{ray}  = int(100*($res{ray})+0.5)/100;
$res{int} = 2.559*($in{tel}*1e-2/2)**2*$in{power}/(($in{wave}*1e-9)**2*($in{arm}*1e3)**2)*1e9;
$ires{int}  = int(100*($res{int})+0.5)/100;
$res{pow} = $pi*($in{tel}*1e-2/2)**2*$res{int}*$in{oe}/100*1e3;
$ires{pow}  = int(100*($res{pow})+0.5)/100;
$res{cable} = $in{sbf}*$in{sbl}*$in{temp}*$in{cps};
$ires{cable}  = int(100*($res{cable})+0.5)/100;
$res{res} = $in{wave}*1e-9*$in{qe}/100/0.000001239;
$ires{res} = int(100*($res{res})+0.5)/100;

#####
##### WERTE in SE Einheiten
#####

$ops = $in{ops} * 1e-12;
$paams = $in{paams} * 1e-12;

$cstability = $in{cps} * 1e-3 / 1e9;
$fstability = $in{fps} * 1e-3 / 1e9;
$clength = $in{sbl};
$flength = $in{ofl};
$sbfreq = $in{sbf} * 1e9;
$hfreq = $in{freq} * 1e6;
$wavelength = $in{wave}*1e-9;
$telescoped = $in{tel} * 1e-2;
$capacitance = $in{cap}*1e-12;
$qefficiency = $in{qe}/100;
$oefficiency = $in{oe}/100;

$in{ohq} = $in{he};
$hefficiency = $in{he}/100;

$tiltangle = $in{tilt}*1e-6;
$pdradius = $in{qpdd}/2/1000;
$telescoper = $telescoped/2;
$magnification = $telescoper/$pdradius;


$sbpower = $in{sbpower}/100;
$voltagen = $in{vn}*1e-9;
$currentn = $in{cn}*1e-12;
$power = $in{power};
$segments = $in{seg};
if ($segments > 1) {$segmentsUnit = "segments";} else {$segmentsUnit = "segment";}
if ($segments eq "1") {$segmentsText = "single-element photodiodes with one segment each";}
	elsif ($segments eq "4") {$segmentsText = "quadrant photodiodes with four segments each";}
	elsif ($segments eq "2") {$segmentsText = "bi-cell photodiodes with two segments each";}
	else {$segmentsText = "photodiodes, each with multiple segments";}
#$segments = 1, 2x2, 4, or 2x4!!;
$rin = $in{rin};
$phasemeasurement = $in{pm}*1e-6;
#$tdiclock = $in{tdiclock}*1e-6;
$laserfreqnoise = $in{lfn};
$ranging = $in{ranging};
$eomnoise = $in{eomnoise}*1e-3;
$fanoise = $in{fanoise}*1e-3;
$acc = $in{acc};
$zero = $in{zero} * 1e-3;
$fs = $in{fs} * 1e-3;
#####
#####
#####

#####
##### KONSTANTEN
#####

$ctez = 2e-08; #CTE(Zerodur)
$ctef = 5.5e-7; #CTE(Fused Silica)
$dndtf = 1.1e-6; #dn/dT(Fused Silica)
$rif = 1.45; #refractive index of fused silica @ 1064 nm

#####
#####
#####

#####
##### Besselfunktionen zur Berechnung der Signalleistungen
#####
$x = 1;
$m = 0;
$ii = 1;
while ($x > 0.0000001)
{
$x=$x/10;

while ($ratio <= $sbpower) {
my $j0 = Math::Cephes::j0 ($m);
my $j1 = Math::Cephes::j1 ($m);
$oldratio = $ratio;
$ratio = $j1**2/$j0**2;
$m = $m+$x;
$ii++; if ($ii > 1e8) {last;}
}

$ratio = $oldratio;
$m = $m-$x-$x;

}
$j0 = Math::Cephes::j0 ($m);
$j1 = Math::Cephes::j1 ($m);
$ratio = int(100*( $j1**2/$j0**2*100)+0.5)/100;
$powercarrier = $j0**2;
$powercarrierfactor = int(100*(1/$powercarrier)+0.5)/100;
$powersideband = $j1**2;
$powersidebandfactor =  int(100*(1/$powersideband)+0.5)/100;
$printm = int(100*($m)+0.5)/100;

#####
#####
#####


#####
##### POWER RECEIVED - kann ich mit einem Gauss-strahl alle Leistung übertragen? let's find out. Wir suchen das minimale $Wo (waist)
#####


# $Z1 = abstand emitter bis waist (bei gegebenem telescope diameter, was ist der abstand zum waist bei gegebenem waist)
# $WZ2 = Beamdiameter nach abstand waist bis receiver (bei gegebenem waist und abstand zum waist, was ist der waist, der zum geringsten strahldurchmesser führt)

$Wo = 0.0000001; #$Wo nicht bei null starten, das geht nicht.
$x = 10;
$ii = 1;

while ($x > 0.00001)
{
$x=$x/10;

$WZ2old = $Wo * sqrt(1+(($armlength/2)*$wavelength/$pi/$Wo**2)**2);
$WZ2 = $WZ2old;

while ($WZ2 <= $WZ2old) {
$oldWZ2old = $WZ2old;
$WZ2old = $WZ2;

$WZ2 = $Wo * sqrt(1+(($armlength/2)*$wavelength/$pi/$Wo**2)**2);

$Wo = $Wo+$x;

$ii++; if ($ii > 1e5) {last;}

}

$WZ2 = $oldWZ2old;
$Wo = $Wo-$x-$x-$x;
$WZ2 = $Wo * sqrt(1+(($armlength/2)*$wavelength/$pi/$Wo**2)**2);

}

$Wo = $Wo+$x/2;
$WZ2 = $Wo * sqrt(1+(($armlength/2)*$wavelength/$pi/$Wo**2)**2);

$Wocenter = $Wo;
$spotsizeatreccenter = 2* $WZ2;

if ($WZ2 < $telescoped/2) {$gaussianradius = $Wo;
$wherewaist = "center";
$wherewaisttext = "at center between spacecraft";
$spotsizeatrec = 2* $WZ2;
}
else {$gaussianradius = 0.892*$telescoped/2;
$spotsizeatrec = 2* $gaussianradius * sqrt(1+(($armlength)*$wavelength/$pi/$gaussianradius**2)**2);
$wherewaist = "transmitter";
$wherewaisttext = "at transmitting telescope";
}

if ($spotsizeatrec*1e2 < 1000)
{$printspotsizeatrec =  int(100*($spotsizeatrec*1e2)+0.5)/100; $printspotsizeatrecu = "cm";}
elsif ($spotsizeatrec < 1000)
{$printspotsizeatrec =  int(100*($spotsizeatrec)+0.5)/100; $printspotsizeatrecu = "m";}
else
{$printspotsizeatrec =  int(100*($spotsizeatrec/1e3)+0.5)/100; $printspotsizeatrecu = "km";}


#####
#####
#####


$lowaist = $gaussianradius / $magnification;
$printlowaist = $lowaist*1000; 

##### CALCULATE Heterodyne Efficiency (PAAM vs. no PAAM)


### MAXIMUM (with PAAM)
$hefficiency = ($pi* $lowaist**2 * (1 - exp(-1 * $pdradius**2/$lowaist**2)))**2/($pi*$lowaist**2/2*(1-exp(-2*$pdradius**2/$lowaist**2)) *$pi*$pdradius**2);
$maxhe = $hefficiency*$in{ohq};
$rawheteff = $hefficiency * 100;


### no PAAM (depends on tilt)

if ($in{paam} eq "no") {



$kkk = 2*$pi/$wavelength;

$tilti=0;

for ($tilt=$tiltangle/30; $tilt <= $tiltangle; $tilt=$tilt+$tiltangle/30)
{

$HE = 0;	

	for ($pdr=$pdradius/100; $pdr <= $pdradius; $pdr=$pdr+$pdradius/100)
	{
		$JJ = exp(-1*$pdr**2/$lowaist**2) * cos($magnification*$tilt)*$pdr*2*$pi/40;
		$JJJ = 0;
		for ($quad=2*$pi/40; $quad <= 2*$pi/$segments; $quad=$quad+2*$pi/40)
			{
				$JJJ=$JJJ+exp(-1*i*$kkk*$pdr*sin($quad)*tan($magnification*$tilt))*$JJ;
			}

		$HE=$HE+$JJJ*$pdradius/100;

	}

	$hefft = $segments**2*abs($HE)**2/($pi*$lowaist**2/2*(1-exp(-2*$pdradius**2/$lowaist**2))*$pi*$pdradius**2);
#	print HEFF $tilt." ".$hefft."\n";

	$tiltv[$tilti]=$tilt;
	$heffv[$tilti]=$hefft;
	$tilti++;
	
}


}

## CALCULATE THE POWER (INTENSITY)

# MAXIMUM WITH PAAM 
$intensity = 2.559*($telescoped/2)**2*$power/(($wavelength)**2*($armlength)**2);
$maxpwr = $pi*$telescoper**2*$intensity*$oefficiency;

if ($maxpwr*1e12 < 1000)
{$printreceivedmax = int(100*($maxpwr * 1e12)+0.5)/100; $printreceivedmaxu = "pW";}
elsif ($maxpwr*1e9 < 1000)
{$printreceivedmax = int(100*($maxpwr * 1e9)+0.5)/100; $printreceivedmaxu = "nW";}
elsif ($maxpwr*1e6 < 1000)
{$printreceivedmax = int(100*($maxpwr * 1e6)+0.5)/100; $printreceivedmaxu = "µW";}
elsif ($maxpwr*1e3 < 1000)
{$printreceivedmax = int(100*($maxpwr * 1e3)+0.5)/100; $printreceivedmaxu = "mW";}
else
{$printreceivedmax = int(100*($maxpwr)+0.5)/100; $printreceivedmaxu = "W";}

#print "0 ".$pi*$telescoper**2*$intensity."\n";

# NO PAAM, with tilt

if ($in{paam} eq "no") {



$amplitude = sqrt(2/($pi*$gaussianradius**2));

$tilti=0;

for ($tilt=$tiltangle/30; $tilt <= $tiltangle; $tilt=$tilt+$tiltangle/30)
{
$EEE = 0;

        for ($telr=$telescoper/40; $telr <= $telescoper; $telr=$telr+$telescoper/40)
        {

		$JJ = i/($wavelength*$armlength*cos($tilt)) * exp(i*$KKK*$armlength) * $amplitude * exp(-1*($telr**2)/$gaussianradius**2);
		$JJJ = 0;

                for ($quad=2*$pi/20; $quad <= 2*$pi; $quad=$quad+2*$pi/20)
                        {
                                $JJJ=$JJJ+$JJ*  exp(-1*i*$pi*(($armlength*sin($tilt)-$telr*sin($quad))**2+(0-$telr*cos($quad))**2)/$wavelength/($armlength*cos($tilt))) * $telr *2*$pi/20;
                        }


		$EEE = 	$EEE + $JJJ * $telescoper/40;

	}

        $powr = $power*$pi*$telescoper**2*abs($EEE)**2;
#        print PWR $tilt." ".$powr."\n";

        $pwrv[$tilti]=$powr;
        $tilti++;


}

}



# find IDEAL offset angle

if ($in{paam} eq "no") {


open(HEFFPWR, ">$ENV{APP_ROOT}/htdocs/designer/results/$stamp/hptilt.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/hptilt.txt: $!\n";

for ($counti = 0; $counti < $tilti; $counti++)
	{
	$hptilt[$counti] = $pwrv[$tilti-$counti-1] * $heffv[$counti];
	print HEFFPWR $tiltv[$counti]." ".$pwrv[$tilti-$counti-1]." ".$heffv[$counti]."\n";
	}

close(HEFFPWR);

    $hpmax = $hptilt[0];

    $counti = 0;

    foreach $hpval (@hptilt)
    {
        if ($hpval > $hpmax)
        {
            $hpmax = $hpval;
	    $hpentry = $counti;
        }
	$counti++;
    }

$hefficiency = $heffv[$hpentry] * $in{ohq}/100;
$intensity = $pwrv[$tilti-$hpentry-1] / ($pi*$telescoper**2);
$optimaltilt = $tiltv[$hpentry];

} else {

$hefficiency = $hefficiency * $in{ohq}/100;

}

$in{he} = $hefficiency * 100;

$optimaltilturad = $optimaltilt * 1000000;


#####
##### Interesting results
#####

$impedance = 1/(2*$pi*$capacitance*$hfreq);
$printimpedance = int(100*($impedance)+0.5)/100; 
$responsivity = $wavelength*$qefficiency/0.000001239;
$printresponsivity =int(100*($responsivity)+0.5)/100; 
$electronicn = sqrt(((($voltagen)/($impedance))**2)+($currentn)**2);
$printelectronicn = int(100*($electronicn*1e12)+0.5)/100;

$printgaussianradius =  int(100*($gaussianradius*1e2)+0.5)/100;
$rayleigh = $pi*($gaussianradius)**2/($wavelength);
$printrayleigh =  int(100*($rayleigh*1e-3)+0.5)/100;

if ($wherewaist eq "center")
{
$received = $power*$oefficiency;
}
else {
$received = $pi*($telescoped/2)**2*$intensity*$oefficiency;



	if ($spotsizeatrec < 10*$telescoped) {
	#TODO:
	#SPOTSIZE WARNING! (CLIPPING AND SHIT!)
	}
	#{print '<div class="help" style="background: #9a130a;overflow: hidden;width:auto; margin: 10px 0px 15px;"><div style="opacity: 1; display: block; padding: 5px 10px 5px 5px; z-index: 4; "><img src="/tools/clipping.png" width="67" height="67" style="float:left; margin-left:0px;margin-top:0px;padding-right:10px;margin-bottom:5px;"></div><p style="font-family: Century Gothic, Arial, sans-serif;font-size: 16px;color: #FFFFFF;padding-bottom:4px;">PLEASE NOTE</p><p style="color: #FFFFFF;padding-right:10px;padding-bottom:5px;">Beam diameter at the receiver ('.$printspotsizeatrec.' '.$printspotsizeatrecu.') is larger than telescope diameter ('.$in{tel}.' cm) but too small for flat intensity profile. Recieved power subject to beam pointing.</strong></p></div>';}

}





if ($intensity*1e12 < 1000)
{$printintensity =  int(100*($intensity*1e12)+0.5)/100; $printintensityu = "pW";}
elsif ($intensity*1e9 < 1000)
{$printintensity =  int(100*($intensity*1e9)+0.5)/100; $printintensityu = "nW";}
elsif ($intensity*1e6 < 1000)
{$printintensity =  int(100*($intensity*1e6)+0.5)/100; $printintensityu = "µW";}
elsif ($intensity*1e3 < 1000)
{$printintensity =  int(100*($intensity*1e3)+0.5)/100; $printintensityu = "mW";}
else
{$printintensity =  int(100*($intensity)+0.5)/100; $printintensityu = "W";}


if ($received*1e12 < 1000)
{$printreceived = int(100*($received * 1e12)+0.5)/100; $printreceivedu = "pW";}
elsif ($received*1e9 < 1000)
{$printreceived = int(100*($received * 1e9)+0.5)/100; $printreceivedu = "nW";}
elsif ($received*1e6 < 1000)
{$printreceived = int(100*($received * 1e6)+0.5)/100; $printreceivedu = "µW";}
elsif ($received*1e3 < 1000)
{$printreceived = int(100*($received * 1e3)+0.5)/100; $printreceivedu = "mW";}
else
{$printreceived = int(100*($received)+0.5)/100; $printreceivedu = "W";}







# plot tilt effects

if ($in{paam} eq "no") {

$scaling = $maxpwr+((100-$maxhe)/$maxhe)*$maxpwr;
$minimpact = sqrt($maxpwr*$maxhe/100);

$optimalloss = ($hefficiency*$received)**0.5/$minimpact*100;

# Plot the Bessel functions

open(GNU, ">$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Heterodyne efficiency in %'\n";
print GNU "set y2label 'Received power in W'\n";
print GNU "set y2tics nomirror\n";
print GNU "set ytics nomirror\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.svg'\n";

print GNU "set arrow from $optimaltilt*1000000,0 to $optimaltilt*1000000,($hefficiency*$received)**0.5/$minimpact*100 nohead  lw 1\n";

#print GNU "set arrow from $m,0 to $m,(100*besj1($m)**2/besj0($m)**2) nohead front lw 1\n";
#print GNU "set arrow from 0,(100*besj1($m)**2/besj0($m)**2) to $m,(100*besj1($m)**2/besj0($m)**2) nohead front lw 1\n";
#print GNU "set arrow from 0,(100*besj0($m)**2) to $m,(100*besj0($m)**2) nohead front lw 1\n";

#print GNU "set arrow from 0,(100*besj1($m)**2/besj0($m)**2) to 1.4,(100*besj1($m)**2/besj0($m)**2) nohead  lw 1\n";
#print GNU "set arrow from 0,(100*besj0($m)**2) to 1.4,(100*besj0($m)**2) nohead  lw 1\n";

#print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Tilt angle in urad'\n";
print GNU "set xrange [0:$tilt*1000000]\n";
print GNU "set yrange [0:100]\n";
print GNU "set y2range [0:$scaling]\n";

print GNU "set format y2 '%2.1t∙10^{%L}'\n";
print GNU "set ytics add ('0' 0)\n";
print GNU "set y2tics add ('0' 0)\n";
print GNU "set xtics add ('0' 0)\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";


print GNU "\n";

print GNU "plot \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/hptilt.txt' u (\$1*1000000):(0):((\$3*$in{ohq}/100*\$2*$oefficiency)**0.5/$minimpact*100) w filledcurve  fs transparent solid 0.1  title '' lw 0 lt rgb '#000000', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/hptilt.txt' u (\$1*1000000):(\$3*$in{ohq}) w l  title 'Heterodyne efficiency' lw 3 lt rgb '#259b24', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/hptilt.txt' u (\$1*1000000):(\$2*$oefficiency) axis x1y2 w l  title 'Received power' lw 3 lt rgb '#e91e63'\n\n";


print GNU "unset output\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/heff-vs-power.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/tilt.svg`;


}







#######
# figure out read-out noise contributions and optimal local oscillator power with gnuplot


open(GNU, ">$ENV{APP_ROOT}/htdocs/designer/results/$stamp/readout.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/readout.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Phase noise in rad/√Hz'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/ro.svg'\n";

print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Local laser power P_{local}'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$power]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "set samples 10000\n";

print GNU "\n";

print GNU "Prec = $received\n";
print GNU "q = 1.60217657e-19\n";
print GNU "Rpd = $responsivity\n";
print GNU "nhet = $hefficiency\n";
print GNU "RIN = $rin\n";
print GNU "N = $segments\n";
print GNU "Ipd = $currentn\n";
print GNU "Upd = $voltagen\n";
print GNU "Zpd = $impedance\n";

print GNU "\n";

print GNU "sn(x) = sqrt((2*q*(x+Prec))/(Rpd*nhet*x*Prec))\n";
print GNU "rin(x) = RIN*sqrt((x**2+Prec**2)/(2*nhet*x*Prec))\n";
print GNU "el(x) = sqrt(2*N)/Rpd *sqrt((Ipd**2+(Upd/Zpd)**2)/(nhet*x*Prec))\n";

print GNU "\n";

print GNU "plot \\\n";
print GNU "sqrt(sn(x)**2+rin(x)**2+el(x)**2) w l  title 'Combined read-out noise' lw 4 lt rgb '#cddc39', \\\n";
print GNU "sn(x) w l  title 'Shot noise' lw 2 lt rgb '#ff5722', \\\n";
print GNU "rin(x) w l  title 'Relative intensity noise' lw 2 lt rgb '#673ab7', \\\n";
print GNU "el(x) w l  title 'Electronic noise' lw 2 lt rgb '#00bcd4'\n\n";

print GNU "unset output\n";
print GNU "reset\n";

print GNU "set logscale\n";
print GNU "set xrange [1e-5:$power]\n";
print GNU "set samples 10000\n";
print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/results/$stamp/rodep.txt\"\n";
print GNU "plot sqrt(sn(x)**2+rin(x)**2+el(x)**2)\n";
print GNU "unset table\n\n";

print GNU "reset\n";
print GNU "set samples 2\n";
print GNU "stats '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/rodep.txt' prefix \"B\"\n";
print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/results/$stamp/plocal.txt\"\n";
print GNU "plot '+' u (B_pos_min_y):(B_min_y)\n";
print GNU "unset table\n\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/readout.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/ro.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/readout-noise-dependency.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/ro.svg`;

#######
#######

# Plot the Bessel functions

open(GNU, ">$ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Normalized power in %'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.svg'\n";

#print GNU "set arrow from $m,0 to $m,(100*besj1($m)**2/besj0($m)**2) nohead front lw 1\n";
#print GNU "set arrow from 0,(100*besj1($m)**2/besj0($m)**2) to $m,(100*besj1($m)**2/besj0($m)**2) nohead front lw 1\n";
#print GNU "set arrow from 0,(100*besj0($m)**2) to $m,(100*besj0($m)**2) nohead front lw 1\n";

print GNU "set arrow from $m,0 to $m,88 nohead  lw 1\n";
print GNU "set arrow from 0,(100*besj1($m)**2/besj0($m)**2) to 1.4,(100*besj1($m)**2/besj0($m)**2) nohead  lw 1\n";
#print GNU "set arrow from 0,(100*besj0($m)**2) to 1.4,(100*besj0($m)**2) nohead  lw 1\n";

print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Modulation depth m in rad'\n";
print GNU "set xrange [0:1.4]\n";
print GNU "set yrange [0:120]\n";
print GNU "set ytics ('0' 0, '' 20, '' 40, '' 60, '' 80, '100' 100, (100.*besj1($m)**2/besj0($m)**2))\n";
print GNU "set xtics ('0' 0, '' .2, '' .4, '' .6, '' .8, '1' 1, '' 1.2, '' 1.4, $m)\n";

print GNU "set format y \"%1.1f\"\n";
print GNU "set format x \"%1.2f\"\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "set samples 1000\n";

print GNU "\n";

print GNU "plot \\\n";
print GNU "100*besj0(x)**2 w l  title 'Carrier power J_0(m)^2' lw 3 lt rgb '#e91e63', \\\n";
print GNU "100*besj1(x)**2 w l  title '1^{st} order sideband power J_1(m)^2' lw 3 lt rgb '#673ab7', \\\n";
print GNU "100*(2/x*besj1(x)-besj0(x))**2 w l  title '2^{nd} order sideband power J_2(m)^2' lw 3 lt rgb '#5677fc', \\\n";
print GNU "100*(besj1(x)**2/besj0(x)**2) w l  title '1^{st} order sideband / carrier' lw 3 lt rgb '#259b24'\n\n";

print GNU "unset output\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/carriver-and-sideband-power.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/m.svg`;


#######
#######

#Read out optimal local oscillator power from $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plocal.txt
#$minlopower at $minloval readout noise

$file = "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/plocal.txt";
open FILE, $file or die "Could not open $file: $!";

while( my $line = <FILE>)  {
if ($line =~ /^\s\S/) {
@werte = split(/\s+/, $line);
$minloval = sprintf("%e", $werte[2]);
$minloval =~ s/e-0/e-/g;
$minloval =~ s/e0/e/g;
$minlopow = sprintf("%e", $werte[1]);
$minlopow =~ s/e-0/e-/g;
$minlopow =~ s/e0/e/g;
}

}

close(FILE);

#Umrechnungsfaktor von rad in pm
$radinpm = $wavelength/(2*$pi);



$optSn = sqrt((2*1.60217657e-19*($minlopow+$received))/($responsivity*$hefficiency*$minlopow*$received));
$optRin = $rin*sqrt(($minlopow**2+$received**2)/(2*$hefficiency*$minlopow*$received));
$optEl = sqrt(2*$segments)/$responsivity *sqrt(($currentn**2+($voltagen/$impedance)**2)/($hefficiency*$minlopow*$received));

$optSnCarrierPM = 1/$powercarrier*$radinpm*$optSn;
$optRinCarrierPM = 1/$powercarrier*$radinpm*$optRin;
$optElCarrierPM = 1/$powercarrier*$radinpm*$optEl;


#$test = `touch $ENV{APP_ROOT}/test | echo "$rin*sqrt(($minlopow**2+$received**2)/(2*$hefficiency*$minlopow*$received))\\\n1/$powercarrier*$radinpm*$optRin" > $ENV{APP_ROOT}/test`;

#$mPrec = $received;
#$mq = 1.60217657e-19;
#$mRpd = $responsivity;
#$mnhet = $hefficiency;
#$mRIN = $rin;
#$mN = $segments;
#$mIpd = $currentn;
#$mUpd = $voltagen;
#$mZpd = $impedance;



$receivedps = $received/$segments;
if ($receivedps*1e12 < 1000)
{$printreceivedps = int(100*($receivedps * 1e12)+0.5)/100; $printreceivedpsu = "pW";}
elsif ($receivedps*1e9 < 1000)
{$printreceivedps = int(100*($receivedps * 1e9)+0.5)/100; $printreceivedpsu = "nW";}
elsif ($receivedps*1e6 < 1000)
{$printreceivedps = int(100*($receivedps * 1e6)+0.5)/100; $printreceivedpsu = "µW";}
elsif ($receivedps*1e3 < 1000)
{$printreceivedps = int(100*($receivedps * 1e3)+0.5)/100; $printreceivedpsu = "mW";}
else
{$printreceivedps = int(100*($receivedps)+0.5)/100; $printreceivedpsu = "W";}

#$optimalpower = $electronicn/($responsivity*sqrt($segments)*$rin);
#$printoptimalpower = int(100*($optimalpower * 1e6)+0.5)/100;
#$lopowercarrier = $powercarrier * $optimalpower;
#$printlopowercarrier = int(100*($lopowercarrier * 1e6)+0.5)/100;
#$lopowersb = $powersideband * $optimalpower;
#$printlopowersb = int(100*($lopowersb * 1e6)+0.5)/100;

#$snr = $powercarrier * sqrt($responsivity*$hefficiency*$received/(1.6e-19+$electronicn*sqrt($segments)*$rin)); ##nicht electronicn^2? oder noch mehr zum quadrat? und plus statt mal?

$snr = 1/$powercarrier * sqrt($optSn**2 + $optRin**2 + $optEl**2);
$printsnr =  int(100*(20*log($snr)/log(10))+0.5)/100; #ist das nicht snrdb statt C/N0 in dbhz?
#$printsnr = $snr;


if ($powersideband) {
#$snrsb = $powersideband * sqrt($responsivity*$hefficiency*$received/(1.6e-19+$electronicn*sqrt($segments)*$rin));

$snrsb = 1/$powersideband * sqrt($optSn**2 + $optRin**2 + $optEl**2);
$printsnrsb =  int(100*(20*log($snrsb)/log(10))+0.5)/100; }
else {$snrsb = "0"; $printsnrsb = "0";}

#####
#####
#####


#Temperaturverlauf ist 1/f**2. Angegeben wird der Punkt bei 10 mHz (0.01 Hz). Um diesen auf 1 zu setzen, gilt: 0.01**2/f**2. Um diesen nun auf einen beliebigen wert zu setzen, gilt: WERT*0.01**2/f**2.

open PLOTPTSL, "> $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt" or die $!;
print PLOTPTSL "#frequency [Hz]  Cable	Fiber	EOM	FA	Electronics	Read-out\n";


open PLOTPM, "> $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt" or die $!;
print PLOTPM "#frequency [Hz]	summe	1/SNR Carrier	metrology	acceleration noise	sideband cable	optical pathlength noise	1/SNR Sideband\n";

open PLOTOPN, "> $ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.txt" or die $!;
print PLOTOPN "#frequency [Hz]  ULE	fused silica	telescope\n";


#Phase noise in science signal
$snrpn = $snr*$radinpm;

#timing stability requirement
$timereq = $snr /2 /$pi /$hfreq;

#Phase noise in science signal SIDEBANDS
if ($snrsb && $sbfreq) {$snrsbpn = $snrsb*$radinpm/sqrt(2)*$hfreq/$sbfreq;}
else {$snrsbpn = "0";}
#if ($links eq "12") {$snrsbpn = "0";}

#Phase measurement noise and co (sc jitter, residual clock noise)
#$pmpm = sqrt(($phasemeasurement*$radinpm)**2+($tdiclock*$radinpm)**2);

#BETTER: Phase measurement noise and co (residual frequency noise at ranging accuracy)
$pmpm = sqrt(($phasemeasurement*$radinpm)**2+($ranging*$laserfreqnoise/2.9979e8*$wavelength)**2);

$freqnoiseranging = $ranging*$laserfreqnoise/2.9979e8*$wavelength;
$freqnoisenoranging = $armlength*$laserfreqnoise/2.9979e8*$wavelength;
$phasemeasurementpm = $phasemeasurement*$radinpm;

# untere grenze für displacement plot
$plotlowpm = log(sqrt($pmpm**2+$snrpn**2))/log(10);
$plotlowpm = int($plotlowpm-.5)-2;
$plotlowpm = 10**$plotlowpm/10;


#factor for cable and fiber noise (factor times $enoise(f) = cablepm)
$cabletimes = $cstability * $clength * $sbfreq *  $hfreq / $sbfreq * $radinpm;
$fibertimes = $fstability * $flength * $sbfreq *  $hfreq / $sbfreq * $radinpm;


for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);

# one could provide a detaild frequency noise shape for the laser freq noise and do this here
#$pmpm = sqrt(($phasemeasurement*$radinpm)**2+(.3*300/$f/1e14)**2);


##Thermal noise (Optical Bench)
#Phasenoise due to Zerodur
$zerodur = abs($onoise{$f}*($zero-$fs*$ctef)*$ctez)/$wavelength*2*$pi * $radinpm;
#Phasenoise due to Fused silica
$fusedsilica = abs($onoise{$f}*$fs*($ctef*($rif-1)+$dndtf))/$wavelength*2*$pi * $radinpm;
$sumtn = sqrt(($zerodur+$fusedsilica)**2+$ops**2);

#GHz sideband cable noise

if ($sbfreq) {
$cablepm = $cstability * $clength * $sbfreq * $enoise{$f} * $hfreq / $sbfreq * $radinpm;
$fiberpm = $fstability * $flength * $sbfreq * $enoise{$f} * $hfreq / $sbfreq * $radinpm;
$eompm = $eomnoise * $hfreq / $sbfreq * $radinpm;
$fapm = $fanoise * $hfreq / $sbfreq * $radinpm;
$etmpm = $wavelength * $hfreq * $in{etm};
} else {$cablepm = "0"; $fiberpm = "0"; $eompm = "0"; $fapm = "0"; $etmpm = "0";}

#$sbsignalline = sqrt(($cablepm+$fiberpm)**2 + $fapm**2 + $eompm**2 );
$sbsignalline = $cablepm + $fiberpm + $fapm + $eompm + $etmpm; #all linear since all depend on temperature noise?

#if ($links eq "12") {$sbsignalline = "0";}

$accnoisepm = $acc /$f**2 / (2*$pi)**2;

$summe = sqrt(($snrpn+$snrsbpn)**2 + $pmpm**2  + $sbsignalline**2 + $sumtn**2);

print PLOTPM "$f $summe $snrpn $pmpm $accnoisepm $sbsignalline $sumtn $snrsbpn\n";
print PLOTPTSL "$f $cablepm $fiberpm $eompm $fapm $etmpm $snrsbpn\n";
print PLOTOPN "$f $zerodur	$fusedsilica	$ops\n";

}

close PLOTPTSL;
close PLOTPM;


#PRINT RESULTS

open(DET, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/details.json") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/details.json: $!\n";

$linknumber = $links*2;

given ($in{con}) {
        when ("two") {$constellation="60\$^{\\\\circ}\$ two-arm"; }
        when ("oct") {$constellation="octahedral twelve-arm"; }
        when ("tri") {$constellation="triangular three-arm";}
}

print DET <<EOF;
{
        "session": {
                "id": "$in{session}"
        },
	"detectorName": {
		"name": "$in{name}"
	},
        "numberOfLinks": {
                "value": "$linknumber",
		"textElement": "$constellation"
        },
        "armLength": {
                "value": "$in{arm}",
		"unit": "km"
        },
        "heterodyneFrequency": {
                "value": "$in{freq}",
                "unit": "MHz"
        },
        "laserFrequencyNoise": {
                "value": "$in{lfn}",
                "unit": "Hz/√Hz",
		"latexunit": "\\\\text{Hz}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "telescopePathlengthNoise": {
                "value": "$in{ops}",
                "unit": "pm/√Hz",
                "latexunit": "\\\\text{pm}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "telescopeDiameter": {
                "value": "$in{tel}",
		"unit": "cm"
        },
        "waistPosition": {
                "position": "$wherewaist",
                "textElement": "$wherewaisttext"
        },
        "waistTransmitter": {
                "value": "$printgaussianradius",
		"unit": "cm"
        },
        "waistLO": {
                "value": "$printlowaist",
                "unit": "mm"
        },
        "magnificationFactor": {
                "value": "$magnification"
        },
        "waistCenter": {
                "value": "$Wocenter",
                "unit": "m"
        },
        "pdDiameter": {
                "value": "$in{qpdd}",
                "unit": "mm"
        },
        "withPAAM": {
                "value": "$in{paam}"
        },
        "paamNoise": {
                "value": "$in{paams}",
                "unit": "pm/√Hz",
                "latexunit": "\\\\text{pm}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "beamIntensity": {
                "value": "$printintensity",
                "unit": "$printintensityu/m²",
		"latexunit": "\\\\text{$printintensityu}/\\\\text{m}^2"
        },
        "beamDiameterTransmitterWaist": {
                "value": "$printspotsizeatrec",
                "unit": "$printspotsizeatrecu"
        },
        "beamDiameterCenterWaist": {
                "value": "$spotsizeatreccenter",
                "unit": "m"
        },
        "receivedPower": {
                "value": "$printreceived",
                "unit": "$printreceivedu"
        },
        "receivedMax": {
                "value": "$printreceivedmax",
                "unit": "$printreceivedmaxu"
        },
        "localOscillatorPower": {
                "value": "$minlopow",
                "unit": "W",
		"unitfull": "Watts"
        },
        "laserWavelength": {
                "value": "$in{wave}",
                "unit": "nm"
        },
        "laserPower": {
                "value": "$in{power}",
                "unit": "W",
		"unitfull": "Watts"
        },
        "laserRIN": {
                "value": "$in{rin}",
                "unit": "/√Hz",
		"texunit": "/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "opticalEfficiency": {
                "value": "$in{oe}",
                "unit": "%"
        },
        "heterodyneMax": {
                "value": "$maxhe",
                "unit": "%"
        },
        "heterodyneEfficiency": {
                "value": "$in{he}",
                "unit": "%"
        },
        "rawHetEff": {
                "value": "$rawheteff",
                "unit": "%"
        },
        "heterodyneQuality": {
                "value": "$in{ohq}",
                "unit": "%"
        },
        "quantumEfficiency": {
                "value": "$in{qe}",
                "unit": "%"
        },
        "photodiodeResponsivity": {
                "value": "$printresponsivity",
                "unit": "A/W",
		"texunit": "\\\\text{A}/\\\\text{W}"
        },
	"photodiodeSegments": {
		"value": "$segments",
		"unit": "$segmentsUnit",
		"textElement": "$segmentsText"
	},
        "voltageNoise": {
                "value": "$in{vn}",
                "unit": "nV/√Hz",
		"texunit": "\\\\text{nV}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "currentNoise": {
                "value": "$in{cn}",
                "unit": "pA/√Hz",
                "texunit": "\\\\text{pA}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "photodiodeImpedance": {
                "value": "$printimpedance",
                "unit": "Ω",
		"texunit": "\\\\Omega"
        },
        "photodiodeCapacitance": {
                "value": "$in{cap}",
                "unit": "pF"
        },
        "OPDob": {
                "value": "$in{zero}",
                "unit": "mm"
        },
        "OPDfs": {
                "value": "$in{fs}",
                "unit": "mm"
        },
        "temperatureElectronics": {
                "n1": "$in{ten1}",
		"n2": "$in{ten2}",
		"n3": "$in{ten3}",
                "unit": "mk/√Hz",
		"texunit": "\\\\text{mK}/{\\\\sqrt{\\\\text{Hz}}}",
		"f1": "$in{tef1}",
		"f2": "$in{tef2}",
		"funit": "Hz",
                "s1": "$tes1",
                "s3": "$tes3"
        },
        "temperatureOptics": {
                "n1": "$in{ton1}",
                "n2": "$in{ton2}",
                "n3": "$in{ton3}",
                "unit": "mk/√Hz",
                "texunit": "\\\\text{mK}/{\\\\sqrt{\\\\text{Hz}}}",
                "f1": "$in{tof1}",
                "f2": "$in{tof2}",
		"funit": "Hz",
                "s1": "$tos1",
                "s3": "$tos3"
        },
	"sidebandPower": {
		"value": "$in{sbpower}",
		"m": "$printm",
		"unit": "%",
		"unitm": "rad"
	},
        "levelFactors": {
                "carrier": "$powercarrierfactor",
                "sideband": "$powersidebandfactor"
        },
        "timingRequirement": {
                "value": "$timereq",
                "unit": "s/√Hz",
                "texunit": "\\\\text{s}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierReadOut": {
                "value": "$snrpn",
                "unit": "m/√Hz",
		"texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
		"texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierReadOutPn": {
                "value": "$snr",
                "unit": "rad/√Hz",
                "texunit": "\\\\text{rad}/{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierShotNoise": {
                "value": "$optSnCarrierPM",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierRIN": {
                "value": "$optRinCarrierPM",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierElectronicNoise": {
                "value": "$optElCarrierPM",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "totalReadoutNoise": {
                "value": "$minloval",
                "unit": "rad/√Hz",
		"texunit": "\\\\text{rad}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{rad}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "electricTimingNoise": {
                "value": "$in{etm}",
                "unit": "s/√Hz",
                "texunit": "\\\\text{s}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{s}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "electricPTNoise": {
                "value": "$etmpm",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "sidebandReadOut": {
                "value": "$snrsbpn",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "modulationFrequency": {
                "value": "$in{sbf}",
                "unit": "GHz"
        },
        "cableLength": {
                "value": "$in{sbl}",
                "unit": "m"
        },
        "fiberLength": {
                "value": "$in{ofl}",
                "unit": "m"
        },
        "thermalStabilityCables": {
                "value": "$in{cps}",
                "unit": "mrad/(K·m·GHz)",
                "texunit": "\\\\text{mrad}/{\\\\left(\\\\text{K}\\\\:\\\\text{m}\\\\:\\\\text{GHz}\\\\right)}",
                "texunit2": "\\\\frac{\\\\text{mrad}}{\\\\text{K}}\\\\:\\\\frac{1}{\\\\text{m} \\\\times \\\\text{GHz}}"
        },
        "thermalStabilityFibers": {
                "value": "$in{fps}",
                "unit": "mrad/(K·m·GHz)",
                "texunit": "\\\\text{mrad}/{\\\\left(\\\\text{K}\\\\:\\\\text{m}\\\\:\\\\text{GHz}\\\\right)}",
                "texunit2": "\\\\frac{\\\\text{mrad}}{\\\\text{K}}\\\\:\\\\frac{1}{\\\\text{m} \\\\times \\\\text{GHz}}"
        },
        "optimalTilt": {
                "value": "$optimaltilturad",
                "unit": "µrad",
                "texunit": "\\\\upmu\\\\text{rad}"
        },
        "optimalLoss": {
                "value": "$optimalloss",
                "unit": "%"
        },
        "cableNoise": {
                "value": "$cabletimes",
                "unit": "m/K",
                "texunit": "\\\\text{m}/{\\\\text{K}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\text{K}}"
        },
        "fiberNoise": {
                "value": "$fibertimes",
                "unit": "m/K",
                "texunit": "\\\\text{m}/{\\\\text{K}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\text{K}}"
        },
        "eomNoise": {
                "value": "$eompm",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "faNoise": {
                "value": "$fapm",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "eomPhaseNoise": {
                "value": "$eomnoise",
                "unit": "rad/√Hz",
                "texunit": "\\\\text{rad}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{rad}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "faPhaseNoise": {
                "value": "$fanoise",
                "unit": "rad/√Hz",
                "texunit": "\\\\text{rad}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{rad}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "accelerationNoise": {
                "value": "$in{acc}",
		"unit": "m/s²/√Hz × 1/f²/(2π)²",
		"texunit": "\\\\text{m}\\\\:\\\\text{s}^{-2}/\\\\sqrt{\\\\text{Hz}}",
		"texunit2": "\\\\frac{\\\\text{m}/\\\\text{s}^2}{\\\\sqrt{\\\\text{Hz}}} \\\\times \\\\frac{1}{\\\\left(2\\\\pi\\\\:f\\\\right)^2}"
        },
        "rangingAccuracy": {
                "value": "$in{ranging}",
		"unit": "m"
        },
        "freqNoiseNoRanging": {
                "value": "$freqnoisenoranging",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"

        },
        "freqNoiseRanging": {
                "value": "$freqnoiseranging",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "beamTilt": {
                "value": "$in{tilt}",
                "unit": "µrad",
                "texunit": "\\\\upmu\\\\text{rad}",
                "texunit2": "\\\\upmu\\\\text{rad}"
        },
        "metrologySystem": {
                "value": "$in{pm}",
                "unit": "µrad/√Hz",
                "texunit": "\\\\upmu\\\\text{rad}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\upmu\\\\text{rad}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "metrologySystemDisp": {
                "value": "$phasemeasurementpm",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "metrologySystemTotal": {
                "value": "$pmpm",
                "unit": "m/√Hz",
                "texunit": "\\\\text{m}/{\\\\sqrt{\\\\text{Hz}}}",
                "texunit2": "\\\\frac{\\\\text{m}}{\\\\sqrt{\\\\text{Hz}}}"
        },
        "carrierPowerBessel": {
                "value": "$powercarrier"
        },
        "sidebandPowerBessel": {
                "value": "$powersideband"
        }




}
EOF

#print DET "detector name;$in{name};;[name];\r\n";
#print DET "armlength;$in{arm};km;[armlength];\r\n";
#print DET "number of arms;$links;;[links];\r\n";

#print DET "maximum heterodyne frequency;$in{freq};MHz;[fhet];\r\n";
#print DET "laser wavelength;$in{wave};nm;[laser];\r\n";
#print DET "relative intensity noise;$in{rin};/sqrt(Hz);[rin];\r\n";

#print DET "optical power to telescope;$in{power};W;[power];\r\n";
#print DET "telescope diameter;$in{tel};cm;[diameter];\r\n";
#print DET "optical efficiency;$in{oe};%;[oeff];\r\n";

#print DET "waist located at;$wherewaist;;[waistlocation];\r\n";
#print DET "Gaussian radius (at waist);$printgaussianradius;cm;[waistradius];\r\n";
#print DET "Rayleigh length;$printrayleigh;km;[rayleigh];\r\n";
#print DET "beam diameter at receiver;$printspotsizeatrec;$printspotsizeatrecu;[beamdiameter];\r\n";
#print DET "beam diameter at receiver when waist at center;$spotsizeatreccenter;m;[beamdiameterforcenter];\r\n";
#print DET "optimal waist when waist at center;$Wocenter;m;[waistforcenter];\r\n";
#print DET "intensity at receiver;$printintensity;$printintensityu/m^2;[intensity];\r\n";
#print DET "received power;$printreceived;$printreceivedu;[received];\r\n";
#print DET "detected power per segment;$printreceivedps;$printreceivedpsu;[detected];\r\n";

close (GNU);

#Photodiode impedance: $printimpedance Ohm<br>
#Photodiode responsitivity: $printresponsivity A/W<br>
#Electronic noise: $printelectronicn pA/Hz<br>
#Signal to noise ratio (Carrier): $printsnr dBHz<br>
#Signal to noise ratio (Sideband): $printsnrsb dBHz<br>
#Modulation index (EOM): $printm<br>
#Optimal power LO (per segment): $printoptimalpower &mu;W<br>
#Optical power (LO carrier): $printlopowercarrier &mu;W<br>
#Optical power (single LO sideband): $printlopowersb &mu;W<br>





open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Displacement noise in m/√Hz'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.svg'\n";

print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$plotlowpm:1e-6]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";

#if ($links eq "12") {$noise ="\$2"; $linewidth = "2";} else {$noise = "sqrt(\$2**2+\$5**2+\$9**2)"; $linewidth = "3";}

#combined noise is sum plus acceleration and jitter for normal detectors, only litte contribution for OGO
if ($links eq "12") {$noise ="sqrt(\$3**2+\$4**2+\$7**2)"; $linewidth = "2";} else {$noise = "sqrt(\$2**2+\$5**2)"; $linewidth = "3";}

print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):($noise) w l  title 'Combined displacement noise' lw 8 lt rgb '#9e9e9e',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$3) w l  title 'Read-out noise (carrier signal)' lw 3 lt rgb '#e91e63',\\\n";

#if ($links ne "12") {
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$8) w l  title 'Read-out noise (sideband signal)' lw $linewidth lt rgb '#673ab7',\\\n"; 
#}

#if ($links ne "12") {
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$6) w l  title 'Pilot tone transmission line noise' lw $linewidth lt rgb '#5677fc',\\\n";
#}


print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$4) w l  title 'Metrology system / data processing' lw 3 lt rgb '#00bcd4',\\\n";

print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$7) w l  title 'Optical pathlength noise' lw 3 lt rgb '#259b24', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$5) w l  title 'Acceleration noise' lw $linewidth lt rgb '#ffc107'\n\n";
#print GNU "set terminal png enhanced transparent fontscale 0.8 size 560,320\n";
#print GNU "set term svg enhanced mouse size 530,340\n";
#print GNU "set terminal png enhanced notransparent fontscale 0.8 size 540,360\n";
#print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.big.png'\n";
# print GNU "set ylabel 'Displacement in m/Hz^{-0.5}'\n";
#print GNU "replot\n";
#print GNU "replot\n";
print GNU "unset output\n";



print GNU "unset logscale\n";
print GNU "unset format\n";

print GNU "set table \"$ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.txt\"\n";
print GNU "replot\n";
print GNU "unset table\n\n";


print GNU "quit\n";
close (GNU);



$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/displacement-noise-sources.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.svg`;

$columnhead = `sed -i.bak s/#[[:space:]]Curve[[:space:]]title:/Title/ $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.txt`;
$rmbak = `rm $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.txt.bak`;

open(GNU, ">", "$ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.gnu: $!\n";

print GNU "# This work is licensed under a Creative Commons Attribution 4.0 International License.\n";
print GNU "# http://creativecommons.org/licenses/by/4.0/\n";
print GNU "# Licensees may copy, distribute, display and perform the work and make derivative works based\n";
print GNU "# on it only if they give the author or licensor the credits in the manner specified by these.\n";
print GNU "# \n";
print GNU "# Please cite: Simon Barke et al.\n";
print GNU "# Towards a Gravitational Wave Observatory Designer: Sensitivity Limits of Spaceborne Detectors.\n";
print GNU "# 2015 Class. Quantum Grav. 32 095004. (doi:10.1088/0264-9381/32/9/095004)\n\n\n";

print GNU "reset\n\n";

print GNU "set key autotitle columnhead\n\n";

print GNU "datafile = 'displacement.txt'\n";
print GNU "stats datafile\n";
print GNU "BLK = STATS_blocks-1\n\n";

print GNU "set linetype 1 lw 10 lc rgb '#9e9e9e'\n";		  
print GNU "set linetype 2 lw 3 lc rgb '#e91e63'\n";
print GNU "set linetype 3 lw 3 lc rgb '#673ab7'\n";
print GNU "set linetype 4 lw 3 lc rgb '#5677fc'\n";
print GNU "set linetype 5 lw 3 lc rgb '#00bcd4'\n";
print GNU "set linetype 6 lw 3 lc rgb '#259b24'\n";
print GNU "set linetype 7 lw 3 lc rgb '#cddc39'\n";
print GNU "set linetype 8 lw 3 lc rgb '#ffc107'\n";
print GNU "set linetype 9 lw 3 lc rgb '#ff5722'\n\n";

print GNU "set logscale\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";

print GNU "set encoding utf8\n";

print GNU "set ylabel 'Displacement noise in m/√Hz'\n";
print GNU "set xlabel 'Frequency in Hz'\n";

print GNU "set term pngcairo size 1600,1000 enhanced font ',20'\n";
print GNU "set output 'displacement.png'\n";

print GNU "set title 'http://spacegravity.org/designer/#rc=$in{session}'\n";

print GNU "plot for [IDX=0:BLK] 'displacement.txt' index IDX u 1:2 title columnhead(2) w l lt IDX+1\n";



print GNU "unset output\n";

print GNU "quit\n";


close (GNU);


$gnuplot = `cd $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/ && gnuplot displacement.gnu`;

$imagemagick = `convert $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.png $ENV{APP_ROOT}/designer/latexelements/designer_watermark.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/designer/sessions/$in{session}/data/$stamp/displacement.png`;












open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Displacement noise in m/√Hz'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.svg'\n";

print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$plotlowpm:1e-6]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";

print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$7) w l  title 'Total optical pathlength noise' lw 8 lt rgb '#9e9e9e', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.txt' u (\$1):(\$2) w l  title 'Thermo-elastic noise (ULE)' lw 3 lt rgb '#e91e63',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.txt' u (\$1):(\$3) w l  title 'Thermo-optical noise (fused silica)' lw $linewidth lt rgb '#3f51b5',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.txt' u (\$1):(\$4) w l  title 'Telescope' lw $linewidth lt rgb '#00bcd4'\n\n";

print GNU "unset output\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/optical-pathlength-noise.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/opn.svg`;





open(GNU, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$stamp/ptsl.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plot.gnu: $!\n";

print GNU "set encoding utf8\n";
print GNU "set term svg enhanced mouse jsdir \"/designer/gnuplot.js/\" rounded solid size 800,500 dynamic font 'RobotoDraft,16' name 'GWODesigner'\n";
print GNU "set ylabel 'Displacement noise in m/√Hz'\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.svg'\n";

print GNU "set logscale\n";
print GNU "set grid lt 1 lw 0.5 lc rgb '#9e9e9e'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [$plotlowpm:1e-6]\n";

print GNU "set object 1 rectangle from graph 0,0 to graph 1,1 behind fc rgb \"#ffffff\"\n";

print GNU "plot \\\n";


print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$7) w l  title 'Total read-out noise (sideband signal)' lw 8 lt rgb '#e91e63',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.txt' u (\$1):(\$6) w l  title 'Total pilot tone transmission chain noise' lw 8 lt rgb '#9e9e9e', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$6) w l  title 'Electrical components' lw 2 lt rgb '#3f51b5',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$2) w l  title 'Electrical cables' lw 2 lt rgb '#00bcd4',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$3) w l  title 'Optical fibers' lw 2 lt rgb '#8bc34a',\\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$4) w l  title 'Electro-optic modulator' lw 2 lt rgb '#ffc107', \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.txt' u (\$1):(\$5) w l  title 'Fiber amplifier' lw 2 lt rgb '#795548'\n";

print GNU "unset output\n";

print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/designer/results/$stamp/ptsl.gnu`;

$nostroke = `sed -i.bak s/stroke-width=\\"1\\"/stroke-width=\\"0\\"/ $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/results/$stamp/plots/clock-noise.pdf $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pt.svg`;




#$imagemagick = `convert $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.png`;
#$imagemagick = `convert $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.big.png $ENV{APP_ROOT}/htdocs/tools/overlay.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/designer/results/$stamp/pm.big.png`;




print '{"result":[{"uuid": "'.$stamp.'", "run": "'.$in{run}.'"}]}';



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

