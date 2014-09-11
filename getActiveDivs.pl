#!perl -w
#
# Return a CSV list of active regions and regions/divisions

use strict;
use DBI;

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx12;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

# Query InfoPro to find all active regions and divisions
my $sth = $dbh->prepare(qq{
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFA.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFE.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFF.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFM.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFN.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFO.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFR.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFS.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFW.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
UNION ALL
  SELECT ICREG, LTRIM(ICCOMP) ICCOMP
    FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBFV.BIPCO
   WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'
});

$sth->execute;

my $icreg;
my $iccomp;
my %seenRegion;
my %seenDiv;
my %seenRegDiv;
while (($icreg, $iccomp) = $sth->fetchrow_array) {
  $seenRegDiv{$icreg . $iccomp}++;
  $seenRegion{$icreg}++;
  $seenDiv{$iccomp}++;
}

my $total=0;
foreach my $regdiv (keys %seenRegDiv) {
  my $count = $dbh->selectrow_array("select count(*) from infoprodev.allied0d.bidbf${regdiv}.bipccm");
  warn "$regdiv\t$count\n";
  $total+=$count;
}
warn "total=$total\n";

# foreach my $region (keys %seenRegion) {
#   my $count = $dbh->selectrow_array("select count(*) from infopro.allied.ardbf${region}.arpco");
#   warn "$region\t$count\n";
#   $total+=$count;
# }
# warn "total=$total\n";

#print join(',', sort keys %seenRegion), "\n";
#print join(',', sort keys %seenDiv), "\n";
#print join(',', sort keys %seenRegDiv), "\n";
