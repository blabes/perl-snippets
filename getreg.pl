#!perl -w
#
# Given a region return its InfoPro division

use strict;
use DBI;

my $usage = "Usage: $0 <div>\n";
my $div = shift or die $usage;

# left zero-fill $div to three wide
$div = sprintf("%0.3d", $div);
warn "Division=$div\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwpsa"
) or die("DBI Connect Error - $DBI::errstr\n");

# Find the region letter for the given division
my $reg = $dbh->selectrow_array(qq{
  SELECT icreg FROM stg_ifp_bipic WHERE current_ind='Y' AND iccomp=?
}, undef, $div);
warn "InfoPro Region=$reg\n";
