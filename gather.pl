#!perl -w
#
# Return individual row counts and a grand total for a given file
# across all InfoPro divisional or regional libraries

use strict;
use DBI;
use Getopt::Long;

my %opt;

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

my $linkedServer = $opt{dev} ? 'INFOPRODEV' : 'INFOPRO';
my $serverName   = $opt{dev} ? 'ALLIED0D'   : 'ALLIED';

print "Using InfoPro path of: $linkedServer.$serverName.$libraryBase<>.$table\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx12;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

my @sql;
foreach my $region (qw{A E F M N O R S W V}) {
  push(@sql, qq{SELECT ICREG, LTRIM(ICCOMP) ICCOMP
                  FROM INFOPRO.ALLIED.CUFILE.BIPIC, INFOPRO.ALLIED.BIDBF$region.BIPCO
                 WHERE ICCOMP = COCOMP AND ICSTS='A' AND COACTV='1'});
}
my $sql = join(' UNION ALL ', @sql);

# Query InfoPro to find all active regions and divisions
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
$= = 9999999;                   # only print the format header once
foreach my $regdiv (@loopArray) {
  my $sql = qq[
    select * from openquery(infopro,'select CCCOMP,
                                            CCACCT,
                                            CCSITE,
                                            CCCTGR,
                                            CCTAC,
                                            CCCLDT,
                                            COUNT(*) as occurs
                                       from allied.bidbf${regdiv}.bipcc
                                      where CCCHCD=''DSP''
                                        and CCCHTY=''S''
                                        and CCCGMT=''W''
                                   group by CCCOMP,
                                            CCACCT,
                                            CCSITE,
                                            CCCTGR,
                                            CCTAC,
                                            CCCLDT
                                     having count(*) > 1
                                        for fetch only with ur')];
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  while (my @row=$sth->fetchrow_array) {
    warn "row=@row\n";
  }
}
