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
use GD::Graph::linespoints;
use HTML::Table;
use Data::Dumper;

# Report on the latest N ETL runs
my $runsToReport = 100;

# Configure MIME::Lite to use RSG's SMTP gateway
MIME::Lite->send('smtp', 'relay.repsrv.com', Timeout=>60, Debug=>0);

# Set up the recipient list for the email, but allow an optional
# passed-in list of email addrs to override
my @to = @ARGV ? @ARGV : qw{
  dbloebaum@republicservices.com
  yraj@republicservices.com
  svennam@republicservices.com
  nwright@republicservices.com
  rpatel@republicservices.com
  epeters@republicservices.com
  pnovotny@republicservices.com
  AAguilar@republicservices.com
  JPalubinskas@republicservices.com
  bbaker3@republicservices.com
};

# Connect to prod dwcore via ODBC using Windows authentication of running user
my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

# bail out if there are no recipients
exit if @to == 0;

# Prepare the email with our HTML table as a MIME attachment
my $msg = MIME::Lite->new (
  From => 'dbloebaum@republicservices.com',
  To => join(',', @to),
  Subject => 'Sales ETL Elapsed Time Trend',
  Type =>'multipart/related'
) or die "Error creating multipart container: $!\n";

my ($image, $table) = buildImage($dbh);
my $style = getCSS();

my $html =
  $style .
  "<body><p>" . localtime . ": Sales ETL Trending Report, last $runsToReport runs</p>" .
  '<br> <img src="cid:image.png"> <br><br><br>' .
  $table;

$msg->attach(
  Type     => 'text/html',
  Data     => $html,
) or die "Error adding the text message part: $!\n";

$msg->attach (
  Type => 'image/png',
  Data => $image,
  Id => 'image.png',
) or die "Error adding the text message part: $!\n";

#$msg->send;

#
# Subroutines
#

# build the batch elapsed time graph
sub buildImage {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT TOP $runsToReport
           DATENAME(WEEKDAY, start_ts) + ' ' + CONVERT(CHAR, start_ts) start_time,
           CONVERT(CHAR, end_ts) end_time,
           elapsed_time,
           CONVERT(VARCHAR, DATEPART(MM,end_ts)) + '/' + CONVERT(VARCHAR,DATEPART(DD,end_ts)) end_date,
           elapsed_sec
      FROM dwetl.dbo.etl_job_hist
     where JOB_NAME='Seq_FACT_SALES_ACTIVITY'
     ORDER
        BY end_ts DESC
  });
  $sth->execute;

  my $graph = new GD::Graph::linespoints(600,300);

  $graph->set(
    x_label => 'Date',
    y_label => 'Elapsed Time (sec)',
    title => 'Sales ETL Elapsed Time Trend',
    y_min_value => 1000,
    marker_size => 1,
    x_label_skip => 7,
    markers => [ 7 ],

    transparent => 0,
  );

  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Start Time', 'End Time', 'Elapsed');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  my @date;
  my @elapsed_sec;
  while (my ($start_time, $end_time, $elapsed_time, $end_date, $elapsed_sec) = $sth->fetchrow_array) {
    $table->addRow($start_time, $end_time, $elapsed_time);
    $table->setRowAlign(-1,'RIGHT');
    unshift(@date, $end_date);
    unshift(@elapsed_sec, $elapsed_sec);
  }

  my $data = GD::Graph::Data->new([
    \@date,
    \@elapsed_sec,
  ]) or die GD::Graph::Data->error;

  warn "date=@date\n";
  warn "elapsed_sec=@elapsed_sec\n";

  $graph->plot($data);
  my $image = $graph->gd()->png;
  open(IMG,">my.png") or die;
  binmode IMG;
  print IMG $image;
  close IMG;

  return $image, $table;
}

# Stolen subroutine to add a commas to numbers over 999
sub commify {
  return '0' unless defined $_;
  return $_ unless /^[.0-9]+$/;
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}

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
