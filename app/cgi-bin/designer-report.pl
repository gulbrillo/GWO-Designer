#!/usr/bin/perl -w


use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;
use JSON::Parse 'json_file_to_perl';

use utf8;

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


if (-e "$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/details.json") {

$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex`;

#parse all parameters from json file to variables ($details->{'beamIntensity'}->{'value'})
$file = "$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/details.json";
$details = json_file_to_perl ($file);

$file = "$ENV{APP_ROOT}/htdocs/designer/templates/sessions/$details->{'session'}->{'id'}/parameters.json";
$session = json_file_to_perl ($file);

#open template
open TEX, "<:utf8", "$ENV{APP_ROOT}/designer/latexelements/report.tex" or die $!;
@tex = <TEX>;
close TEX;


$lighttravel = $details->{'armLength'}->{'value'} / 299792458 * 1000;

#optionalText
if ($details->{'withPAAM'}->{'value'} eq "no") {

if ($details->{'photodiodeSegments'}->{'value'} eq "1") {
$segment = "2\\pi";
$area = "the area of one receiving single-element";
} elsif ($details->{'photodiodeSegments'}->{'value'} eq "2") {
$segment = "\\pi";
$area = "a single element of one receiving bi-cell ";
} else {
$segment = "\\pi/2";
$area = "a single element of one receiving quadrant ";
}

$withPAAM = "";
$withoutPAAMper = "for perfect beam alignment";
$withoutPAAMmax = "maximum possible";
$withoutPAAMmaxtex = "^\\text{max}";
$withoutPAAM = "";
$withPAAMnoise = "";
$PAAMparameters = "Point Ahead Angle Mechanism (PAAM) & ~ & ~ $details->{'withPAAM'}->{'value'}\\\\
Maximum point-ahead angle & \$ \\alpha_\\text{pa}^\\text{max} =  \$ & ~ \$$details->{'beamTilt'}->{'value'}\$\\,\$$details->{'beamTilt'}->{'texunit2'}\$ \\\\
Optimal tilt angle & \$\\alpha_\\text{pa} = \$ & ~ \$\\num{$details->{'optimalTilt'}->{'value'}}\$\\,\$$details->{'optimalTilt'}->{'texunit'}\$ \\\\
Heterodyne efficiency (photodiode segment) & \$ \\eta_\\text{het} =  \$ & ~ \$ \\num{$details->{'heterodyneEfficiency'}->{'value'}} \$  \\% \\\\";
$noPaamText = "\\\\

We now have to consider that the received beam originated from a direction where the remote spacecraft was \$L_\\text{arm}/c = \\num{$lighttravel} \$ seconds ago. The above calculated maximum heterodyne efficiency consequenty occurs only if the receiving telescope is pointed into this direction. However, to reach the maximum in received power, the receiving spacecraft needs to be situated in the center of the received beam. Hence the outgoing beam should be trasmitted in the directoin where the distant spacecraft will be in \\num{$lighttravel} seconds. We assume the maximum point-ahead angle between the origin of the received light and the transmitted beam to be \$\\alpha_\\text{pa}^\\text{max} =  $details->{'beamTilt'}->{'value'}\\,\$$details->{'beamTilt'}->{'texunit2'}\$.\\footnote{A study by Airbus \\cite{fitzsimons2014elisa} found that the point-ahead angle is oscillating with an amplitude of roughly 1.15\\,\\textmu rad per 1 million kilometer arm length.} Since there is no Point-Ahead Angle Mechanism (PAAM) applied in the current study, we have to find the optimal tilt angle \$\\alpha_\\text{pa}\$ (illustrated in Figure~\\ref{fig:paam}) so that the combination from loss in received power and loss in heterodyne efficiency has a minimum impact on the overall sensitivity of the observatory \\cite{fitzsimons2014elisa}.\\\\

\\begin{figure}[htb]\\centering
\\includegraphics[width=\\linewidth]{$ENV{APP_ROOT}/designer/latexelements/paam}
\\caption{The tilt angle \$\\alpha_\\text{pa}\$ is measured between the origin of the received beam and the direction of the transmitted beam. The maximum point ahead angle \$\\alpha_\\text{pa}^\\text{max}\$ accounts for the position the remote spacecraft is in when it receives the transmitted beam.}
\\label{fig:paam}
\\end{figure}

To calculate the received power as a function of the tilt angle, we nummerically integrate the Fresnel diffraction integral of the transmitted beam over the apperture of the transmitting telescope aperture (\$r^{\\prime}=0\\dots d_\\text{tel}/2\$, \$\\theta^{\\prime} = 0 \\dots 2\\pi\$) to find the electric field diffraction pattern
\\begin{equation}
E_\\text{FF}=~\\frac{ik e^{ikz}}{2\\pi z} \\iint_\\text{aperture} E_\\text{NF} \\: e^{\\frac{ik}{2z}\\left[\\left(x-x^{\\prime}\\right)^2+\\left(y-y^{\\prime}\\right)^2\\right]}  dr^{\\prime}d\\theta^{\\prime}
\\label{eq:fresnel}
\\end{equation}
for the transmitted Gaussian beam \$E_\\text{NF} = E_\\text{NF} \\propto e^{-\\left(x^2+y^2\\right)/\\omega_\\text{LO}^2}\$ (normalized amplitude, truncated at the telescope aperture) moving along \$z\$ direction. Here \$k=2\\pi/\\lambda_\\text{laser}\$ is the wavenumber and  coorinates at \$z=0\$ can be expressed as \$x^{\\prime} = r^{\\prime}\\sin(\\theta^{\\prime})\$ and \$y^{\\prime} = r^{\\prime}\\cos(\\theta^{\\prime})\$. We can now calculate the received electrical field at distance \$z=L_\\text{arm}\\times \\cos(\\alpha_\\text{pa}^\\text{max} - \\alpha_\\text{pa})\$ and offset from the center of the beam \$x=L_\\text{arm}\\times \\sin(\\alpha_\\text{pa}^\\text{max} - \\alpha_\\text{pa})\$, \$y=0\$ for all tilt angles  \$\\alpha_\\text{pa} = 0 \\dots \\alpha_\\text{pa}^\\text{max}\$. 
The received power is expressed by 
\\begin{equation}
P_\\text{rec}\\left(\\alpha_\\text{pa}\\right) = P_\\text{tel} \\times \\pi\\:\\left(\\frac{d_\\text{tel}}{2}\\right)^2 \\eta_\\text{opt} \\: \\left|E_\\text{FF}\\right|^2~.
\\label{eq:optpower}
\\end{equation}
Naturally, the maximum occurs when the spacecraft points away from the origin of the received beam and the distant spacecraft sits at the center of the transmitted beam (\$\\alpha_\\text{pa} = \\alpha_\\text{pa}^\\text{max}\$).\\\\

The maximum heterodyne efficiency is achieved whenever the receiving telescope points towards the origin of the received beam (\$\\alpha_\\text{pa} = 0\$) and decreases with larger tilt angle, independent of the actual pointing direction of the recieved beam. For this to be true, we assume that the wavefronts of the far field beam are approximately radial in shape around the transmitter. 

We can now evaluate the heterodyne efficiency between the received an the local beam numerically 
\\begin{equation}
\\eta_\\text{het}\\left(\\alpha_\\text{pa}\\right) = \\frac{\\left|\\iint_\\text{area}E_\\text{NF}\\,E_\\text{FF}\\left(\\alpha_\\text{pa}\\right)\\,dA\\right|^2}{\\iint_\\text{area}\\left|E_\\text{NF}\\right|^2 dA \\times \\iint_\\text{area}\\left|E_\\text{FF}\\left(\\alpha_\\text{pa}\\right)\\right|^2 dA}
\\label{eq:heffnum}
\\end{equation}
where the area represents $area  photodiode (\$r^{\\prime}=0\\dots d_\\text{pd}/2\$, \$\\theta^{\\prime} = 0 \\dots $segment\$).\\footnote{The phase information of each segment has to be evaluated individually as the heterodyne efficiency may be reduced substantially when the signal from different segments is combined or read out simultaniously over a larger area.}
\$E_\\text{NF} \\propto e^{-r^{\\prime2}/\\omega_\\text{LO}^2\$ and \$E_\\text{FF} \\left(\\alpha_\\text{pa}\\right) \\propto e^{-ikr \\times \\sin\\left(\\theta^{\\prime}\\right)\\times\\tan\\left(\\alpha_\\text{pa} M\\right)}\$ represent the electrical fields of the two beams. \$E_\\text{NF}\$ is the Gaussian local oscillator, \$E_\\text{FF}\$ is the received flat top beam which is tilted with respect to the other field by \$\\alpha_\\text{pa} \\times M\$. \$M = d_\\text{tel}/d_\\text{pd}\$ is the same magnification factor between the telescope and photodiode diameter as before.


\\begin{figure}[htb]\\centering
\\includegraphics[width=\\linewidth]{$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/plots/heff-vs-power}
\\caption{Heterodyne efficiency and received power as a function of the tilt angle. The combined impact on the observatory sensitivity is shown as shaded area (sensitivity in percent with respect to maximum values for efficiency and power). Maximum sensitivity is given for \$\\alpha_\\text{pa} = \$ \\num{$details->{'optimalTilt'}->{'value'}}\\,\\textmu rad.}
\\label{fig:heffvspower}
\\end{figure}

Figure~\\ref{fig:heffvspower} shows the Heterodyne efficiency and received power as a function of the tilt angle \$\\alpha_\\text{pa}\$. As shown in Section~\\ref{sec:shotnoise}, both values influence the noise of the observatory as the square root of their inverse. In order to reduce its noise, it is crucial to maximize \$\\sqrt{\\eta_\\text{het}\\left(\\alpha_\\text{pa}\\right)\\times P_\\text{rec}\\left(\\alpha_\\text{pa}\\right)}\$ which is depicted as shaded area, normalized to \$\\sqrt{\\eta_\\text{het}^\\text{max} \\times P_\\text{rec}^\\text{max}\$. The maximum is found at \\num{$details->{'optimalLoss'}->{'value'}}\\,\\% for \$\\alpha_\\text{pa} = \$ \\num{$details->{'optimalTilt'}->{'value'}}\\,\\textmu rad where the received power is \$P_\\text{rec} = \\num{$details->{'receivedPower'}->{'value'}}\$\\,$details->{'receivedPower'}->{'unit'} with a heterodyne efficiency of \$\\eta_\\text{het} = \\num{$details->{'heterodyneEfficiency'}->{'value'}}\$\\,\\%. 

" 
} else {
$withPAAM = "While the telescope always points towards the received beam, in the direction where the remote spacecraft was \$L_\\text{arm}/c = \\num{$lighttravel} \$ seconds ago, the transmitted goes into the direction where the distant spacecraft will be in \\num{$lighttravel} seconds. This ensures for a maximum possible heterodyne efficiency while at the same time the power received by the remote spacecraft is maximized since the spacecraft are always situated in the center of the received beams. A Point-Ahead Angle Mechanism (PAAM) is used to account for this point-ahead angle between the origin of the received light and the transmitted beam. We assume that the PAAM can fully compensate a maximum angle of \$\\alpha_\\text{pa}^\\text{max} =  $details->{'beamTilt'}->{'value'}\\,\$$details->{'beamTilt'}->{'texunit2'}\$.\\footnote{A study by Airbus found that the point-ahead angle is oscillating with an amplitude of roughly 1.15\\,\\textmu rad per 1 million kilometer arm length.}  The piston noise of the PAAM is given by \$ \\widetilde{x}_\\text{opn}^\\text{paam} =  $details->{'paamNoise'}->{'value'}\$\\,\$$details->{'paamNoise'}->{'latexunit'}\$.\\\\";
$withoutPAAMper = "";
$withoutPAAM = "";
$withoutPAAMmax = "";
$withoutPAAMmaxtex = "";
$withPAAMnoise = "Additionally, the PAAM will direclty influences the optical path-length stability.";
$noPaamText = "";
$PAAMparameters = "Point Ahead Angle Mechanism (PAAM) & ~ & ~ $details->{'withPAAM'}->{'value'}\\\\
Maximum point-ahead angle & \$ \\alpha_\\text{pa}^\\text{max} =  \$ & ~ \$$details->{'beamTilt'}->{'value'}\$\\,\$$details->{'beamTilt'}->{'texunit2'}\$ \\\\
PAAM piston noise & \$ \\widetilde{x}_\\text{opn}^\\text{paam} =  \$ & ~ \$$details->{'paamNoise'}->{'value'}\$\\,\$$details->{'paamNoise'}->{'latexunit'}\$ \\\\
Heterodyne efficiency (photodiode segment) & \$ \\eta_\\text{het} =  \$ & ~ \$ \\num{$details->{'heterodyneMax'}->{'value'}} \$  \\% \\\\";
}


#replace variables
foreach(@tex) {
	$_ =~ s|<approot>|$ENV{APP_ROOT}|g;
	$_ =~ s/<uuid>/$au{uuid}/g;
	$_ =~ s/<session>/$details->{'session'}->{'id'}/g;
	$_ =~ s/<author>/$session->{'feed'}->{'parameters'}->{'author'}->{'value'}/g;
	$_ =~ s/<affiliation>/$session->{'feed'}->{'parameters'}->{'affiliation'}->{'value'}/g;
	$_ =~ s/<paamText>/$withPAAM/g;
	$_ =~ s/<noPaamText>/$noPaamText/g;
        $_ =~ s/<precMax>/$withoutPAAMmaxtex/g;
	$_ =~ s/<precMaxPos>/$withoutPAAMmax/g;
	$_ =~ s/<heffMaxPos>/$withoutPAAMper/g;
	$_ =~ s/<paamTextNoise>/$withPAAMnoise/g;
	$_ =~ s/<PAAMparameters>/$PAAMparameters/g;
	$_ =~ s/<optimalTilt>/$details->{'optimalTilt'}->{'value'}/g;
	$_ =~ s/<optimalTiltU>/$details->{'optimalTilt'}->{'texunit'}/g;
	$_ =~ s/<detectorName>/$details->{'detectorName'}->{'name'}/g;
	$_ =~ s/<numberOfLinks>/$details->{'numberOfLinks'}->{'value'}/g;
	$_ =~ s/<formation>/$details->{'numberOfLinks'}->{'textElement'}/g;
	$_ =~ s/<armLength>/$details->{'armLength'}->{'value'}/g;
	$_ =~ s/<armLengthU>/$details->{'armLength'}->{'unit'}/g;
	$_ =~ s/<heterodyneFrequency>/$details->{'heterodyneFrequency'}->{'value'}/g;
	$_ =~ s/<heterodyneFrequencyU>/$details->{'heterodyneFrequency'}->{'unit'}/g;
	$_ =~ s/<laserFrequencyNoise>/$details->{'laserFrequencyNoise'}->{'value'}/g;
	$_ =~ s/<laserFrequencyNoiseU>/$details->{'laserFrequencyNoise'}->{'latexunit'}/g;
	$_ =~ s/<telescopePathlengthNoise>/$details->{'telescopePathlengthNoise'}->{'value'}/g;
	$_ =~ s/<telescopePathlengthNoiseU>/$details->{'telescopePathlengthNoise'}->{'latexunit'}/g;
	$_ =~ s/<telescopeDiameter>/$details->{'telescopeDiameter'}->{'value'}/g;
        $_ =~ s/<telescopeDiameterU>/$details->{'telescopeDiameter'}->{'unit'}/g;
        $_ =~ s/<waistCenter>/$details->{'waistCenter'}->{'value'}/g;
        $_ =~ s/<waistCenterU>/$details->{'waistCenter'}->{'unit'}/g;
        $_ =~ s/<waistTransmitter>/$details->{'waistTransmitter'}->{'value'}/g;
        $_ =~ s/<waistTransmitterU>/$details->{'waistTransmitter'}->{'unit'}/g;
        $_ =~ s/<waistLO>/$details->{'waistLO'}->{'value'}/g;
	$_ =~ s/<magnificationFactor>/$details->{'magnificationFactor'}->{'value'}/g;
        $_ =~ s/<waistLOU>/$details->{'waistLO'}->{'unit'}/g;
	$_ =~ s/<beamIntensity>/$details->{'beamIntensity'}->{'value'}/g;
	$_ =~ s/<beamIntensityU>/$details->{'beamIntensity'}->{'latexunit'}/g;
        $_ =~ s/<beamDiameterCenterWaist>/$details->{'beamDiameterCenterWaist'}->{'value'}/g;
	$_ =~ s/<beamDiameterCenterWaistU>/$details->{'beamDiameterCenterWaist'}->{'unit'}/g;
        $_ =~ s/<beamDiameterTransmitterWaist>/$details->{'beamDiameterTransmitterWaist'}->{'value'}/g;
        $_ =~ s/<beamDiameterTransmitterWaistU>/$details->{'beamDiameterTransmitterWaist'}->{'unit'}/g;
	$_ =~ s/<receivedPower>/$details->{'receivedPower'}->{'value'}/g;
	$_ =~ s/<receivedPowerU>/$details->{'receivedPower'}->{'unit'}/g;
        $_ =~ s/<laserWavelength>/$details->{'laserWavelength'}->{'value'}/g;
        $_ =~ s/<laserWavelengthU>/$details->{'laserWavelength'}->{'unit'}/g;
        $_ =~ s/<laserPower>/$details->{'laserPower'}->{'value'}/g;
        $_ =~ s/<laserPowerU>/$details->{'laserPower'}->{'unit'}/g;
	$_ =~ s/<laserPowerUf>/$details->{'laserPower'}->{'texunit'}/g;
        $_ =~ s/<laserRIN>/$details->{'laserRIN'}->{'value'}/g;
        $_ =~ s/<laserRINU>/$details->{'laserRIN'}->{'texunit'}/g;
        $_ =~ s/<quantumEfficiency>/$details->{'quantumEfficiency'}->{'value'}/g;
        $_ =~ s/<photodiodeResponsivity>/$details->{'photodiodeResponsivity'}->{'value'}/g;
        $_ =~ s/<photodiodeResponsivityU>/$details->{'photodiodeResponsivity'}->{'texunit'}/g;
        $_ =~ s/<photodiodeSegments>/$details->{'photodiodeSegments'}->{'value'}/g;
        $_ =~ s/<photodiodeSegmentsU>/$details->{'photodiodeSegments'}->{'unit'}/g;
	$_ =~ s/<photodiodeSegmentsText>/$details->{'photodiodeSegments'}->{'textElement'}/g;
        $_ =~ s/<voltageNoise>/$details->{'voltageNoise'}->{'value'}/g;
        $_ =~ s/<voltageNoiseU>/$details->{'voltageNoise'}->{'texunit'}/g;
        $_ =~ s/<currentNoise>/$details->{'currentNoise'}->{'value'}/g;
        $_ =~ s/<currentNoiseU>/$details->{'currentNoise'}->{'texunit'}/g;
        $_ =~ s/<photodiodeImpedance>/$details->{'photodiodeImpedance'}->{'value'}/g;
        $_ =~ s/<photodiodeImpedanceU>/$details->{'photodiodeImpedance'}->{'texunit'}/g;
        $_ =~ s/<photodiodeCapacitance>/$details->{'photodiodeCapacitance'}->{'value'}/g;
        $_ =~ s/<photodiodeCapacitanceU>/$details->{'photodiodeCapacitance'}->{'unit'}/g;
        $_ =~ s/<opticalEfficiency>/$details->{'opticalEfficiency'}->{'value'}/g;
        $_ =~ s/<heterodyneEfficiency>/$details->{'heterodyneEfficiency'}->{'value'}/g;
	$_ =~ s/<rawHetEff>/$details->{'rawHetEff'}->{'value'}/g;
	$_ =~ s/<localOscillatorPower>/$details->{'localOscillatorPower'}->{'value'}/g;
	$_ =~ s/<localOscillatorPowerU>/$details->{'localOscillatorPower'}->{'unit'}/g;
	$_ =~ s/<localOscillatorPowerUf>/$details->{'localOscillatorPower'}->{'unitfull'}/g;
        $_ =~ s/<totalReadoutNoise>/$details->{'totalReadoutNoise'}->{'value'}/g;
        $_ =~ s/<totalReadoutNoiseU>/$details->{'totalReadoutNoise'}->{'texunit'}/g;
	$_ =~ s/<waistPosition>/$details->{'waistPosition'}->{'position'}/g;
	$_ =~ s/<waistPositionText>/$details->{'waistPosition'}->{'textElement'}/g;
        $_ =~ s/<OPDob>/$details->{'OPDob'}->{'value'}/g;
        $_ =~ s/<OPDobU>/$details->{'OPDob'}->{'unit'}/g;
        $_ =~ s/<OPDfs>/$details->{'OPDfs'}->{'value'}/g;
        $_ =~ s/<OPDfsU>/$details->{'OPDfs'}->{'unit'}/g;
	$_ =~ s/<temperatureElectronicsN1>/$details->{'temperatureElectronics'}->{'n1'}/g;
	$_ =~ s/<temperatureElectronicsN2>/$details->{'temperatureElectronics'}->{'n2'}/g;
	$_ =~ s/<temperatureElectronicsN3>/$details->{'temperatureElectronics'}->{'n3'}/g;
	$_ =~ s/<temperatureElectronicsU>/$details->{'temperatureElectronics'}->{'texunit'}/g;
	$_ =~ s/<temperatureElectronicsF1>/$details->{'temperatureElectronics'}->{'f1'}/g;
	$_ =~ s/<temperatureElectronicsF2>/$details->{'temperatureElectronics'}->{'f2'}/g;
	$_ =~ s/<temperatureElectronicsFU>/$details->{'temperatureElectronics'}->{'funit'}/g;
	$_ =~ s/<temperatureElectronicsS1>/$details->{'temperatureElectronics'}->{'s1'}/g;
	$_ =~ s/<temperatureElectronicsS3>/$details->{'temperatureElectronics'}->{'s3'}/g;
        $_ =~ s/<temperatureOpticsN1>/$details->{'temperatureOptics'}->{'n1'}/g;
        $_ =~ s/<temperatureOpticsN2>/$details->{'temperatureOptics'}->{'n2'}/g;
        $_ =~ s/<temperatureOpticsN3>/$details->{'temperatureOptics'}->{'n3'}/g;
        $_ =~ s/<temperatureOpticsU>/$details->{'temperatureOptics'}->{'texunit'}/g;
        $_ =~ s/<temperatureOpticsF1>/$details->{'temperatureOptics'}->{'f1'}/g;
        $_ =~ s/<temperatureOpticsF2>/$details->{'temperatureOptics'}->{'f2'}/g;
        $_ =~ s/<temperatureOpticsFU>/$details->{'temperatureOptics'}->{'funit'}/g;
        $_ =~ s/<temperatureOpticsS1>/$details->{'temperatureOptics'}->{'s1'}/g;
        $_ =~ s/<temperatureOpticsS3>/$details->{'temperatureOptics'}->{'s3'}/g;
	$_ =~ s/<carrierPower>/$details->{'carrierPower'}->{'value'}/g;
        $_ =~ s/<sidebandPower>/$details->{'sidebandPower'}->{'value'}/g;
        $_ =~ s/<sidebandPowerM>/$details->{'sidebandPower'}->{'m'}/g;
	$_ =~ s/<sidebandPowerMU>/$details->{'sidebandPower'}->{'unitm'}/g;
        $_ =~ s/<levelFactorCarrier>/$details->{'levelFactors'}->{'carrier'}/g;
        $_ =~ s/<levelFactorSideband>/$details->{'levelFactors'}->{'sideband'}/g;
	$_ =~ s/<timingRequirement>/$details->{'timingRequirement'}->{'value'}/g;
        $_ =~ s/<timingRequirementU>/$details->{'timingRequirement'}->{'texunit'}/g;
	$_ =~ s/<carrierReadOut>/$details->{'carrierReadOut'}->{'value'}/g;
	$_ =~ s/<carrierReadOutU>/$details->{'carrierReadOut'}->{'texunit'}/g;
        $_ =~ s/<carrierReadOutU2>/$details->{'carrierReadOut'}->{'texunit2'}/g;
        $_ =~ s/<carrierReadOutPn>/$details->{'carrierReadOutPn'}->{'value'}/g;
        $_ =~ s/<carrierReadOutPnU>/$details->{'carrierReadOutPn'}->{'texunit'}/g;
        $_ =~ s/<carrierShotNoise>/$details->{'carrierShotNoise'}->{'value'}/g;
        $_ =~ s/<carrierShotNoiseU>/$details->{'carrierShotNoise'}->{'texunit'}/g;
        $_ =~ s/<carrierShotNoiseU2>/$details->{'carrierShotNoise'}->{'texunit2'}/g;
        $_ =~ s/<carrierRIN>/$details->{'carrierRIN'}->{'value'}/g;
        $_ =~ s/<carrierRINU>/$details->{'carrierRIN'}->{'texunit'}/g;
        $_ =~ s/<carrierRINU2>/$details->{'carrierRIN'}->{'texunit2'}/g;
        $_ =~ s/<carrierElectronicNoise>/$details->{'carrierElectronicNoise'}->{'value'}/g;
        $_ =~ s/<carrierElectronicNoiseU>/$details->{'carrierElectronicNoise'}->{'texunit'}/g;
        $_ =~ s/<carrierElectronicNoiseU2>/$details->{'carrierElectronicNoise'}->{'texunit2'}/g;
        $_ =~ s/<electricTimingNoise>/$details->{'electricTimingNoise'}->{'value'}/g;
        $_ =~ s/<electricTimingNoiseU>/$details->{'electricTimingNoise'}->{'texunit'}/g;
        $_ =~ s/<electricTimingNoiseU2>/$details->{'electricTimingNoise'}->{'texunit2'}/g;
        $_ =~ s/<electricPTNoise>/$details->{'electricPTNoise'}->{'value'}/g;
        $_ =~ s/<electricPTNoiseU>/$details->{'electricPTNoise'}->{'texunit'}/g;
        $_ =~ s/<electricPTNoiseU2>/$details->{'electricPTNoise'}->{'texunit2'}/g;
        $_ =~ s/<sidebandReadOut>/$details->{'sidebandReadOut'}->{'value'}/g;
        $_ =~ s/<sidebandReadOutU>/$details->{'sidebandReadOut'}->{'texunit'}/g;
        $_ =~ s/<sidebandReadOutU2>/$details->{'sidebandReadOut'}->{'texunit2'}/g;
        $_ =~ s/<modulationFrequency>/$details->{'modulationFrequency'}->{'value'}/g;
        $_ =~ s/<modulationFrequencyU>/$details->{'modulationFrequency'}->{'unit'}/g;
        $_ =~ s/<faPhaseNoise>/$details->{'faPhaseNoise'}->{'value'}/g;
        $_ =~ s/<faPhaseNoiseU>/$details->{'faPhaseNoise'}->{'texunit'}/g;
        $_ =~ s/<faPhaseNoiseU2>/$details->{'faPhaseNoise'}->{'texunit2'}/g;
        $_ =~ s/<eomPhaseNoise>/$details->{'eomPhaseNoise'}->{'value'}/g;
        $_ =~ s/<eomPhaseNoiseU>/$details->{'eomPhaseNoise'}->{'texunit'}/g;
        $_ =~ s/<eomPhaseNoiseU2>/$details->{'eomPhaseNoise'}->{'texunit2'}/g;
        $_ =~ s/<faNoise>/$details->{'faNoise'}->{'value'}/g;
        $_ =~ s/<faNoiseU>/$details->{'faNoise'}->{'texunit'}/g;
        $_ =~ s/<faNoiseU2>/$details->{'faNoise'}->{'texunit2'}/g;
        $_ =~ s/<eomNoise>/$details->{'eomNoise'}->{'value'}/g;
        $_ =~ s/<eomNoiseU>/$details->{'eomNoise'}->{'texunit'}/g;
        $_ =~ s/<eomNoiseU2>/$details->{'eomNoise'}->{'texunit2'}/g;
        $_ =~ s/<fiberNoise>/$details->{'fiberNoise'}->{'value'}/g;
        $_ =~ s/<fiberNoiseU>/$details->{'fiberNoise'}->{'texunit'}/g;
        $_ =~ s/<fiberNoiseU2>/$details->{'fiberNoise'}->{'texunit2'}/g;
        $_ =~ s/<cableNoise>/$details->{'cableNoise'}->{'value'}/g;
        $_ =~ s/<cableNoiseU>/$details->{'cableNoise'}->{'texunit'}/g;
        $_ =~ s/<cableNoiseU2>/$details->{'cableNoise'}->{'texunit2'}/g;
        $_ =~ s/<thermalStabilityFibers>/$details->{'thermalStabilityFibers'}->{'value'}/g;
        $_ =~ s/<thermalStabilityFibersU>/$details->{'thermalStabilityFibers'}->{'texunit'}/g;
        $_ =~ s/<thermalStabilityFibersU2>/$details->{'thermalStabilityFibers'}->{'texunit2'}/g;
        $_ =~ s/<thermalStabilityCables>/$details->{'thermalStabilityCables'}->{'value'}/g;
        $_ =~ s/<thermalStabilityCablesU>/$details->{'thermalStabilityCables'}->{'texunit'}/g;
        $_ =~ s/<thermalStabilityCablesU2>/$details->{'thermalStabilityCables'}->{'texunit2'}/g;
        $_ =~ s/<cableLength>/$details->{'cableLength'}->{'value'}/g;
        $_ =~ s/<cableLengthU>/$details->{'cableLength'}->{'unit'}/g;
        $_ =~ s/<fiberLength>/$details->{'fiberLength'}->{'value'}/g;
        $_ =~ s/<fiberLengthU>/$details->{'fiberLength'}->{'unit'}/g;
	$_ =~ s/<sidebandPowerBessel>/$details->{'sidebandPowerBessel'}->{'value'}/g;
	$_ =~ s/<carrierPowerBessel>/$details->{'carrierPowerBessel'}->{'value'}/g;
        $_ =~ s/<accelerationNoise>/$details->{'accelerationNoise'}->{'value'}/g;
        $_ =~ s/<accelerationNoiseU>/$details->{'accelerationNoise'}->{'texunit'}/g;
        $_ =~ s/<accelerationNoiseU2>/$details->{'accelerationNoise'}->{'texunit2'}/g;
        $_ =~ s/<freqNoiseNoRanging>/$details->{'freqNoiseNoRanging'}->{'value'}/g;
        $_ =~ s/<freqNoiseNoRangingU>/$details->{'freqNoiseNoRanging'}->{'texunit'}/g;
        $_ =~ s/<freqNoiseNoRangingU2>/$details->{'freqNoiseNoRanging'}->{'texunit2'}/g;
        $_ =~ s/<freqNoiseRanging>/$details->{'freqNoiseRanging'}->{'value'}/g;
        $_ =~ s/<freqNoiseRangingU>/$details->{'freqNoiseRanging'}->{'texunit'}/g;
        $_ =~ s/<freqNoiseRangingU2>/$details->{'freqNoiseRanging'}->{'texunit2'}/g;
        $_ =~ s/<metrologySystem>/$details->{'metrologySystem'}->{'value'}/g;
        $_ =~ s/<metrologySystemU>/$details->{'metrologySystem'}->{'texunit'}/g;
        $_ =~ s/<metrologySystemU2>/$details->{'metrologySystem'}->{'texunit2'}/g;
        $_ =~ s/<metrologySystemDisp>/$details->{'metrologySystemDisp'}->{'value'}/g;
        $_ =~ s/<metrologySystemDispU>/$details->{'metrologySystemDisp'}->{'texunit'}/g;
        $_ =~ s/<metrologySystemDispU2>/$details->{'metrologySystemDisp'}->{'texunit2'}/g;
        $_ =~ s/<rangingAccuracy>/$details->{'rangingAccuracy'}->{'value'}/g;
        $_ =~ s/<rangingAccuracyU>/$details->{'rangingAccuracy'}->{'unit'}/g;
        $_ =~ s/<metrologySystemTotal>/$details->{'metrologySystemTotal'}->{'value'}/g;
        $_ =~ s/<metrologySystemTotalU>/$details->{'metrologySystemTotal'}->{'texunit'}/g;
        $_ =~ s/<metrologySystemTotalU2>/$details->{'metrologySystemTotal'}->{'texunit2'}/g;
	$_ =~ s/<withPAAM>/$details->{'withPAAM'}->{'value'}/g;
        $_ =~ s/<paamNoise>/$details->{'paamNoise'}->{'value'}/g;
        $_ =~ s/<paamNoiseU>/$details->{'paamNoise'}->{'latexunit'}/g;
        $_ =~ s/<beamTilt>/$details->{'beamTilt'}->{'value'}/g;
        $_ =~ s/<beamTiltU>/$details->{'beamTilt'}->{'texunit'}/g;
	$_ =~ s/<beamTiltU2>/$details->{'beamTilt'}->{'texunit2'}/g;
        $_ =~ s/<pdDiameter>/$details->{'pdDiameter'}->{'value'}/g;
        $_ =~ s/<pdDiameterU>/$details->{'pdDiameter'}->{'unit'}/g;
        $_ =~ s/<receivedMax>/$details->{'receivedMax'}->{'value'}/g;
        $_ =~ s/<receivedMaxU>/$details->{'receivedMax'}->{'unit'}/g;
        $_ =~ s/<heterodyneQuality>/$details->{'heterodyneQuality'}->{'value'}/g;
        $_ =~ s/<heterodyneQualityU>/$details->{'heterodyneQuality'}->{'unit'}/g;
        $_ =~ s/<heterodyneMax>/$details->{'heterodyneMax'}->{'value'}/g;
        $_ =~ s/<heterodyneMaxU>/$details->{'heterodyneMax'}->{'unit'}/g;


   push(@report,$_);
}

$return = `rm $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.pdf`;
$return = `rm $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/spacegravity.org_$au{uuid}.pdf`;

#write tex file
open REPORT, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.tex" or die $!;
print REPORT @report;
close(REPORT);

#compile the tex file with pdf latex (nonstop-mode) and bibtex
$pdflatex = `export HOME=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ && /usr/bin/pdflatex -interaction=nonstopmode -output-directory=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.tex`;
$bibtex = `export HOME=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ && cd $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ && /usr/bin/bibtex report.aux`;
$pdflatex = `export HOME=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ && /usr/bin/pdflatex -interaction=nonstopmode -output-directory=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.tex`;
$pdflatex = `export HOME=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ && /usr/bin/pdflatex -interaction=nonstopmode -output-directory=$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/ $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.tex`;

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.pdf") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.pdf: $!\n";;
flock(LOCK, 2);
close LOCK;

# Stream the PDF with a friendly download name: <recoverycode>_report_<shortuuid>.pdf
$sid = $details->{'session'}->{'id'};
$fname = $sid . "_report_" . uc(substr($au{uuid},0,8)) . ".pdf";
print "Content-Type: application/pdf\n";
print "Content-Disposition: inline; filename=\"$fname\"\n\n";
binmode STDOUT;
open(PDF, "<", "$ENV{APP_ROOT}/htdocs/designer/results/$au{uuid}/latex/report.pdf") or exit(0);
binmode PDF;
local $/;
print <PDF>;
close PDF;

exit(0);

#print "Content-type: text/html\n\n";
#print <<END;

#<!doctype html>
#<html>
#<head>
#  <title>GWO Designer</title>
#  <meta charset="utf-8">
#</head>

#<body>
#<div style="white-space:pre-line;">
#UUID: $au{uuid}
#Beam intensity: $details->{'beamIntensity'}->{'value'} $details->{'beamIntensity'}->{'unit'}
#</div>
#</body>

#</html>
#END
#exit(0);

}
else {

#TODO: make this pretty
print "Content-type: text/html\n\n";
print "$au{uuid}.pdf not found";
exit(0);

}



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

}

