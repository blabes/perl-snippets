#!perl -w
#
# 
# This script will bring back the metadata of the table from infopro
#

use strict;
use DBI;

my $usage = "Usage: $0 <env> <lib> <schema> <tabname>\n";
my $env = shift or die $usage;
my $lib = shift or die $usage;
my $schema = shift or die $usage;
my $tabname = shift or die $usage;

# warn displays the message. Displaying the values being passed
warn "Environment (infoprodev/infopro) = $env\n";
warn "Library (qsys1/qysy2) = $lib\n";
warn "Schema (BIDBFE802) = $schema\n";
warn "Table Name (BIPSD) = $tabname\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwpsa"
) or die("DBI Connect Error - $DBI::errstr\n");


# Find the region letter for the given division
my $sql_stmt = qq{
  select * from openquery($env,'select * from allied.$lib.syscolumns where system_table_schema=''$schema'' and table_name=''$tabname'' order by ordinal_position')
};
warn "SQL Statement = $sql_stmt\n";

my $rec_set = $dbh->selectall_arrayref($sql_stmt);

open(OUT, ">describetable.csv") or die;

foreach my $rec_cnt (@$rec_set) {
  warn "record count=@$rec_cnt\n";
  print OUT join(',', @$rec_cnt), "\n";
}

close(OUT);

$dbh = DBI->disconnect();
