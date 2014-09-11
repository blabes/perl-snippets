#!perl -w
#

use strict;
use DBI;
use Data::Dumper;

# turn off buffering on stdout
$|=1;

# get today's date in yyyy-mm-dd format
# localtime returns ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
my ($mday,$mon,$year) = (localtime)[3,4,5];
my $today = sprintf('%0.4d-%0.2d-%0.2d', $year+1900, $mon+1, $mday);

# build a data structure to hold info about our SQL Server instances
my $allInstances = {
  prod  => {
    server    => 'srazphx76',
    databases => ['DWCORE','DWCORE_STATIC'],
  },
  qa    => {
    server    => 'srazphx057',
    databases => ['DWDAILY','DWUPDATE'],
  },
  qar1  => {
    server => 'srazphx057\qar1',
    databases => ['DWCORE'],
  },
  qar2  => {
    server => 'srazphx057\qar2',
    databases => ['DWCORE'],
  },
  devr1 => {
    server => 'srazphx12\devr1',
    databases => ['DWCORE'],
  },
  devr2 => {
    server => 'srazphx12\devr2',
    databases => ['DWCORE'],
  },
};

# set up a DBI connection for each instance and store them in our hash
my $connectStringBase = 'DBI:ODBC:Driver={SQL Server};Server=';
foreach my $instanceName (keys %$allInstances) {
  my $server = $allInstances->{$instanceName}->{server};
  $allInstances->{$instanceName}->{dbh} = DBI->connect($connectStringBase . $server)
    or die "$0: Connection to $instanceName ($server) failed\n";
}

#print Dumper($allInstances);

# For each instance and DWCORE-like database, check the ETL_TABLE_STATUS table
my $instanceName;
my $printInstance;
my $db;
my $business_dt;
my $table_name;
print "\nData Currency Report for $today:\n";
foreach $instanceName (keys %$allInstances) {
  $printInstance = $instanceName;
  foreach $db (@{$allInstances->{$instanceName}->{databases}}) {
    my $dbh = $allInstances->{$instanceName}->{dbh};
    my $sql = "SELECT table_name, MAX(CONVERT(DATE,business_dt)) FROM $db.dbo.ETL_TABLE_STATUS GROUP BY Table_Name";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    print "\n";
    while(($table_name, $business_dt) = $sth->fetchrow_array) {
      write;
      $printInstance='';
    }
  }
}

# Now report how far along the prod ETL is
my $currentSql = qq{
  SELECT TOP 5
         BATCH_CNTRL_ID,
         SRC_OBJ_NM,
         TGT_OBJ_NM,
         LOAD_REC_CNT,
         INS_UPDT_DT,
         JOB_NM
    FROM dwetl.dbo.BATCH_DW_LOAD_DETAIL
   WHERE batch_cntrl_id=(SELECT MAX(batch_cntrl_id) FROM dwetl.dbo.BATCH_DW_LOAD_DETAIL)
   ORDER
      BY INS_UPDT_DT desc
};

my $salesSql = qq{
  SELECT TOP 5
         BATCH_CNTRL_ID,
         SRC_OBJ_NM,
         TGT_OBJ_NM,
         LOAD_REC_CNT,
         INS_UPDT_DT,
         JOB_NM
    FROM dwetl.dbo.BATCH_DW_LOAD_DETAIL
   WHERE JOB_NM='Load_Agg_Sales_Activity'
   ORDER BY INS_UPDT_DT DESC
};

my $pricingSql = qq{
  SELECT TOP 5
         BATCH_CNTRL_ID,
         SRC_OBJ_NM,
         TGT_OBJ_NM,
         LOAD_REC_CNT,
         INS_UPDT_DT,
         JOB_NM
    FROM dwetl.dbo.BATCH_DW_LOAD_DETAIL
   WHERE JOB_NM='Load_FactServiceDetailPass2Delta'
   ORDER BY INS_UPDT_DT DESC
};

my @row;

print "\nSales ETL Completion Report\n\n";
printResults($allInstances->{prod}->{dbh}, $salesSql);

print "\nPricing ETL Completion Report\n\n";
printResults($allInstances->{prod}->{dbh}, $pricingSql);

print "\nLatest 5 ETL Jobs Completed\n\n";
printResults($allInstances->{prod}->{dbh}, $currentSql);


format STDOUT_TOP=
Instance       Table                               Business Date
----------     --------------------------------  ---------------
.

format STDOUT=
@<<<<<<<<<<    @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>
$printInstance, $db . '.' . $table_name,      $business_dt
.

format STDERR_TOP=
Batch_ID      Source               Target                    Rows Timestamp               Job
------------- -------------------- -------------------- --------- ----------------------- ----------------------------------
.

format STDERR=
@<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<< @######## @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$row[0],      $row[1],             $row[2],             $row[3],    $row[4],                   $row[5]
.

sub printResults {
  my $dbh = shift;
  my $sql = shift;

  my $sth = $dbh->prepare($sql);
  $sth->execute;

  select STDERR;
  $- = 0;
  select STDOUT;
  while(@row = $sth->fetchrow_array) {
    write STDERR;
  }

}
