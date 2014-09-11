#!perl -w
#

use strict;
use DBI;
use Getopt::Long;

my %opt;

$|=1;                           # turn off buffering on stdout

Getopt::Long::GetOptions(
  \%opt,
  'dev',
  'prod',
  'reg',
  'div',
);

die "$0: Can't set both -prod and -dev\n" if $opt{dev} and $opt{prod};
die "$0: Can't set both -reg and -div\n" if $opt{reg} and $opt{div};

my $table = uc(shift) or die "Usage: $0 [-prod|-dev] [-div|-reg] <table>\n";
my $libraryBase = 'BIDBF';      # change to ARDBF for AR files
#$libraryBase = 'ARDBF';      # change to ARDBF for AR files

my $linkedServer = $opt{dev} ? 'INFOPRODEV' : 'INFOPRO';
my $serverName   = $opt{dev} ? 'ALLIED0D'   : 'ALLIED';

print "Using InfoPro path of: $linkedServer.$serverName.$libraryBase<>.$table\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  'Server=srazphx12\devr1;' .
  "Database=dwpsa_analysis"
) or die("DBI Connect Error - $DBI::errstr\n");

# SQL to retrieve active InfoPro regions and divisions
my $sql = qq{
  SELECT ic.ICREG,
         ic.ICCOMP
    FROM srazphx76.dwpsa.dbo.STG_IFP_BIPIC ic
         INNER JOIN srazphx76.dwpsa.dbo.STG_IFP_BIPCO co
            ON ic.ICCOMP=co.COCOMP
           AND ic.CURRENT_IND='Y'
           AND co.CURRENT_IND='Y'
   WHERE ic.ICSTS='A'
     AND co.COACTV='1'
};

my $sth = $dbh->prepare($sql);
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
my $divCount = keys(%seenRegDiv);
print "$divCount active divisions\n";
my @loopArray = $opt{reg} ? keys %seenRegion : keys %seenRegDiv;

my $libraryFile;
my $i=1;
foreach my $regdiv (@loopArray) {
  warn "Iteration ", $i++, " / $divCount\n";
  my $sql = qq{
    INSERT INTO dbo.bipsuc
    SELECT * FROM OPENQUERY(infopro,
                            'SELECT *
                               FROM $serverName.$libraryBase${regdiv}.$table
                              WHERE sudate IN (20121110,20121111,20121112,20121113,20121114)
                              WITH UR')};
  warn "sql=$sql\n";
  my $rc = $dbh->do($sql);
  warn "rc=$rc\n";
}
