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

$return = `rm $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.raw.zip`;

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

open (LOCK, "+<$ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/tf.txt: $!\n";;
flock(LOCK, 2);
close LOCK;

$zipfile = `zip -j $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/report.raw.zip $ENV{APP_ROOT}/htdocs/tools/sensecalc/result/$stamp/*`;

$URL = "http://spacegravity.org/tools/sensecalc/result/$stamp/report.raw.zip?$time";
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

