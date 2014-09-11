#!/cygdrive/c/strawberry/perl/bin/perl -w
#
# Do a "DESCRIBE" on an AS/400 library.file
#

use strict;
use Getopt::Long;
use Data::Dumper;
use DBI;

my $usage = "Usage: $0 [-prod|-dev] [-coldump] library.file (ex: bidbfm999.bipsd)\n";

my %opt;

Getopt::Long::GetOptions(
  \%opt,
  'coldump',
  'dev',
  'prod'
);

die "$0: Can't set both -prod and -dev\n" if $opt{dev} and $opt{prod};

# allow parms to be passed as library.file or library file
my $arg = uc join(' ', @ARGV);
my ($library, $file) = split(/[. ]/, $arg);
die $usage unless $library and $file;

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx12;" .
  "Database=dwpsa"
) or die("DBI Connect Error - $DBI::errstr\n");

my $linkedServer = $opt{dev} ? 'infoprodev' : 'infopro';
my $serverName   = $opt{dev} ? 'allied0d'   : 'allied';

warn "Using InfoPro path of: $linkedServer.$serverName\n";

# look for a table description on our specific library.file
my $tabSql = qq{
SELECT * FROM OPENQUERY($linkedServer,
 'SELECT table_text
    FROM $serverName.qsys2.systables
   WHERE table_text != ''''
     AND system_table_schema=''$library''
     AND system_table_name=''$file''
   FETCH FIRST ROW ONLY WITH UR')
};
my $table_text = $dbh->selectrow_array($tabSql);
$table_text = '' unless defined $table_text;

if ($table_text eq '') {
  warn "No table_text found... trying other libraries\n";
  # get the first non-empty table description for our table in any
  # library; lots of libraries have blank descriptions for a given
  # table, but sometimes one or two will have something helpful
  $tabSql = qq{
  SELECT * FROM OPENQUERY($linkedServer,
   'SELECT table_text
      FROM $serverName.qsys2.systables
     WHERE table_text != ''''
       AND system_table_name=''$file''
     FETCH FIRST ROW ONLY WITH UR')
  };
  $table_text = $dbh->selectrow_array($tabSql);
  $table_text = '' unless defined $table_text;
}

# get the column details for this table
my $descSql = qq{
SELECT * FROM OPENQUERY($linkedServer,
  'SELECT system_table_name,
          system_column_name,
          TRIM(data_type) || ''('' || length || COALESCE('','' || numeric_scale, '''') || '')'' AS type,
          COALESCE(column_text, column_heading) AS column_text,
          storage,
          is_nullable
    FROM $serverName.qsys2.syscolumns
   WHERE system_table_schema=''$library''
     AND system_table_name=''$file''
   ORDER
      BY ordinal_position
    WITH UR')
};

my $descSth = $dbh->prepare($descSql);
$descSth->execute;

print "--\n";
print "-- $table_text\n";
print "--\n";
print "CREATE TABLE $library.$file(\n";
my $table_name;
my $column_name;
my $type;
my $column_text;
my $is_nullable;
my $null_text;
my $storage;
my $colCount=0;
my $storageTotal=0;
my @cols;
while (($table_name, $column_name, $type, $column_text, $storage, $is_nullable) = $descSth->fetchrow_array) {
  push(@cols, $column_name);
  $colCount++;
  $storageTotal += $storage;
  $column_text = defined $column_text ? $column_text : '';
  $null_text = $is_nullable eq 'Y' ? 'NULL,' : 'NOT NULL,';
  write;
}
print ")\n";
print "$colCount columns\n";
print "$storageTotal bytes/row\n";

print join("\t",@cols), "\n" if $opt{coldump};

format STDOUT=
    @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<< -- @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $column_name,            $type,                  $null_text,  $column_text
.
