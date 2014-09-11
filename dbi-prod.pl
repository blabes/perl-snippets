#!perl -w
#
# Given a division number and date (yyyymmdd format) return the count
# for that combination in both the InfoPro table and the DWPSA table

use strict;
use DBI;

my $usage = "Usage: $0 <div> <yyyymmdd>\n";
my $div = shift or die $usage;
my $date = shift or die $usage;;

# left zero-fill $div to three wide
$div = sprintf("%0.3d", $div);
warn "div=$div\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwpsa"
) or die("DBI Connect Error - $DBI::errstr\n");

# Find the region letter for the given division
my $reg = $dbh->selectrow_array(qq{
  SELECT icreg FROM stg_ifp_bipic WHERE current_ind='Y' AND iccomp=?
}, undef, $div);
warn "reg=$reg\n";

# get the InfoPro count for the div/date
my $ifpCount = $dbh->selectrow_array(qq{
  SELECT COUNT(*) FROM infopro.allied.bidbf${reg}${div}.bipac WHERE acudat=?
}, undef, $date);
warn "ifpCount=$ifpCount\n";

# get the DWPSA count for the div/date
my $psaCount = $dbh->selectrow_array(qq{
  SELECT COUNT(*) FROM stg_ifp_bipac WHERE current_ind='Y' AND accomp=? AND acudat=?
}, undef, $div, $date);
warn "psaCount=$psaCount\n";
