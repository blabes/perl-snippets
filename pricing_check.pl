#!perl -w
#
# Produce an HTML report on the health of the monthly pricing ETL
#
# Usage: pricing_check.pl [user1@company.com [user2@company.com ...]]

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
  pnovotny@republicservices.com
  AAguilar@republicservices.com
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

my @subList = (
  \&buildRegionByMonthTable,
  \&buildAreasByMonthTable,
  \&buildDivisionsByMonthTable,
  \&buildRevByRegByMonthTable,
  \&buildRevByAreaByMonthTable,
  \&buildRevByDivByMonthTable,
);

my $html = $style . '<p>' . localtime . ": Pricing ETL Report</p>";
foreach my $sub (@subList) {
  my $table = &$sub($dbh);
  $html .= $table->getTable . '<br>';
}

# Prepare the email with our HTML table as a MIME attachment
my $msg = MIME::Lite->new (
  From => 'dbloebaum@republicservices.com',
  To => join(',', @to),
  Subject => 'Pricing ETL report',
  Type =>'multipart/mixed'
) or die "Error creating multipart container: $!\n";

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

sub buildRevByDivByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           hier_nbr,
           SUM(revenue_amt) total_revenue_amt,
           SUM(Qty_Svc) total_qty_svc
      FROM Agg_Service_Billed
     WHERE Hier_Lvl_Nm='DIVISION'
     GROUP
        BY Report_Period_SK,
           Hier_Nbr
     ORDER
        BY Report_Period_SK,
           Hier_Nbr
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Division','Revenue','Service Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    map {$_=commify($_)} @row;
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

sub buildRevByAreaByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           hier_nbr,
           SUM(revenue_amt) total_revenue_amt,
           SUM(Qty_Svc) total_qty_svc
      FROM Agg_Service_Billed
     WHERE Hier_Lvl_Nm='AREA'
     GROUP
        BY Report_Period_SK,
           Hier_Nbr
     ORDER
        BY Report_Period_SK,
           Hier_Nbr
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Region','Revenue','Service Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    map {$_=commify($_)} @row;
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

sub buildRevByRegByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           hier_nbr,
           SUM(revenue_amt) total_revenue_amt,
           SUM(Qty_Svc) total_qty_svc
      FROM Agg_Service_Billed
     WHERE Hier_Lvl_Nm='REGION'
     GROUP
        BY Report_Period_SK,
           Hier_Nbr
     ORDER
        BY Report_Period_SK,
           Hier_Nbr
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Region','Revenue','Service Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    map {$_=commify($_)} @row;
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

sub buildRegionByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           COUNT(*) region_count
     FROM (SELECT DISTINCT report_period_sk,
                  hier_nbr
             FROM agg_service_billed
            WHERE Hier_Lvl_Nm='REGION'
          ) t
    GROUP
       BY Report_Period_SK
    ORDER
       BY Report_Period_SK
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Region Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

sub buildAreasByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           COUNT(*) area_count
      FROM (SELECT DISTINCT report_period_sk,
                   hier_nbr
              FROM agg_service_billed
             WHERE Hier_Lvl_Nm='AREA'
           ) t
     GROUP
        BY Report_Period_SK
     ORDER
        BY Report_Period_SK
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Area Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
    $table->addRow(@row);
    $table->setRowAlign(-1,'RIGHT');
  }

  return $table;
}

sub buildDivisionsByMonthTable {
  my $dbh = shift or die;

  my $sth = $dbh->prepare(qq{
    SELECT SUBSTRING(CAST(report_period_sk AS CHAR),1,4) + '-' +
             SUBSTRING(CAST(report_period_sk AS CHAR),5,2) Report_Period,
           COUNT(*) division_count
     FROM (SELECT DISTINCT report_period_sk,
                  hier_nbr
             FROM agg_service_billed
            WHERE Hier_Lvl_Nm='DIVISION'
          ) t
    GROUP
       BY Report_Period_SK
    ORDER
       BY Report_Period_SK
  });

  $sth->execute;
  my $table = new HTML::Table;
  $table->setClass('gridtable');

  # Add header row #1
  $table->addRow('Report Period','Division Count');
  $table->setRowHead(-1);

  # Now add the data rows from the query results
  while (my @row = $sth->fetchrow_array) {
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
