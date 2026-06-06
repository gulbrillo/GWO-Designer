#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;

$in{calculate} = "1";
&DATA;

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

if ($c{'SPACEGRAVITYIP'}) {$cip = $c{'SPACEGRAVITYIP'}->value;}
if ($c{'SPACEGRAVITYID'}) {$cid = $c{'SPACEGRAVITYID'}->value;}

if ($ip ne $cip) {$cip = $ip; $cid = $time}
if (!$cid) {$cid = $time}

$stamp = $cip.$cid;
$stamp =~ s/\.//g;
$stamp =~ s/\://g;
$stamp = sprintf("%x", $stamp);

$cookieip = CGI::Cookie->new(-name=>'SPACEGRAVITYIP',
                            -value=>$cip,
                            -expires=>'+4h',
                           );

$cookieid = CGI::Cookie->new(-name=>'SPACEGRAVITYID',
                            -value=>$cid,
                            -expires=>'+4h',
                           );


#print "Content-type: text/html\n\n";
print $q->header(-cookie=>[$cookieip,$cookieid]);


$return = `mkdir $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/`;
$return = `cp -rp $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/verification.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/`;
$return = `cp -rp $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/confusion.txt $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/`;

open ID, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/identify" or die $!;
print ID "$time\n$ip\n$host\n$user\n$lang\n";
close ID;


open FILE, "head.htm" or die $!;
my @lines = <FILE>;
close FILE;

print @lines;

if ($au{var} eq "index") {$in{load} = "lisa";}

if ($in{load}) {

$in{arm} = "5000000"; $in{tel} = "38"; $in{wave} = "1064"; $in{power} = "1"; $in{oe} = "70"; $in{freq} = "25"; $in{he} = "70"; $in{rin} = "1e-8"; $in{cap} = "10"; $in{qe} = "80"; $in{seg} = "8"; $in{vn} = "2"; $in{cn} = "2"; $in{pm} = "6";  $in{zero} = "565"; $in{fs} = "29"; $in{sbl} = "2"; $in{cps} = "7"; $in{sbf} = "2.4"; $in{ten1} = "2"; $in{ton1} = "0.004"; $in{ten2} = "0.001"; $in{ton2} = "0.0002"; $in{tef1} = "3e-3"; $in{tof1} = "1e-2"; $in{tef2} = "5e-2"; $in{tof2} = "1e-1"; $in{tes1} = "2"; $in{tes2} = "0.1"; $in{tes3} = "1"; $in{tos1} = "2"; $in{tos2} = "0.5"; $in{tos3} = "0"; $in{ofl} = "5"; $in{fps} = "1"; $in{eomnoise} = "0.3"; $in{fanoise} = "0.6"; $in{acc} = "3e-15"; $in{sbpower} = "7.5"; $in{name} = "LISA-like"; $in{scjitter}="6"; $in{tdiclock}="6";

given ($in{load}) {
	when ("lisa") { $in{tri} = "checked";}
	when ("elisa") {$in{arm} = "1000000"; $in{tel} = "20"; $in{wave} = "1064"; $in{power} = "1"; $in{oe} = "70"; $in{freq} = "25"; $in{he} = "70"; $in{rin} = "1e-8"; $in{cap} = "10"; $in{qe} = "80"; $in{seg} = "8"; $in{vn} = "2"; $in{cn} = "2"; $in{pm} = "6"; $in{two} = "checked"; $in{sbf} = "2.4"; $in{name} = "eLISA-like"}
	when ("ogo") {$in{arm} = "1414"; $in{tel} = "100"; $in{wave} = "512"; $in{power} = "10"; $in{oe} = "70"; $in{freq} = "0.1"; $in{he} = "80"; $in{rin} = "1e-9"; $in{cap} = "10"; $in{qe} = "90"; $in{seg} = "8"; $in{vn} = "1"; $in{cn} = "1"; $in{pm} = "6"; $in{oct} = "checked"; $in{sbf} = "2.4"; $in{name} = "OGO-like"; $in{tdiclock} = "0"; $in{pm} = "0.0001"; $in{ton1} = "0.004"; $in{ton2} = "0.000001"; $in{tof1} = "1e-4"; $in{tof2} = "1e-3"; $in{tos1} = "1"; $in{tos2} = "1"; $in{tos3} = "2";  $in{zero} = "100"; $in{fs} = "10"; $in{sbf} = "0"; $in{sbpower} = "0"; $in{eomnoise} = "0"; $in{fanoise} = "0";  $in{ofl} = "0"; $in{fps} = "0"; $in{sbl} = "0"; $in{cps} = "0";  $in{ten1} = "20"; $in{ten2} = "0.01"; }
}

if ($au{var} eq "calculate") {$in{calculate} = "2";}

} elsif ($au{var} eq "calculate") {

given ($in{con}) {
	when ("two") {$in{two} = "checked"; $links="2"; }
	when ("oct") {$in{oct} = "checked"; $links="12"; }
	when ("tri") {$in{tri} = "checked"; $links="3";}
}

}

$armlength = $in{arm}*1e3;

# rechte grenze für alle plots
$gwavefreq = 1 / $armlength * 299792458 /2;
$gwavefreq = log($gwavefreq)/log(10);
if ($gwavefreq < 0) {$gwavefreq = int($gwavefreq-.5);} else {$gwavefreq = int($gwavefreq+.5);}
$gwavefreq = int($gwavefreq + 3);
$gwavefreqf = 10**$gwavefreq;

## TEMPERATURE DATA
open PLOTTM, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tm.txt" or die $!;
print PLOTTM "#\"frequency [Hz]\"	\"Temperature stability at electronics [K/sqrt(Hz)]\"	 \"Temperature stability at optical bench [K/sqrt(Hz)]\"\n";

$ten1 = $in{ten1} * 1e-3;
$ton1 = $in{ton1} * 1e-3;
$ten2 = $in{ten2} * 1e-3;
$ton2 = $in{ton2} * 1e-3;

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);
#Temperature noise at electronics
$tne = ($ten1*$in{tef1}**$in{tes1}/$f**$in{tes1} + $ten1*$in{tef1}**$in{tes2}/$f**$in{tes2}) / (1+$f**$in{tes3}/$in{tef2}**$in{tes3})  + $ten2;
#Temperature noise at optical bench
$tno = ($ton1*$in{tof1}**$in{tos1}/$f**$in{tos1} + $ton1*$in{tof1}**$in{tos2}/$f**$in{tos2}) / (1+$f**$in{tos3}/$in{tof2}**$in{tos3})  + $ton2;
print PLOTTM "$f	$tne	$tno\n";
$enoise{$f}=$tne;
$onoise{$f}=$tno;
}

close PLOTTM;


## TEMPERATURE NOISE PLOT

open(GNU, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/temp.gnu") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/temp.gnu: $!\n";
print GNU "set terminal png enhanced transparent fontscale 0.6 size 290,150\n";
print GNU "set output '$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/temp.png'\n";
print GNU "set logscale\n";
print GNU "set grid\n";
print GNU "set ylabel 'Temperature in K/{/Symbol Ö}Hz'\n";
print GNU "set xlabel 'Frequency in Hz'\n";
print GNU "set format y '10^{%L}'\n";
print GNU "set format x '10^{%L}'\n";
print GNU "set xrange [1e-5:$gwavefreqf]\n";
print GNU "set yrange [1e-7:1e1]\n";
print GNU "plot \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tm.txt' u (\$1):(\$2) w l  title 'Electronics' lw 2, \\\n";
print GNU "'$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tm.txt' u (\$1):(\$3) w l  title 'Optical bench' lw 2\n";
print GNU "quit\n";
close (GNU);

$gnuplot = `gnuplot $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/temp.gnu`;




print << "END";


<form method="POST" action="/tools/sensecalc/calculate.html">

			<div class='et-tabs-container et_sliderfx_slide et_sliderauto_false et_sliderauto_speed_5000 et_sliderstart_$in{calculate} et_slidertype_top_tabs' id='et-tabs-container128'>
				<ul class='et-tabs-control'>
			<li><a href='#'>
			Presets
		</a></li> 
		<li><a href='#'>
			Mission
		</a></li>
                <li><a href='#'>
                        Instrument
                </a></li> 
                <li><a href='#'>
                        Clock
                </a></li>
                <li><a href='#'>
                        Other
                </a></li>
		<li><a href='#'>
			Temperature
		</a></li> 
		</ul> <!-- .et-tabs-control --> 
		<div class='et-tabs-content'>
			<div class='et_slidecontent'>
<p class="subline">Classic LISA &ndash; the most sophisticated study</p>
<img align="left" src="/tools/trit.jpg" width="65" height="65" style="margin-right:10px; border: 1px solid #A2A2A2;  padding:2px; margin-top:2px;">Until 2011 this was the ESA/NASA joint mission baseline design for a triangular gravitational wave detector in space, and it is still one of the most promising concepts out there. It features a 5 Million Kilometer spacecraft separation bridged with a 1 watt laser and fairly large 38 cm telescopes on a stable solar orbit 20&deg; behind Earth. (<a href="http://sci.esa.int/lisa/48364-lisa-assessment-study-report-yellow-book/" target="_blank">read more</a>)<br>
<input type="submit" class="load" name="load" value="lisa">
<p class="subline">eLISA (2013) &ndash; the smallest mission possible</p>
<img align="left" src="/tools/twot.jpg"  width="65" height="65" style="margin-right:10px; border: 1px solid #A2A2A2;  padding:2px;  margin-top:2px;">Also known as NGO and quite similar to NASA's SGO-Mid, this V-shaped detector concept was designed as a candidate for ESA's 'Cosmic Vision' programme. Due to the reduced budget it features only 20 cm telescopes with a spacecraft separation of 1 Million Kilometers on a drift-away solar orbit resulting in a shorter mission lifetime. (<a href="http://sci.esa.int/ngo/49839-ngo-assessment-study-report-yellow-book/" target="_blank">read more</a>)<br>
<input type="submit" class="load" name="load" value="elisa">
<p class="subline">OGO &ndash; a future concept</p>
<img align="left" src="/tools/octt.png"  width="65" height="65" style="margin-right:10px;border: 1px solid #A2A2A2; padding:2px;   margin-top:2px;">The Octahedral Gravitational-Wave Observatory is a short-arm detector in quasi-halo orbit featuring 6 spacecraft, 10 watt lasers and 1 m telescopes. With twice as many independent links as spacecraft, TDI can remove not only acceleration noise and spacecraft jitter but alos all clock noise without the need for a clock tone transfer mechanism. (<a href="http://journals.aps.org/prd/abstract/10.1103/PhysRevD.88.104021" target="_blank">read more</a>)<br>
<input type="submit" class="load" name="load" value="ogo">

		</div> 

		<div class='et_slidecontent'>

<div class="help" style="background: #eeeeee; width:auto; width: 560px; margin: -20px -25px 10px -25px;"><div style="opacity: 1; display: block; padding: 5px 15px 5px; z-index: 4; ">
<table border="0" width="100%" cellspacing="0">
<tr>
<td align="left" nowrap>
<p style="font-family: Century Gothic, Arial, sans-serif;font-size: 16px;color: #515050 !important;">Detector name</p>
</td>
<td align="left">
<input
                            type="text" class="name" size="9" name="name"
                            value="$in{name}">
</td>
<td align="left">
(for plots and documents)
</td>
</tr>
</table>
<table width="100%" border="0" cellspacing="0" class="parameters" style="margin-top: 5px;margin-bottom: 6px; margin-left:-5px;">
<tr>
<td align="left">
<div><input id="Field1_0" name="con" type="radio" value="two" $in{two} />
<label for="Field1_0" class="conimg" id="two">Two arm (4 links)</label></div>
</td><td align="center">
<div><input id="Field1_1" name="con" type="radio" value="tri" $in{tri} />
<label for="Field1_1" class="conimg" id="tri">Triangular (6 links)</label></div>
</td><td align="right">
<div><input id="Field1_2" name="con" type="radio" value="oct" $in{oct} />
<label for="Field1_2" class="conimg" id="oct">Octahedral (24 links)</label></div>
</td>
</tr>
</table>

</div></div>

<table class="values" border="0" cellpadding="0" cellspacing="0" style="margin-left:10px">
        <tr>
            <td valign="top" rowspan="3"><img src="/tools/orbit-01.png" style="margin-right:10px"></td>
            <td nowrap rowspan="2"><strong>Orbit</strong></td>
            <td nowrap align="right">Armlength</td>
            <td><input
                            type="text" class="parameter" size="9" name="arm" id="armid"
                            value="$in{arm}"></td>
            <td nowrap>km</td>
        </tr>
        <tr>
            <td nowrap  align="right">Heterodyne frequency</td>
            <td><input
                            type="text" class="parameter"size="9" name="freq" id="freqid"
                            value="$in{freq}"></td>
            <td nowrap>MHz</td>
        </tr>
        <tr>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td valign="top" rowspan="4"><img src="/tools/laser-01.png" style="margin-right:10px"></td>
            <td nowrap rowspan="3"><strong>Laser</strong></td>
            <td nowrap  align="right">Wavelength</td>
            <td><input
                            type="text" class="parameter"size="9" name="wave" id="waveid"
                            value="$in{wave}"></td>
            <td nowrap>nm</td>
        </tr>
        <tr>
            <td nowrap align="right">Power (to telescope)</td>
            <td><input
                            type="text" class="parameter"size="9" name="power" id="powerid"
                            value="$in{power}"></td>
            <td nowrap>W</td>
        </tr>
        <tr>
            <td nowrap  align="right">Relative intensity noise</td>
            <td><input
                            type="text" class="parameter"size="9" name="rin" id="rinid"
                            value="$in{rin}"></td>
            <td nowrap>1/&radic;Hz</td>
        </tr>
        <tr>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td valign="top" rowspan="3"><img src="/tools/telescope.png" style="margin-right:10px"></td>
            <td nowrap rowspan="2"><strong>Telescope</strong></td>
            <td nowrap align="right">Diameter</td>
            <td><input
                            type="text" class="parameter"size="9" name="tel" id="telid"
                            value="$in{tel}"></td>
            <td nowrap>cm</td>
        </tr>
        <tr>
            <td nowrap align="right">Optical efficiency</td>
            <td><input
                            type="text" class="parameter"size="9" name="oe" id="oeid"
                            value="$in{oe}"></td>
            <td nowrap>%</td>
        </tr>
        <tr>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
    </table>

<input type="submit" class="calculate" name="calculate" value="2">

		</div>
                <div class='et_slidecontent'>




   <table border="0" cellpadding="0" cellspacing="0" class="values">
        <tr>
            <td colspan="3" align="left"  style="vertical-align: top;"><p class="subline">Electronics</p>Photodiode properties and preamplifier noise contribute to what generally is declared as shotnoise.<br>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td colspan="3" align="left"  style="vertical-align: top;"><p class="subline">Optics</p>Quality and other properties of the optical bench will affect the thermal stability and beat note intensity.<br>&nbsp;</td>
        </tr>
        <tr>
            <td align="right" nowrap><strong>Photodiode</strong> capacitance</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="cap"
                            value="$in{cap}"></td>
            <td nowrap>pF</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap><strong>Optical pathlength difference</strong></td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td align="right" nowrap>quantum efficiency</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="qe"
                            value="$in{qe}"></td>
            <td nowrap>%</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>on Zerodur and Fused Silica</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="zero"
                            value="$in{zero}"></td>
            <td nowrap>mm</td>
        </tr>
        <tr>
            <td align="right" nowrap>number of segments</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="seg"
                            value="$in{seg}"></td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>within Fused Silica</td>
          <td nowrap><input
                            type="text" class="parametersmall" size="9" name="fs"
                            value="$in{fs}"></td>
            <td nowrap>mm</td>
        </tr>
        <tr>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td align="right" nowrap><strong>Preamplifier</strong> voltage noise</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="vn"
                            value="$in{vn}"></td>
            <td nowrap>nV/&radic;Hz</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap><strong>Heterodyne efficiency</strong></td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="he"
                            value="$in{he}"></td>
            <td nowrap>%</td>
        <tr>
            <td align="right" nowrap>current noise</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="cn"
                            value="$in{cn}"></td>
            <td nowrap>pA/&radic;Hz</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
</tr>
</table>


<input type="submit" class="calculate" name="calculate" value="3">

                </div>

                <div class='et_slidecontent'>
<div align="center"><img src="/tools/clock.png" width="494" height="134"></div>
<br>&nbsp;
   <table border="0" cellpadding="0" cellspacing="0" class="values">
        <tr>
            <td align="right" nowrap><strong>Sideband</strong>
            frequency</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="sbf"
                            value="$in{sbf}"></td>
            <td nowrap>GHz</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap width="100%"><strong>GHz cable</strong>
            length</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="sbl"
                            value="$in{sbl}"></td>
            <td nowrap>m</td>
        </tr>
        <tr>
            <td align="right" nowrap>power</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="sbpower"
                            value="$in{sbpower}"></td>
            <td nowrap>%</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>thermal stability</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="cps"
                            value="$in{cps}"></td>
            <td nowrap>mrad/(K&#183;m&#183;GHz)</td>
        </tr>
        <tr>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td align="right" nowrap><strong>Noise</strong> of EOM</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="eomnoise"
                            value="$in{eomnoise}"></td>
            <td nowrap>mrad/&radic;Hz</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap><strong>Optical fiber</strong>
            length</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="ofl"
                            value="$in{ofl}"></td>
            <td nowrap>m</td>
        </tr>
        <tr>
            <td align="right" nowrap>of fiber amplifier</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="fanoise"
                            value="$in{fanoise}"></td>
            <td nowrap>mrad/&radic;Hz</td>
            <td nowrap>&nbsp;</td>
            <td align="right" nowrap>thermal stability</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="fps"
                            value="$in{fps}"></td>
            <td nowrap>mrad/(K&#183;m&#183;GHz)</td>
        </tr>
    </table>

<input type="submit" class="calculate" name="calculate" value="4">
		</div>

		<div class='et_slidecontent'>

<p class="subline">Some noise sources are not calculated by the Sensitivity Calculator yet</p> We are working on more detailed models for these contributions and will extend the functionality of the Sensitivity Calculator in future versions. For now plase enter absolute values for the noise sources below.<br>&nbsp; 

   <table border="0" cellpadding="0" cellspacing="0" class="values">
        <tr>
            <td align="right" nowrap>Phase measurement noise</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="pm"
                            value="$in{pm}"></td>
            <td nowrap>µrad/&radic;Hz</td>
            <td nowrap>incl pilot tone generation and distribution</td>
        </tr>
        <tr>
            <td align="right" nowrap>Residual clock noise</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="tdiclock"
                            value="$in{tdiclock}"></td>
            <td nowrap>µrad/&radic;Hz</td>
            <td nowrap>after time detay interferometry (TDI)</td
        </tr>
        <tr>
            <td align="right" nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
            <td nowrap>&nbsp;</td>
        </tr>
        <tr>
            <td align="right" nowrap>Acceleration noise</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="acc"
                            value="$in{acc}"></td>
            <td nowrap>m/s² /&radic;Hz</td>
            <td nowrap>&middot; 1/f² / (2&pi;)²</td>
        </tr>
        <tr>
            <td align="right" nowrap>Spacecraft position jitter</td>
            <td nowrap><input
                            type="text" class="parametersmall" size="9" name="scjitter"
                            value="$in{scjitter}"></td>
            <td nowrap>µrad/&radic;Hz</td>
            <td nowrap>&nbsp;</td>
        </tr>
    </table>

<input type="submit" class="calculate" name="calculate" value="5">
		</div>

		<div class='et_slidecontent'>
			
    <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td valign="top"><table border="0"
            cellpadding="0" cellspacing="0" width="100%">
                <tr>
                    <td valign="top" ><p class="subline">Temperature noise</p></td>
                    <td valign="top" nowrap>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
                    <td valign="top" ><p class="subline">Electronics</p></td>
                    <td valign="top" nowrap>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
                    <td valign="top" ><p class="subline">Optical bench</p></td>
                </tr>
                <tr>
		    <td valign="top"><img src="/tools/tnoise-01.png" width="177" height="123"></td>
                    <td valign="top" nowrap>&nbsp;&nbsp;</td>
                    <td valign="top"><table border="0"
                    cellpadding="0" cellspacing="0">
                        <tr>
                            <td>n<sub>1</sub></td>
                            <td><input type="text" size="5"
                            name="ten1" class="temp" value="$in{ten1}"></td>
                            <td width="100%">mK/&radic;Hz</td>
                        </tr>
                        <tr>
                            <td>n<sub>2</sub></td>
                            <td><input type="text" size="5"
                            name="ten2" class="temp" value="$in{ten2}"></td>
                            <td>mK/&radic;Hz</td>
                        </tr>
                        <tr>
                            <td>f<sub>1</sub></td>
                            <td><input type="text" size="5"
                            name="tef1" class="temp" value="$in{tef1}"></td>
                            <td>Hz</td>
                        </tr>
                        <tr>
                            <td>f<sub>2</sub></td>
                            <td><input type="text" size="5"
                            name="tef2" class="temp" value="$in{tef2}"></td>
                            <td>Hz</td>
                        </tr>
                        <tr>
                            <td>s<sub>1</sub></td>
                            <td colspan="2"><table border="0"
                            cellpadding="0" cellspacing="0">
                                <tr>
                                    <td><input type="text"
                                    size="2" name="tes1" class="tempsmall" value="$in{tes1}"></td>
                                    <td>s<sub>2</sub></td>
                                    <td><input type="text"
                                    size="2" name="tes2" class="tempsmall" value="$in{tes2}"></td>
                                    <td>s<sub>3</sub></td>
                                    <td><input type="text"
                                    size="2" name="tes3" class="tempsmall" value="$in{tes3}"></td>
                                </tr>
                            </table>
                            </td>
                        </tr>
                    </table>
                    </td>
                    <td valign="top" nowrap>&nbsp;&nbsp;</td>
                    <td valign="top"><table border="0"
                    cellpadding="0" cellspacing="0">
                        <tr>
                            <td>n<sub>1</sub></td>
                            <td><input type="text" size="5"
                            name="ton1" class="temp" value="$in{ton1}"></td>
                            <td width="100%">mK/&radic;Hz</td>
                        </tr>
                        <tr>
                            <td>n<sub>2</sub></td>
                            <td><input type="text" size="5"
                            name="ton2" class="temp" value="$in{ton2}"></td>
                            <td>mK/&radic;Hz</td>
                        </tr>
                        <tr>
                            <td>f<sub>1</sub></td>
                            <td><input type="text" size="5"
                            name="tof1" class="temp" value="$in{tof1}"></td>
                            <td>Hz</td>
                        </tr>
                        <tr>
                            <td>f<sub>2</sub></td>
                            <td><input type="text" size="5"
                            name="tof2" class="temp" value="$in{tof2}"></td>
                            <td>Hz</td>
                        </tr>
                        <tr>
                            <td>s<sub>1</sub></td>
                            <td colspan="2"><table border="0"
                            cellpadding="0" cellspacing="0">
                                <tr>
                                    <td><input type="text"
                                    size="2" name="tos1" class="tempsmall" value="$in{tos1}"></td>
                                    <td>s<sub>2</sub></td>
                                    <td><input type="text"
                                    size="2" name="tos2" class="tempsmall" value="$in{tos2}"></td>
                                    <td>s<sub>3</sub></td>
                                    <td><input type="text"
                                    size="2" name="tos3" class="tempsmall" value="$in{tos3}"></td>
                                </tr>
                            </table>
                            </td>
                        </tr>
                    </table>
                    </td>
                </tr>
                <tr>
                    <td valign="top" width="100%">&nbsp;<br>Specify realistic temperature noise for two places inside the spacecraft (at electronics and optical bench). Please enter corner frequencies and slopes as well as noise level at f<sub>1</sub> (n<sub>1</sub>) and noise floor (n<sub>2</sub>).<br>Note: <a class="link" id="geo" href="#">Geocentric orbits</a> will highly  increase temperature noise.</td>
                    <td valign="top" nowrap>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
                    <td valign="top" colspan="3">&nbsp;<br><div class="graimg" id="realtemp"><img src="/tools/sensecalc/result/$stamp/temp.png?$time" height="150" width="290"></div></td>
                </tr>
            </table>
            </td>
        </tr>
    </table>
<input type="submit" class="calculate" name="calculate" value="6">
		</div> 
		</div>
			</div> <!-- .et-tabs-container -->
</form>

END

if ($au{var} eq "calculate" && !$in{load}) {


$res{imp} = 1/(2*3.1415*$in{cap}*1e-12*$in{freq}*1e6);
$ires{imp} = int(100*($res{imp})+0.5)/100;
$res{pden} = sqrt(((($in{vn}*1e-9)/($res{imp}))**2)+($in{cn}*1e-12)**2)*1e12;
$ires{pden}  = int(100*($res{pden})+0.5)/100;
$res{gau} = 0.892*$in{tel}/2;
$ires{gau}  = int(100*($res{gau})+0.5)/100;
$res{ray} = 3.1415*($res{gau}*1e-2)**2/($in{wave}*1e-9)*1e-3;
$ires{ray}  = int(100*($res{ray})+0.5)/100;
$res{int} = 2.559*($in{tel}*1e-2/2)**2*$in{power}/(($in{wave}*1e-9)**2*($in{arm}*1e3)**2)*1e9;
$ires{int}  = int(100*($res{int})+0.5)/100;
$res{pow} = 3.1415*($in{tel}*1e-2/2)**2*$res{int}*$in{oe}/100*1e3;
$ires{pow}  = int(100*($res{pow})+0.5)/100;
$res{cable} = $in{sbf}*$in{sbl}*$in{temp}*$in{cps};
$ires{cable}  = int(100*($res{cable})+0.5)/100;
$res{res} = $in{wave}*1e-9*$in{qe}/100/0.000001239;
$ires{res} = int(100*($res{res})+0.5)/100;

#####
##### WERTE in SE Einheiten
#####

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
$hefficiency = $in{he}/100;
$sbpower = $in{sbpower}/100;
$voltagen = $in{vn}*1e-9;
$currentn = $in{cn}*1e-12;
$power = $in{power};
$segments = $in{seg};
$rin = $in{rin};
$phasemeasurement = $in{pm}*1e-6;
$scjitter = $in{scjitter}*1e-6;
$tdiclock = $in{tdiclock}*1e-6;
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
$powersideband = $j1**2;
$printm = int(100*($m)+0.5)/100;

#####
#####
#####


#####
##### POWER RECEIVED - kann ich mit einem Gauss-strahl alle Leistung übertragen? let's find out. Wir suchen das minimale $Wo (waist)
#####


# $Z1 = abstand emitter bis waist (bei gegebenem telescope diameter, was ist der abstand zum waist bei gegebenem waist)
# $WZ2 = Beamdiameter nach abstand waist bis receiver (bei gegebenem waist und abstand zum waist, was ist der waist, der zum geringsten strahldurchmesser führt)

$pi = 3.1415926535897932384626433832795;
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


if ($WZ2 < $telescoped/2) {$gaussianradius = $Wo;
$wherewaist = "center";
$spotsizeatrec = 2* $WZ2;
}
else {$gaussianradius = 0.892*$telescoped/2;
$spotsizeatrec = 2* $gaussianradius * sqrt(1+(($armlength)*$wavelength/$pi/$gaussianradius**2)**2);
$wherewaist = "transmitter";
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


#####
##### Interesting results
#####

$impedance = 1/(2*3.1415*$capacitance*$hfreq);
$printimpedance = int(100*($impedance)+0.5)/100; 
$responsivity = $wavelength*$qefficiency/0.000001239;
$printresponsivity =int(100*($responsivity)+0.5)/100; 
$electronicn = sqrt(((($voltagen)/($impedance))**2)+($currentn)**2);
$printelectronicn = int(100*($electronicn*1e12)+0.5)/100;



$printgaussianradius =  int(100*($gaussianradius*1e2)+0.5)/100;
$rayleigh = 3.1415*($gaussianradius)**2/($wavelength);
$printrayleigh =  int(100*($rayleigh*1e-3)+0.5)/100;

if ($wherewaist eq "center")
{
$received = $power*$oefficiency;
}
else {
$intensity = 2.559*($telescoped/2)**2*$power/(($wavelength)**2*($armlength)**2);
$received = 3.1415*($telescoped/2)**2*$intensity*$oefficiency;

print << "END";


END


	if ($spotsizeatrec < 10*$telescoped)
	{print '<div class="help" style="background: #9a130a;overflow: hidden;width:auto; margin: 10px 0px 15px;"><div style="opacity: 1; display: block; padding: 5px 10px 5px 5px; z-index: 4; "><img src="/tools/clipping.png" width="67" height="67" style="float:left; margin-left:0px;margin-top:0px;padding-right:10px;margin-bottom:5px;"></div><p style="font-family: Century Gothic, Arial, sans-serif;font-size: 16px;color: #FFFFFF;padding-bottom:4px;">PLEASE NOTE</p><p style="color: #FFFFFF;padding-right:10px;padding-bottom:5px;">Beam diameter at the receiver ('.$printspotsizeatrec.' '.$printspotsizeatrecu.') is larger than telescope diameter ('.$in{tel}.' cm) but too small for flat intensity profile. Recieved power subject to beam pointing.</strong></p></div>';}

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
{$printreceived = int(100*($received/$oefficiency * 1e12)+0.5)/100; $printreceivedu = "pW";}
elsif ($received*1e9 < 1000)
{$printreceived = int(100*($received/$oefficiency * 1e9)+0.5)/100; $printreceivedu = "nW";}
elsif ($received*1e6 < 1000)
{$printreceived = int(100*($received/$oefficiency * 1e6)+0.5)/100; $printreceivedu = "µW";}
elsif ($received*1e3 < 1000)
{$printreceived = int(100*($received/$oefficiency * 1e3)+0.5)/100; $printreceivedu = "mW";}
else
{$printreceived = int(100*($received/$oefficiency)+0.5)/100; $printreceivedu = "W";}


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


$optimalpower = $electronicn/($responsivity*sqrt($segments)*$rin);
$printoptimalpower = int(100*($optimalpower * 1e6)+0.5)/100;
$lopowercarrier = $powercarrier * $optimalpower;
$printlopowercarrier = int(100*($lopowercarrier * 1e6)+0.5)/100;
$lopowersb = $powersideband * $optimalpower;
$printlopowersb = int(100*($lopowersb * 1e6)+0.5)/100;

$snr = $powercarrier * sqrt($responsivity*$hefficiency*$received/(1.6e-19+$electronicn*sqrt($segments)*$rin)); ##nicht electronicn^2? oder noch mehr zum quadrat? und plus statt mal?
$printsnr =  int(100*(20*log($snr)/log(10))+0.5)/100; #ist das nicht snrdb statt C/N0 in dbhz?
#$printsnr = $snr;

if ($powersideband) {
$snrsb = $powersideband * sqrt($responsivity*$hefficiency*$received/(1.6e-19+$electronicn*sqrt($segments)*$rin));
$printsnrsb =  int(100*(20*log($snrsb)/log(10))+0.5)/100; }
else {$snrsb = "0"; $printsnrsb = "0";}

#####
#####
#####


#Temperaturverlauf ist 1/f**2. Angegeben wird der Punkt bei 10 mHz (0.01 Hz). Um diesen auf 1 zu setzen, gilt: 0.01**2/f**2. Um diesen nun auf einen beliebigen wert zu setzen, gilt: WERT*0.01**2/f**2.

#Umrechnungsfaktor von rad in pm
$radinpm = $wavelength/(2*3.1415);


open PLOTPM, "> $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/pm.txt" or die $!;
print PLOTPM "#frequency [Hz]	summe	1/SNR Carrier	other	acceleration noise	sideband cable	optical bench	1/SNR Sideband	SC Jitter\n";

#Phase noise in science signal
$snrpn = 1/$snr*$radinpm;

#Phase noise in science signal SIDEBANDS
if ($snrsb && $sbfreq) {$snrsbpn = 1/$snrsb*$radinpm/sqrt(2)*$hfreq/$sbfreq;}
else {$snrsbpn = "0";}
if ($links eq "12") {$snrsbpn = "0";}

#Phase measurement noise and co (sc jitter, residual clock noise)
$pmpm = sqrt(($phasemeasurement*$radinpm)**2+($tdiclock*$radinpm)**2);

$scjitterpm = $scjitter*$radinpm;

# untere grenze für displacement plot
$plotlowpm = log(sqrt($pmpm**2+$snrpn**2))/log(10);
$plotlowpm = int($plotlowpm-.5)-2;
$plotlowpm = 10**$plotlowpm;

for ($e = -500; $e <= 100*$gwavefreq; $e=$e+2)
{
$f = 10**($e/100);

##Thermal noise (Optical Bench)
#Phasenoise due to Zerodur
$zerodur = $onoise{$f}*($zero-$fs)*$ctez/$wavelength*2*3.1415 * $radinpm;
#Phasenoise due to Fused silica
$fusedsilica = $onoise{$f}*$fs*($ctef*(1-$rif)+$dndtf)/$wavelength*2*3.1415 * $radinpm;
$sumtn = $zerodur+$fusedsilica;

#GHz sideband cable noise

if ($sbfreq) {
$cablepm = $cstability * $clength * $sbfreq * $enoise{$f} * $hfreq / $sbfreq * $radinpm;
$fiberpm = $fstability * $flength * $sbfreq * $enoise{$f} * $hfreq / $sbfreq * $radinpm;
$eompm = $eomnoise * $hfreq / $sbfreq * $radinpm;
$fapm = $fanoise * $hfreq / $sbfreq * $radinpm;
} else {$cablepm = "0"; $fiberpm = "0"; $eompm = "0"; $fapm = "0";}

$sbsignalline = sqrt(($cablepm+$fiberpm)**2 + $fapm**2 + $eompm**2 );
if ($links eq "12") {$sbsignalline = "0";}

$accnoisepm = $acc /$f**2 / (2*3.1415)**2;

$summe = sqrt(($snrpn+$snrsbpn)**2 + $pmpm**2  + $sbsignalline**2 + $sumtn**2);

print PLOTPM "$f $summe $snrpn $pmpm $accnoisepm $sbsignalline $sumtn $snrsbpn $scjitterpm\n";
}

close PLOTPM;


#PRINT RESULTS

open(DET, ">$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/details.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/details.txt: $!\n";

print DET "detector name;$in{name};;[name];\r\n";
print DET "armlength;$in{arm};km;[armlength];\r\n";
print DET "number of arms;$links;;[links];\r\n";

print DET "maximum heterodyne frequency;$in{freq};MHz;[fhet];\r\n";
print DET "laser wavelength;$in{wave};nm;[laser];\r\n";
print DET "relative intensity noise;$in{rin};/sqrt(Hz);[rin];\r\n";

print DET "optical power to telescope;$in{power};W;[power];\r\n";
print DET "telescope diameter;$in{tel};cm;[diameter];\r\n";
print DET "optical efficiency;$in{oe};%;[oeff];\r\n";

print DET "waist located at;$wherewaist;;[waistlocation];\r\n";
print DET "Gaussian radius (at waist);$printgaussianradius;cm;[waistradius];\r\n";
print DET "Rayleigh length;$printrayleigh;km;[rayleigh];\r\n";
print DET "beam diameter at receiver;$printspotsizeatrec;$printspotsizeatrecu;[beamdiameter];\r\n";
print DET "intensity at receiver;$printintensity;$printintensityu/m^2;[intensity];\r\n";
print DET "received power;$printreceived;$printreceivedu;[received];\r\n";
print DET "detected power per segment;$printreceivedps;$printreceivedpsu;[detected];\r\n";

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


$cid =~ s/\://g;

print << "END";

<p>

		<div class='tabs-left' id='tabs-left436'>
				<ul class='et-tabs-control'>
			<li><a href='#'>
			Displacement
		</a></li> 
		<li><a href='#'>
			Single link strain
		</a></li> 
		<li><a href='#'>
			Full detector
		</a></li> 
		<li><a href='#'>
			Details
		</a></li>
		<li><a href='#'>
			Download
		</a></li>
		</ul> <!-- .et-tabs-control --> 

		<div class='et-tabs-content'>

                <div class='et_slidecontent'><div style="display:block;height:197px;width:300px;background-image: url(/tools/calculating.png);
background-repeat:no-repeat;"><div style="position: absolute; left: 60px; top: 117px; "><img src="/tools/wait2.gif" width="38" height="38"></div><div style="position: absolute; left: 8px; top: 8px; "><a class="group1" href="/tools/sensecalc/result/$stamp/pm.big.png?$time" title="Overview of noise sources (expressed as corresponding displacement noise)"><img src="/tools/sensecalc/pm.$cid.$links.$plotlowpm.$armlength.png?$time" width="351" height="197" border="0"></a></div></div></div>

		<div class='et_slidecontent'><div style="display:block;height:197px;width:300px;background-image: url(/tools/calculating.png);
background-repeat:no-repeat;"><div style="position: absolute; left: 60px; top: 117px; "><img src="/tools/wait2.gif" width="38" height="38"></div><div style="position: absolute; left: 8px; top: 8px; "><a class="group1" href="/tools/sensecalc/result/$stamp/single.big.png?$time" title="Single link strain sensitivity (sky avarage) with Classic LISA sensitivity for comparison"><img src="/tools/sensecalc/single.$cid.$links.$in{name}.$armlength.png?$time" width="351" height="197" border="0"></a></div></div></div> 

		<div class='et_slidecontent'><div style="display:block;height:197px;width:300px;background-image: url(/tools/calculating.png);
background-repeat:no-repeat;"><div style="position: absolute; left: 60px; top: 117px; "><img src="/tools/wait2.gif" width="38" height="38"></div><div style="position: absolute; left: 8px; top: 8px; "><a class="group1" href="/tools/sensecalc/result/$stamp/full.big.png?$time"  title="Full detector network strain sensitivity for $in{name} detector with astronomical sources"><img src="/tools/sensecalc/full.$cid.$links.$in{name}.$armlength.png?$time" width="351" height="197" border="0"></a></div></div></div>

		<div class='et_slidecontent'>
Gaussian radius at $wherewaist: $printgaussianradius cm<br>
Beam diameter at receiver: $printspotsizeatrec $printspotsizeatrecu<br>
Photodiode impedance: $printimpedance Ohm<br>
Photodiode responsitivity: $printresponsivity A/W<br>
Electronic noise: $printelectronicn pA/Hz<br>
Rayleigh range: $printrayleigh km<br>
Intensity at receiver: $printintensity $printintensityu/m**2<br>
Received power: $printreceived $printreceivedu<br>
Detected power per segment: $printreceivedps $printreceivedpsu<br>
Signal to noise ratio (Carrier): $printsnr dBHz<br>
Signal to noise ratio (Sideband): $printsnrsb dBHz<br>
Modulation index (EOM): $printm<br>
Optimal power LO (per segment): $printoptimalpower &mu;W<br>
Optical power (LO carrier): $printlopowercarrier &mu;W<br>
Optical power (single LO sideband): $printlopowersb &mu;W<br>

	</div>

		<div class='et_slidecontent'><p class="subline" style="margin-top:0px;">Download results</p><p>We provide documents explaining the detector sensitivity as well as  plots in a PostScript format and raw-data in CSV text files with corresponding Gnuplot scripts.<p>

<a style="float:none;" target="_blank" href="/tools/sensecalc/overview.$cid.$links.$in{name}.$armlength.pdf?$time" class='icon-button download-icon'><span class='et-icon'><span style='background: url(/tools/pdf.png) no-repeat 12px 6px; padding-left:65px;'><strong>Overview Document</strong> (< 0.4 MB)</span></span></a>

<a style="float:none;" target="_blank" href="/tools/sensecalc/complete.$cid.$links.$in{name}.$armlength.pdf?$time" class='icon-button download-icon'><span class='et-icon'><span style='background: url(/tools/pdf.png) no-repeat 12px 6px; padding-left:65px;'><strong>Detailed Report</strong> (< 1.0 MB)</span></span></a>

<a style="float:none;" href="/tools/sensecalc/overview.$cid.$links.$in{name}.$armlength.zip?$time" class='icon-button download-icon'><span class='et-icon'><span style='background: url(/tools/zip.png) no-repeat 12px 6px; padding-left:65px;'><strong>Plots and Raw-Data</strong> (< 0.1 MB)</span></span></a>
</div>

		</div>
			</div> <!-- .tabs-left -->

<p><center style="font-size:11px;color:#bbb;">Please cite as:<br>
Barke S, Tröbs M, Wang Y, Esteban JJ, Heinzel G, Danzmann K. AEI Sensitivity Calculator.<br>In SpaceGravity.org. Retrieved on $date, from http://spacegravity.org/tools/sc/.<br>&nbsp;</center></p>

			<script type='text/javascript'>
					 jQuery('#tabs-left436 .et-tabs-content').et_shortcodes_switcher({linksNav: '#tabs-left436 .et-tabs-control li a', findParent: true, fx: 'fade', auto: false, autoSpeed: '5000'});
			</script></p>


END

# startSlide: '1' macht beim draufklicken auf den ersten slide was komisches
# jQuery('#tabs-left436 .et-tabs-content').et_shortcodes_switcher({linksNav: '#tabs-left436 .et-tabs-control li a', findParent: true, fx: 'fade', auto: false, autoSpeed: '5000', startSlide: '1'});


}

print << "END";
</div>

<div id="subscribers">
<div id="listwrap">


<div id="legal"><a href="https://www.elisascience.org/whitepaper/legal-page">legal notice</a></div>
<div id="social"><a href="https://www.elisascience.org/articles/elisa-mission/elisa-l2-white-paper" style="margin:10px;"><img border="0" src="home.png"></a><a href="http://facebook.com/LISAcommunity" target="_blank" style="margin:10px;"><img border="0" src="facebook.png"></a> <a target="_blank" style="margin:10px;" href="http://twitter.com/LISAcommunity"><img border="0" src="twitter.png"></a> <a target="_blank" style="margin:10px;" href="https://plus.google.com/102103184552119879686" rel="publisher"><img border="0" src="google.png"></a> <a target="_blank" style="margin:10px;" href="http://www.youtube.com/user/LISAcommunity"><img border="0" src="youtube.png"></a></div>






</div>

</div>
</div>
</body>
</html>

END


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

