#!perl -w
#
# Return individual row counts and a grand total for a given file
# across all InfoPro divisional or regional libraries

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
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

# SQL to retrieve active InfoPro regions and divisions
my $sql = qq{
  SELECT ic.ICREG,
         ic.ICCOMP
    FROM prodbirpt.dwpsa.dbo.STG_IFP_BIPIC ic
         INNER JOIN prodbirpt.dwpsa.dbo.STG_IFP_BIPCO co
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

my $total=0;
my $libraryFile;
my $count;
my $i=0;
$= = 9999999;                   # only print the format header once
foreach my $regdiv (@loopArray) {
  $i++;
  $count = $dbh->selectrow_array(qq{
    SELECT * FROM OPENQUERY($linkedServer,
      'SELECT COUNT(*)
         FROM $serverName.$libraryBase${regdiv}.$table
         WITH UR'
    )
  });
  $total += defined $count ? $count : 0;
  $libraryFile = "$libraryBase$regdiv.$table";
  write;
}
# write the TOTAL line
$~='TOTAL';
write;

format STDOUT_TOP=

      Library.File              Row Count
      ------------------- ---------------
.

format STDOUT=
@>>>. @<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>
$i,   $libraryFile,       commify($count)
.

format TOTAL=
      ------------------- ---------------
      @>>>>>>>>>>>>>>>>>> @>>>>>>>>>>>>>>
      'TOTAL',            commify($total)
.

# Stolen subroutine to add a commas to numbers over 999
sub commify {
  local $_  = shift;
  return '?' unless defined $_;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}
