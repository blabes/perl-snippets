#!perl -w

use strict;
use DBI;

# Connect to prod dwcore via ODBC using Windows authentication of running user
my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

my $factTable = 'Fact_Invoice_Detail';

my @sk = qw{
  Charge_Cd_SK
  Acct_SK
  Revenue_Period_SK
  Residential_Charge_Cd_SK
  Post_Period_SK
  Site_SK
  Container_Grp_SK
  Corp_Hier_SK
  InfoPro_Hier_SK
  Rate_SK
  Contract_SK
  Service_Cd_SK
  Acct_Fee_SK
  Route_SK
  Invoice_Dt_SK
  Service_Dt_SK
  Invoice_From_Dt_SK
  Invoice_To_Dt_SK
  Infopro_Div_SK
  Contract_Grp_SK
};

my $sql = "SELECT * INTO #neg1_counts FROM (SELECT ";

foreach my $sk (@sk) {
  $sql .= "CONVERT(DECIMAL(18,2), SUM(CASE WHEN $sk = -1 THEN 1 ELSE 0 END)) AS ${sk}_neg_ones,\n";
  $sql .= "CONVERT(DECIMAL(18,2), SUM(CASE WHEN $sk = -2 THEN 1 ELSE 0 END)) AS ${sk}_neg_twos,\n";
  $sql .= "CONVERT(DECIMAL(18,2), SUM(CASE WHEN $sk >  0 THEN 1 ELSE 0 END)) AS ${sk}_valids,\n";
}

$sql .= "CONVERT(DECIMAL(18,2), COUNT(*)) AS total FROM $factTable) t\n";

warn "sql=$sql";
$dbh->do($sql);

my @sql;
foreach my $sk (@sk) {
  push(@sql, qq{
    SELECT '$sk', total, ${sk}_neg_ones, ${sk}_neg_twos, ${sk}_valids,
           ${sk}_neg_ones/total*100, ${sk}_neg_twos/total*100, ${sk}_valids/total*100
      FROM #neg1_counts
  });
}

$sql = join(' UNION ALL ', @sql);
warn "sql=$sql\n";

my $sth = $dbh->prepare($sql);
$sth->execute;

my @row;
while (@row = $sth->fetchrow_array) {
  $row[1] = commify($row[1]);
  $row[2] = commify($row[2]);
  $row[3] = commify($row[3]);
  $row[4] = commify($row[4]);
  write;
}

format STDOUT_TOP=
SK Column                      Total_Rows     Neg1_Count     Neg2_Count    Valid_Count    -1%    -2%   Val%
--------------------------     ----------     ----------     ----------    -----------    ---    ---   ----
.

format STDOUT=
@<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>> @>>>>>>>>>>>>> @>>>>>>>>>>>>> @>>>>>>>>>>>>> @##.## @##.## @##.##
$row[0],                   $row[1],       $row[2],       $row[3],       $row[4],       $row[5], $row[6], $row[7]
.

# Stolen subroutine to add a commas to numbers over 999
sub commify {
  local $_  = shift;
  return '0' unless defined $_;
  return $_ unless /^[.0-9]+$/;
  s/\.00$//;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}
