#!perl -w
#
# Return a CSV list of active regions and regions/divisions.  Default
# action is to email HTML report to the recipient list.  If an arg of
# MEMAIL is passed, the HTML report is emailed only to a test group of
# recipients.  If an arg of NOMAIL is passed, a text report is printed
# to the screen.

use strict;
use DBI;
use MIME::Lite;
use HTML::Table;

my $arg = shift || '';

# Set up the recipient list for the email
my @to = qw{
  dbloebaum@republicservices.com
  yraj@republicservices.com
  svennam@republicservices.com
  nwright@republicservices.com
  rpatel@republicservices.com
  epeters@republicservices.com
  iyerku@republicservices.com
  pnovotny@republicservices.com
};

@to = () if $arg =~ /nomail/i;
@to = ('dbloebaum@republicservices.com') if $arg =~ /memail/i;

# Connect to prod dwcore via ODBC using Windows authentication of running user
my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

my $batchSth = $dbh->prepare(qq{
select TOP 1
       batch_cntrl_id,
       CONVERT(CHAR, batch_start_ts, 20) AS batch_start_ts,
       CONVERT(CHAR, batch_end_ts, 20) AS batch_end_ts,
       batch_status,
       CONVERT(CHAR, BATCH_END_TS - BATCH_START_TS, 8) as batch_elapsed_time
  from DWETL.dbo.BATCH_AUDIT
 where BATCH_PROCESS != 'DSM'
   and datepart(hh, batch_start_ts) between 2 and 4
 order
    by BATCH_CNTRL_ID DESC
});
$batchSth->execute;

my ($batch_cntrl_id,
    $batch_start_ts,
    $batch_end_ts,
    $batch_status,
    $batch_elapsed_time) = $dbh->selectrow_array($batchSth);

# Query to find -1 surrogate keys by ETL batch
my $sth = $dbh->prepare(qq{
SELECT TOP 7
       SUBSTRING(CONVERT(CHAR, ins_batch_id), 1,4) + '-' +
       SUBSTRING(CONVERT(CHAR, ins_batch_id), 5,2) + '-' +
       SUBSTRING(CONVERT(CHAR, ins_batch_id), 7,2) + ' ' +
       SUBSTRING(CONVERT(CHAR, ins_batch_id), 9,2) + ':' +
       SUBSTRING(CONVERT(CHAR, ins_batch_id),11,2) + ':' +
       SUBSTRING(CONVERT(CHAR, ins_batch_id),13,2) AS ins_batch_id_formatted,
       COUNT(CASE WHEN acct_sk = -1          THEN 1 ELSE NULL END) AS acct_sk_neg_1,
       COUNT(CASE WHEN Site_SK = -1          THEN 1 ELSE NULL END) AS site_sk_neg_1,
       COUNT(CASE WHEN Container_Grp_SK = -1 THEN 1 ELSE NULL END) AS cg_sk_neg_1,
       COUNT(CASE WHEN corp_hier_sk = -1     THEN 1 ELSE NULL END) AS corp_hier_sk_neg_1,
       COUNT(*) batch_rows
  FROM fact_sales_activity
 GROUP
    BY ins_batch_id
 ORDER
    BY ins_batch_id DESC
});
$sth->execute;

# Build an HTML table with the above query's results
my $table = new HTML::Table;
$table->setClass('gridtable');

$table->addRow('Batch ID','Acct_SK','Site_SK','CG_SK','Hier_SK','Batch_Rows');
$table->setRowHead(-1);

my @row;
while (@row = $sth->fetchrow_array) {
  map {$_=commify($_)} @row;
  write && next if @to == 0;

  $table->addRow(@row);
  $table->setRowAlign(-1,'RIGHT');
}

# bail out if we're just producing the text version
exit if @to == 0;

# CSS to make the table a little prettier
my $style = qq{
<HEAD>
  <style type="text/css">
  table.gridtable {
    font-family: verdana,arial,sans-serif;
    font-size:11px;
    color:#333333;
    border-width: 1px;
    border-color: #666666;
    border-collapse: collapse;
  }
  table.gridtable th {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: #666666;
    background-color: #dedede;
  }
  table.gridtable td {
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: #666666;
    background-color: #ffffff;
  }
  </style>
</HEAD>
};

# Prepare the email with our HTML table as a MIME attachment
my $msg = MIME::Lite->new (
  From => 'dbloebaum@republicservices.com',
  To => join(',', @to),
  Subject => 'Negative 1 report',
  Type =>'multipart/mixed'
) or die "Error creating multipart container: $!\n";

my $html =
  $style .
  "<p>The latest batch ($batch_cntrl_id, status '$batch_status') " .
  "ran from $batch_start_ts to $batch_end_ts in $batch_elapsed_time<p>" .
  '<p>' . localtime . ': Negative 1 SK report for fact_sales_activity, last 7 days</p>' .
  $table->getTable;

$msg->attach (
  Type => 'TEXT/HTML',
  Data => $html,
) or die "Error adding the text message part: $!\n";

MIME::Lite->send('smtp', 'relay.repsrv.com', Timeout=>60);
$msg->send;

# Stolen subroutine to add a commas to numbers over 999
sub commify {
  return $_ unless /^[.0-9]+$/;
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}

# Formats for the text version of the report
format STDOUT_TOP=
Batch_ID                Acct_Sk     Site_SK       Cg_SK     Hier_SK  Batch_Rows
--------                -------     -------       -----     -------  ----------
.

format STDOUT=
@>>>>>>>>>>>>>>>>>> @>>>>>>>>>> @>>>>>>>>>> @>>>>>>>>>> @>>>>>>>>>> @>>>>>>>>>>
$row[0],            $row[1],    $row[2],    $row[3],    $row[4],    $row[5]
.
