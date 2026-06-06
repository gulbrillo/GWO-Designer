#!/usr/bin/perl -w

use CGI::Carp qw(fatalsToBrowser);
use feature 'switch';
use Math::Cephes qw(:bessels);
use PDL;
use Math::Complex;
use List::Util qw( min max );

use utf8;
use CGI;

# READ INPUT FORM and DECODE from UTF8
$query = CGI ->new;
$in = {};  
foreach my $name ( $query ->param ) {
  my @val = $query ->param( $name );
  foreach ( @val ) {
    utf8::decode($_);
		$_ =~ s/[^\pL\pN\p{Zs}\pP\p{Sm}\|]//g;
  }
  utf8::decode($name);
  if ( scalar @val == 1 ) {   
    $in{$name} = $val[0];
  } else {                      
    $in{$name} = \@val;  # save value as an array ref
  }
}

# #ENCODE PARAMETERS THAT WILL BE WRITTEN TO OTHER DOCUMENTS
# if (!$in{name}) {$in{namei} = "Your observatory";}
# utf8::encode($in{name});
# utf8::encode($in{plottitle});

$in{session} =~ s/[^A-Za-z0-9-.]//g;
$stamp = $in{session};

print "Content-type: application/json\n\n";


$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/templates/sessions/$stamp/`;
$return = `mkdir $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/`;
$return = `perl $ENV{APP_ROOT}/cgi-bin/qrcode.pl -m 0 http://spacegravity.org/designer/#rc=$stamp > $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/qr.svg`;

$svgtopdf = `rsvg-convert -f pdf -o $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/qr.pdf $ENV{APP_ROOT}/htdocs/designer/sessions/$stamp/qr.svg`;



open(RECOVERY, ">:utf8", "$ENV{APP_ROOT}/htdocs/designer/templates/sessions/$stamp/parameters.json") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/templates/sessions/$stamp/parameters.json: $!\n";

print RECOVERY "{\"version\":\"1.0\",\"encoding\":\"UTF-8\",\"feed\":{\"parameters\":{\n";
	while (($key, $value) = each(%in)){
		if ($key ne "session" && $key ne "qr")
			{print RECOVERY "\"$key\": {$value},\n";}
		}
	print RECOVERY "\"source\": {\"url\":\"http://spacegravity.org/designer\",\"session\":\"$stamp\"}\n";
print RECOVERY "}}}\n";

close (RECOVERY);

open(RECOVERY, "<:utf8", "$ENV{APP_ROOT}/htdocs/designer/templates/sessions/$stamp/parameters.json") or print "Can't open or create file $ENV{APP_ROOT}/htdocs/designer/templates/sessions/$stamp/parameters.json: $!\n";
@return = <RECOVERY>;
close (RECOVERY);

print @return;

exit(0);


