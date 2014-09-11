#!perl -w
#
# Usage: factCounts.pl [user1@company.com [user2@company.com ...]]

use strict;
use DBI;
use MIME::Lite;
use HTML::Table;

# Report on the latest N ETL runs
my $runsToReport = 14;

# Configure MIME::Lite to use RSG's SMTP gateway
MIME::Lite->send('smtp', 'relay.repsrv.com', Timeout=>60);

# Set up the recipient list for the email, but allow an optional
# passed-in list of email addrs to override
my @to = @ARGV ? @ARGV : qw{
  dbloebaum@republicservices.com
  yraj@republicservices.com
  svennam@republicservices.com
  nwright@republicservices.com
  rpatel@republicservices.com
  epeters@republicservices.com
  iyerku@republicservices.com
  pnovotny@republicservices.com
  AAguilar@republicservices.com
  JPalubinskas@republicservices.com
};

# Connect to prod dwcore via ODBC using Windows authentication of running user
my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

my $style = getCSS();
my $table = buildTable($dbh);

# bail out if there are no recipients
exit if @to == 0;

# Prepare the email with our HTML table as a MIME attachment
my $msg = MIME::Lite->new (
  From => 'dbloebaum@republicservices.com',
  To => join(',', @to),
  Subject => 'Fact Count Report',
  Type =>'multipart/mixed'
) or die "Error creating multipart container: $!\n";

my $html =
  $style .
  '<p>' . localtime . ": Fact Count Report for last $runsToReport runs</p>" .
  $table->getTable;

$msg->attach (
  Type => 'TEXT/HTML',
  Data => $html,
) or die "Error adding the text message part: $!\n";

$msg->send;

#
# Subroutines
#

# CSS to make the table a little prettier
sub getCSS {
  my $css = qq{
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

  return $css;
}

# build the batch elapsed time table
sub buildTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT TOP $runsToReport
           SUBSTRING(CONVERT(CHAR, ba.batch_cntrl_id),1,8) + ' ' + SUBSTRING(CONVERT(CHAR, ba.batch_cntrl_id),9,6) AS batch_cntrl_id_formatted,
           DATENAME(WEEKDAY,ba.batch_start_ts) + ' ' + CONVERT(CHAR, ba.batch_start_ts, 20) batch_start_ts,
           CONVERT(CHAR, ba.batch_end_ts, 20) batch_end_ts,
           CASE WHEN ba.batch_end_ts = '9999-12-31 00:00:00'
             THEN ' '
             ELSE CONVERT(CHAR, ba.batch_end_ts-ba.batch_start_ts, 8)
           END elapsed,
           ba.batch_status,
           fsa.rc,
           fid.rc,
           fsd.rc
      FROM dwetl.dbo.batch_audit ba
           LEFT OUTER JOIN (SELECT ins_batch_id, COUNT(*) rc FROM dwcore.dbo.fact_sales_activity GROUP BY ins_batch_id) fsa
             ON ba.batch_cntrl_id=fsa.ins_batch_id
           LEFT OUTER JOIN (SELECT ins_batch_id, COUNT(*) rc FROM dwcore.dbo.fact_invoice_detail GROUP BY ins_batch_id) fid
             ON ba.batch_cntrl_id=fid.ins_batch_id
           LEFT OUTER JOIN (SELECT ins_batch_id, COUNT(*) rc FROM dwcore.dbo.fact_service_detail GROUP BY ins_batch_id) fsd
             ON ba.batch_cntrl_id=fsd.ins_batch_id
     WHERE ba.batch_process != 'DSM'
     ORDER
        BY ba.batch_cntrl_id DESC
  });
  $sth->execute;

  my $table = new HTML::Table;
  $table->setClass('gridtable');

  $table->addRow('Batch ID','Start','End','Elapsed<br>(hh:mm:ss)','Status','FSA Rows','FID Rows','FSD Rows');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    map {$_=commify($_)} @row;
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

# Stolen subroutine to add a commas to numbers over 999
sub commify {
  return '0' unless defined $_;
  return $_ unless /^[.0-9]+$/;
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}
