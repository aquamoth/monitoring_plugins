#!/usr/bin/perl
#
# $Revision: 0.3 $ 2015-04-19	Mattias Åslund (mattias@trustfall.se)
#
# Simple plugin to get the content of an http get request
#

# use strict;

use Getopt::Long;
use LWP::Simple;

use lib "/opt/plugins";
use utils qw(%ERRORS &print_revision &support &usage);

use vars qw($opt_host, $opt_port, $opt_url, $opt_file, $opt_regex, $opt_message);

my $PROGNAME = 'check_http_content';


sub print_help ();
sub print_usage ();
sub help ();
sub version ();


Getopt::Long::Configure('bundling', 'no_ignore_case');
GetOptions(
	"V|version"           => \&version,
	"h|help"              => \&help,
	"d|debug"             => \$debug,
	"H|host:s"            => \$opt_host,
	"p|port:i"            => \$opt_port,
	"u|url:s"             => \$opt_url,
	"f|file:s"            => \$opt_file,
	"r|regex:s"           => \$opt_regex,
	"m|message:s"         => \$opt_message,
);


# configuration section

usage("Hostname required.\n")
  unless ($opt_host or $opt_file);

usage("Url required.\n")
  unless ($opt_url or $opt_file) ;

$opt_port = 80
  unless (defined($opt_port));

print "DEBUG: Host    = $opt_host\n" unless (!defined($debug));
print "DEBUG: Port    = $opt_port\n" unless (!defined($debug));
print "DEBUG: Url     = $opt_url\n" unless (!defined($debug));
print "DEBUG: File    = $opt_file\n" unless (!defined($debug));
print "DEBUG: Regex   = $opt_regex\n" unless (!defined($debug));
print "DEBUG: Message = $opt_message\n" unless (!defined($debug));


my $html;

if(defined($opt_file)) {
	local $/ = undef;
	open FILE, "autopatrol.xml" or die "Couldnt open file: $!";
	binmode FILE;
	$html = <FILE>;
	close FILE;
}
else {
	my $request = "http://$opt_host:$opt_port".$opt_url;
	print "DEBUG: REQUEST = $request\n" unless (!defined($debug));

	$html = get($request);
	print "DEBUG: RESPONSE = $html\n" unless (!defined($debug));
}

exit $ERRORS{'CRITICAL'}
  unless (defined($html));

if(defined($opt_regex)) {
	$html =~ /$opt_regex/s;
	my ($p1,$p2,$p3,$p4,$p5,$p6) = ($1,$2,$3,$4,$5,$6);

	my $format = $opt_message;
	$format = "$1 $2 $3 $4 $5 $6" unless(defined($format));
	$format =~ s/\$1/$p1/g;
	$format =~ s/\$2/$p2/g;
	$format =~ s/\$3/$p3/g;
	$format =~ s/\$4/$p4/g;
	$format =~ s/\$5/$p5/g;
	$format =~ s/\$6/$p6/g;

	print $format."\n";
}
else
{
	print $html."\n";
}

exit $ERRORS{'OK'};



sub print_usage () {
	print "Usage: $PROGNAME -H <host name> [-p <port>] -u <url> [-e <regex> -m <output format>]\n";
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: 0.3 $ ');
	print "Copyright (c) 2015 Mattias Åslund, Trustfall AB

Perl Check http content plugin for Naemon.

Returns OK if the web server returns a 200, otherwise returns ERROR.

The plugin simply makes a query and returns the full response.
By including a regex and output format, the response can be
transcoded into a suitable string before outputting it.
";
	print_usage();
	print '
-H, --host
   The host to request the web page from, ex: www.cosmo-jpn.jp
-p, --port
   The destination tcp port to query. Default: 80
-u, --url
   The page to request from the host, ex: /Auction/Statistics
-r, --regex
   An optional regex to transcode the response from the server,
      ex: "\<TAG0\>(\d+).*\<TAG1\>(\d+)"
-m, --message
   The message to print, including variables from the regex,
      ex: "Indexing $1 vehicles in $2 auctions."
-h, --help
   This stuff.

';
	support();
}

sub version () {
	print_revision($PROGNAME,'$Revision: 0.3 $ ');
	exit $ERRORS{'OK'};
}

sub help () {
	print_help();
	exit $ERRORS{'OK'};
}

