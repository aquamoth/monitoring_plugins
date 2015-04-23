#!/usr/bin/perl
#
# $Revision$ 0.1 $ 2015-04-19	Mattias Åslund (mattias@trustfall.se)
#
# Simple plugin to get number of active auctions and vehicles at autopatrul
#

# use strict;

use Getopt::Long;
use LWP::Simple;
use DateTime;
use URI::Escape;
use Capture::Tiny 'capture';


use lib "/opt/plugins";
use utils qw(%ERRORS &print_revision &support &usage);

use vars qw($opt_host, $opt_port, $opt_code);

my $PROGNAME = 'check_autopatrul';

sub print_help ();
sub print_usage ();
sub help ();
sub version ();


Getopt::Long::Configure('bundling', 'no_ignore_case');
GetOptions(
	"V|version"           => \&version,
	"h|help"              => \&help,
	"H|host:s"            => \$opt_host,
	"p|port:i"            => \$opt_port,
	"P|code:s"             => \$opt_code,
);


# configuration section

usage("Hostname required.\n")
  unless ($opt_host);

$opt_port = 80
  unless (defined($opt_port));

usage("Code required.\n")
  unless ($opt_code);


my $today = DateTime->now(time_zone => 'Asia/Tokyo')->strftime('%Y-%m-%d');
my $sql = "select count(distinct auction),count(*) from main where auction_date>='$today'";
my $url = "/xml/xml?code=".uri_escape($opt_code)."&sql=".uri_escape($sql);
my $regex = "<TAG0>(\\d+).*<TAG1>(\\d+)";
my $message = "Indexing \$1 auctions with \$2 vehicles.|Auctions=\$1 Vehicles=\$2";

my ($stdout, $stderr, $return) = capture {
	system( '/opt/plugins/custom/check_http_content.pl', (
		'-Hautopatrul.ru', 
		"-u$url", 
		"-r$regex",
		"-m$message",
		) 
	);
};
print $stdout;
exit $return;





sub print_usage () {
	print "Usage: $PROGNAME -H <host name> [-p <port>] -P <autopatrul code>\n";
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: 0.1 $ ');
	print "Copyright (c) 2015 Mattias Åslund, Trustfall AB

Perl Check Autopatrul plugin for Naemon.

Returns OK if the web server returns a 200, otherwise returns ERROR.

The plugin asks Autopatrul how many future auctions and vehicles they index
and transcodes the response in a format suitable for monitoring.

OBS! This script relies on that \"check_http_content.pl\" FROM THE SAME AUTHOR
	is available in the same directory!


";
	print_usage();
	print '
-H, --host
   The host to request the web page from, ex: www.cosmo-jpn.jp
-p, --port
   The destination tcp port to query. Default: 80
-P, --code
   An Autopatrul password code that grants query access to their http interface.
-h, --help
   This stuff.

';
	support();
}

sub version () {
	print_revision($PROGNAME,'$Revision: 0.1 $ ');
	exit $ERRORS{'OK'};
}

sub help () {
	print_help();
	exit $ERRORS{'OK'};
}

