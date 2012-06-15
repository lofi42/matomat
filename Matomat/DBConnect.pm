#!/usr/bin/perl

package Matomat::DBConnect;
use Exporter 'import';
@ISA         = qw(Exporter);
@EXPORT = qw($dbh);

use DBI;
use Matomat::Config;

print "DB: $dbfile\n";
sleep(2);

my $dbargs = {AutoCommit => 1, PrintError => 1, foreign_keys => 1};
our $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "", $dbargs);
$dbh->do("PRAGMA foreign_keys = ON");

if ($dbh->err()) { die "[NO_MATE] DB Error $DBI::errstr\n"; }
$dbh->commit();
1;
