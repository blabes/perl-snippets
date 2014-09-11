#!perl -w
#
# Given a division number and date (yyyymmdd format) return the count
# for that combination in both the InfoPro table and the DWPSA table

use strict;
use DBI;

my $dbh = DBI->connect("DBI:ODBC:Infopro_Prod") or die("DBI Connect Error - $DBI::errstr\n");

# Do a test count
my $count = $dbh->selectrow_array(qq{
  SELECT COUNT(*) FROM allied.bidbfa.bipcu
});
warn "count=$count\n";
