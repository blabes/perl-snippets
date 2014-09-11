#!perl -w
#
# Return the row count for a given table

use strict;
use DBI;

my $arg = uc(shift) or die "Usage: $0 <server.db.schema.table>\n";

my ($server, $db, $schema, $table) = split(/\./, $arg);

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=$server;" .
  "Database=$db"
) or die("DBI Connect Error - $DBI::errstr\n");

my $count = $dbh->selectrow_array(qq{
  SELECT REPLACE(CONVERT(CHAR,CONVERT(MONEY,COUNT_BIG(*)),1),'.00','') FROM $db.$schema.$table
});

warn "$table\t$count\n";
