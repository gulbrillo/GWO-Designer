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



if (-e "$ENV{APP_ROOT}/htdocs/designer/templates/sessions/$au{session}/parameters.json") {

$return = `cp $ENV{APP_ROOT}/htdocs/designer/templates/sessions/$au{session}/parameters.json $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/data/`;

$file = "$ENV{APP_ROOT}/htdocs/designer/templates/sessions/$au{session}/parameters.json";
$session = json_file_to_perl ($file);


$return = `rm $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/report.zip`;
$return = `rm $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/spacegravity.org_$au{session}.zip`;

$gnuplot = `cd $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/data/ && gnuplot overview.gnu`;

$imagemagick = `convert $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/data/overview.png $ENV{APP_ROOT}/designer/latexelements/designer_watermark.png -gravity SouthWest  -composite -format png $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/data/overview.png`;







$zipfile = `cd $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/data/ && zip -r $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/report.zip *`;


open (LOCK, "+<$ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/report.zip") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/report.zip: $!\n";;
flock(LOCK, 2);
close LOCK;

$return = `mv $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/report.zip $ENV{APP_ROOT}/htdocs/designer/sessions/$au{session}/spacegravity.org_$au{session}.zip`;

$URL = "http://spacegravity.org/designer/sessions/$au{session}/spacegravity.org_$au{session}.zip";
print "Location: $URL\n\n";



exit(0);


}


else {

#TODO: make this pretty
print "Content-type: text/html\n\n";
print "$au{session}.zip not found";
exit(0);

}








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
