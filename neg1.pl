#!perl -w
#
# Produce an HTML report on the health of the last N ETL batches.
# Default action is to email the report to the hard-coded recipient
# list below.  If a list of email addresses is passed, the HTML report
# is emailed to that list only.
#
# Usage: neg1.pl [user1@company.com [user2@company.com ...]]

use strict;
use DBI;
use MIME::Lite;
use HTML::Table;
use Win32::FileOp qw(ShellExecute);

# Report on the latest N ETL runs
my $runsToReport = 14;

# Configure MIME::Lite to use RSG's SMTP gateway
MIME::Lite->send('smtp', 'relay.repsrv.com', Timeout=>60);

# Set up the recipient list for the email, but allow an optional
# passed-in list of email addrs to override
my @to = @ARGV ? @ARGV : qw{
  dbloebaum@republicservices.com
  svennam@republicservices.com
  nwright@republicservices.com
  rpatel@republicservices.com
  epeters@republicservices.com
  pnovotny@republicservices.com
  JPalubinskas@republicservices.com
  EKairo@republicservices.com
  AHartono@republicservices.com
};

# bail out if there are no recipients
exit if @to == 0;

# Connect to prod dwcore via ODBC using Windows authentication of running user
my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

my $style = getCSS();
my $table = buildTable($dbh);

my $html =
  $style .
  '<p>' . localtime . ": Negative 1 SK report for fact_sales_activity, last $runsToReport runs</p>" .
  $table->getTable;

if ($to[0] eq 'HTML') {         # pop up a browser
  # localtime returns ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
  my ($sec,$min,$hour,$mday,$mon,$year) = (localtime)[0,1,2,3,4,5];
  my $ts = sprintf('%0.4d%0.2d%0.2d%0.2d%0.2d%0.2d', $year+1900,$mon+1,$mday,$hour,$min,$sec);

  my $tempFile = "$ENV{TMP}/neg1_tmp_$ts.htm";
  warn "tempFile=$tempFile\n";
  open(TMP,">$tempFile") or die "Can't open $tempFile for output -- $!\n";
  print TMP $html;
  close(TMP);
  Win32::FileOp::ShellExecute("$tempFile");
  sleep 10;
  unlink $tempFile;
}
else {    # email it
  # Prepare the email with our HTML table as a MIME attachment
  my $msg = MIME::Lite->new (
    From => 'dbloebaum@republicservices.com',
    To => join(',', @to),
    Subject => 'Negative 1 report',
    Type =>'multipart/mixed'
   ) or die "Error creating multipart container: $!\n";

  $msg->attach (
    Type => 'TEXT/HTML',
    Data => $html,
   ) or die "Error adding the text message part: $!\n";

  $msg->send;
}

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
           SUBSTRING(CONVERT(CHAR, batch_cntrl_id),1,8) + ' ' +
           SUBSTRING(CONVERT(CHAR, batch_cntrl_id),9,6) AS batch_cntrl_id_formatted,
           DATENAME(WEEKDAY,ela.batch_start_ts) + ' ' +
           CONVERT(CHAR, ela.batch_start_ts, 20) batch_start_ts,
           CONVERT(CHAR, ela.batch_end_ts, 20) batch_end_ts,
           CASE WHEN ela.batch_end_ts = '9999-12-31 00:00:00'
             THEN ' '
             ELSE CONVERT(CHAR, ela.batch_end_ts-ela.batch_start_ts, 8)
           END elapsed,
           ela.batch_status,
           neg1.batch_rows,
           neg1.acct_sk_neg_1,
           neg1.site_sk_neg_1,
           neg1.cg_sk_neg_1,
           neg1.corp_hier_sk_neg_1,
           neg1.ifp_hier_sk_neg_1
      FROM (SELECT batch_cntrl_id,
                   batch_start_ts,
                   batch_end_ts,
                   batch_status
              FROM dwetl.dbo.batch_audit
             WHERE batch_process != 'DSM'
               --AND DATEPART(HH, batch_start_ts) BETWEEN 2 AND 4
                   ) ela
           LEFT OUTER JOIN
           (SELECT fsa.ins_batch_id,
                   COUNT(CASE WHEN fsa.acct_sk = -1          THEN 1 ELSE NULL END) AS acct_sk_neg_1,
                   COUNT(CASE WHEN fsa.Site_SK = -1          THEN 1 ELSE NULL END) AS site_sk_neg_1,
                   COUNT(CASE WHEN fsa.Container_Grp_SK = -1 THEN 1 ELSE NULL END) AS cg_sk_neg_1,
                   COUNT(CASE WHEN fsa.corp_hier_sk = -1     THEN 1 ELSE NULL END) AS corp_hier_sk_neg_1,
                   COUNT(CASE WHEN fsa.infopro_hier_sk = -1  THEN 1 ELSE NULL END) AS ifp_hier_sk_neg_1,
                   COUNT(*) batch_rows
              FROM dwcore.dbo.fact_sales_activity fsa
             GROUP
                BY fsa.ins_batch_id) neg1
           ON neg1.ins_batch_id = ela.batch_cntrl_id
     ORDER
        BY batch_cntrl_id DESC
  });
  $sth->execute;

  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow(('')x6 , 'FSA Negative 1 SK Counts');
  $table->setRowHead(-1);
  $table->setCellColSpan(-1, 7, 5); # span the seventh column 5-wide

  $table->addRow(('')x6,'Acct','Site','Cg','Corp Hier','IFP Hier');
  $table->setRowHead(-1);

  # Add header row #2
  my $colno=0;
  foreach my $cellText ('Batch ID','Start','End','Elapsed<br>(hh:mm:ss)','Status','FSA Rows') {
    $colno++;
    $table->setCellSpan(1,$colno,2,1); # span each of these six header cells over two rows
    $table->setCell(1,$colno, $cellText);
  }

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    map {$_=commify($_)} @row;
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  # center a couple of columns; they look better that way
  $table->setColAlign(4,'CENTER');
  $table->setColAlign(5,'CENTER');

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
