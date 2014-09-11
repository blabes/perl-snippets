#!perl -w

use strict;
use DBI;

my $usage = "Usage: $0 library (ex: BIDBFO224, BIDBFO, ARDBFO224, ADRDBFO, CUFILE)\n";

my $library = uc shift or die $usage;

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx12;" .
  "Database=dwpsa"
) or die("DBI Connect Error - $DBI::errstr\n");

my $linkedServer='infopro';  # infopro or infoprodev

print "linkedServer=$linkedServer\n";

my $listSql = qq{
select * from openquery($linkedServer,
  'select system_table_schema,
          system_table_name,
          table_type,
          last_altered_timestamp,
          COALESCE(table_text,'') || COALESCE(long_comment,'')
    from qsys2.systables
   where system_table_schema=''$library''
   order
      by system_table_name
    with ur')
};

my $listSth = $dbh->prepare($listSql);
$listSth->execute;

my $table_schema;
my $table_name;
my $table_type;
my $last_altered_ts;
my $table_text;
my $fullTableName;
my $tabCount=0;
while (($table_schema,
        $table_name,
        $table_type,
        $last_altered_ts,
        $table_text) = $listSth->fetchrow_array) {
  $tabCount++;
  $fullTableName = "$table_schema.$table_name";
  $last_altered_ts = substr($last_altered_ts,0,19);
  $table_text = defined $table_text ? $table_text : '';
  write;
}
print "\n$tabCount tables\n";

format STDOUT=
@<<<<<<<<<<<<<<<<< @ @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$fullTableName,    $table_type, $last_altered_ts,   $table_text
.
