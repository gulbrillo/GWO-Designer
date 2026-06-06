#!/usr/bin/perl -w
#
# designer-summary.pl - generates the short "Overview Document" PDF for a session.
# Companion to designer-report.pl (the long detailed report). Reached via
#   /designer/download.overview/<session>.pdf  ->  ...?uuid=<session>
# Contains: title + intro + paper reference, recovery QR/link, the four main result
# plots (overview, displacement, single-link, observatory) with captions, and the full
# list of input parameters. Template: designer/latexelements/summary.tex
#
# Keyed by SESSION id (like the data export), not the per-run uuid. We pick the first
# calculation run found under the session for the per-run plots.

use CGI::Carp qw(fatalsToBrowser);
use JSON::Parse 'json_file_to_perl';
use utf8;

&DATA;

my $root    = $ENV{APP_ROOT};
my $session = $au{uuid};                      # the download route passes the session id here
my $sdir    = "$root/htdocs/designer/sessions/$session";
my $params  = "$root/htdocs/designer/templates/sessions/$session/parameters.json";

unless ($session =~ /^[0-9A-Fa-f-]{4,}$/ && -d $sdir && -e $params) {
    print "Content-type: text/html\n\n<h3>Overview not available</h3><p>No saved data found for this session.</p>";
    exit 0;
}

# --- find the first calculation run under the session (for per-run plots) ---
my $run;
if (opendir(my $dh, "$sdir/data")) {
    my @runs = grep { /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-/ && -d "$sdir/data/$_" } readdir($dh);
    closedir $dh;
    @runs = sort @runs;
    $run = $runs[0];
}
my $rdir = defined($run) ? "$root/htdocs/designer/results/$run" : "";

# --- load data ---
my $p = json_file_to_perl($params);
my $P = $p->{feed}->{parameters} || {};
my $details = (defined($run) && -e "$rdir/details.json") ? json_file_to_perl("$rdir/details.json") : {};

# --- working dir + convert the result SVGs to PDF for inclusion ---
my $work = "$sdir/overview";
`mkdir -p $work`;
sub svg2pdf {
    my ($src, $dst) = @_;
    return "" unless -e $src;
    `rsvg-convert -f pdf -o $work/$dst $src`;
    return -e "$work/$dst" ? "$work/$dst" : "";
}
my $overviewPdf     = svg2pdf("$sdir/af.svg",  "overview.pdf");
my $displacementPdf = svg2pdf("$rdir/pm.svg",  "displacement.pdf");
my $singlePdf       = svg2pdf("$rdir/sa.svg",  "single.pdf");
my $fullPdf         = svg2pdf("$rdir/fl.svg",  "full.pdf");
# QR: a PDF usually already exists; otherwise convert the SVG
my $qrPdf = (-e "$sdir/qr.pdf") ? "$sdir/qr.pdf" : svg2pdf("$sdir/qr.svg", "qr.pdf");

# --- LaTeX sanitiser: escape specials, map common Unicode, strip the rest ---
sub texesc {
    my $s = shift; $s = "" unless defined $s;
    $s =~ s/\\/\\textbackslash{}/g;
    $s =~ s/([&%#_\$\{\}])/\\$1/g;
    $s =~ s/\^/\\textasciicircum{}/g;
    $s =~ s/~/\\textasciitilde{}/g;
    $s =~ s/\x{221A}/\$\\surd\$/g;          # sqrt
    $s =~ s/\x{00D7}/\$\\times\$/g;         # times
    $s =~ s/[\x{00B7}\x{22C5}]/\$\\cdot\$/g;# middle dot
    $s =~ s/\x{00B2}/\\textsuperscript{2}/g;
    $s =~ s/\x{00B3}/\\textsuperscript{3}/g;
    $s =~ s/\x{00B9}/\\textsuperscript{1}/g;
    $s =~ s/[\x{00B5}\x{03BC}]/\$\\upmu\$/g;# micro / mu
    $s =~ s/\x{03C0}/\$\\uppi\$/g;          # pi
    $s =~ s/\x{00B0}/\\textdegree{}/g;
    $s =~ s/\x{03A9}/\$\\Upomega\$/g;       # ohm
    $s =~ s/\x{2013}/--/g; $s =~ s/\x{2014}/---/g;
    $s =~ s/[^\x00-\x7F]//g;                # drop any remaining non-ASCII
    return $s;
}

# --- build the parameter table rows from parameters.json ---
my %skip = map { $_ => 1 } qw(author affiliation session qr run name);
my @rows;
for my $k (sort { lc($a) cmp lc($b) } keys %$P) {
    next if $skip{$k};
    my $h = $P->{$k};
    my ($name, $val, $unit);
    if (ref($h) eq 'HASH' && exists $h->{description}) {
        $name = $h->{description}->{name};
        $val  = $h->{description}->{selected};
        $unit = "";
    } else {
        $name = $h->{name};
        $val  = $h->{value};
        $val  = join(", ", @$val) if ref($val) eq 'ARRAY';
        $unit = $h->{unit};
    }
    next unless defined $name && $name ne "";
    $unit = "" if !defined($unit) || $unit eq "undefined";
    push @rows, texesc($name) . " & " . texesc($val) . " & " . texesc($unit) . " \\\\";
}
my $paramtable = join("\n", @rows);

# --- title / abstract values ---
my $detector = texesc($details->{detectorName}->{name} // $P->{name}->{value} // "your");
my $author   = texesc($P->{author}->{value});       $author = "Anonymous" if $author eq "";
my $affil    = texesc($P->{affiliation}->{value});  $affil  = "---" if $affil eq "";
my $links    = texesc($details->{numberOfLinks}->{value} // "?");
my $armv     = texesc($details->{armLength}->{value} // ($P->{arm}->{value} // "?"));
my $armu     = texesc($details->{armLength}->{unit}  // ($P->{arm}->{unit}  // "km"));

# --- fill the template ---
open my $tfh, "<:utf8", "$root/designer/latexelements/summary.tex" or die "template: $!";
my @tex = <$tfh>; close $tfh;
for (@tex) {
    s|<approot>|$root|g;
    s|<session>|$session|g;
    s|<detectorName>|$detector|g;
    s|<author>|$author|g;
    s|<affiliation>|$affil|g;
    s|<numberOfLinks>|$links|g;
    s|<armLength>|$armv|g;
    s|<armLengthUnit>|$armu|g;
    s|<overviewplot>|$overviewPdf|g;
    s|<displacementplot>|$displacementPdf|g;
    s|<singleplot>|$singlePdf|g;
    s|<fullplot>|$fullPdf|g;
    s|<qrplot>|$qrPdf|g;
    s|<parametertable>|$paramtable|g;
}
open my $ofh, ">:utf8", "$work/summary.tex" or die "write tex: $!";
print $ofh @tex; close $ofh;

# --- compile (twice, for the longtable column widths / page refs) ---
my $pdflatex = "export HOME=$work/ && /usr/bin/pdflatex -interaction=nonstopmode -output-directory=$work/ $work/summary.tex";
`$pdflatex`;
`$pdflatex`;

my $out = "$work/spacegravity.org_overview_$session.pdf";
if (-e "$work/summary.pdf") {
    `mv $work/summary.pdf $out`;
    print "Location: /designer/sessions/$session/overview/spacegravity.org_overview_$session.pdf\n\n";
    exit 0;
}

print "Content-type: text/html\n\n<h3>Overview generation failed</h3><p>The document could not be compiled. See the detailed report instead.</p>";
exit 0;

#----------------------------------------------------------------------------------------
sub DATA {
    my $aufruf = "$ENV{'QUERY_STRING'}";
    $aufruf =~ tr/+/ /;
    $aufruf =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    for my $kv (split(/&/, $aufruf)) {
        my ($key, $value) = split(/=/, $kv);
        next unless defined $key;
        $value = "" unless defined $value;
        $value =~ tr/+/ /;
        $value =~ s/[^a-zA-Z0-9\-\.]//g;
        $au{$key} = $value;
    }
}
