#!/cygdrive/c/strawberry/perl/bin/perl
#
# Given an InfoPro division, return its place in the corp hierarchy

use strict;
use DBI;

my $usage = "Usage: $0 <div>\n";
my $div = shift or die $usage;

# left zero-fill $div to three wide
$div = sprintf("%0.3d", $div);
warn "Division=$div\n";

my $dbh = DBI->connect(
  "DBI:ODBC:Driver={SQL Server};" .
  "Server=srazphx76;" .
  "Database=dwcore"
) or die("DBI Connect Error - $DBI::errstr\n");

# Find dim_corp_hier info for this division
my $sth = $dbh->prepare(qq{
  SELECT DISTINCT
         h.Cur_Infopro_Div_Nbr,
         did.Infopro_Reg,
         h.cur_Region_Nbr + ' - ' + region_nm,
         h.Cur_BU_Nbr + ' - ' + BU_Desc,
         h.Cur_Area_Nbr + ' - ' + Area_Nm,
         h.Cur_Div_Nbr
    FROM Dim_Corp_Hier h
         INNER JOIN Dim_Infopro_Div did
            ON h.Cur_Infopro_Div_Nbr=did.Infopro_Div_Nbr
           AND did.is_Current=1
   WHERE h.cur_Infopro_Div_Nbr=?
     AND h.is_Current=1
});

$sth->execute($div);

my $iDiv;
my $ifpReg;
my $reg;
my $bu;
my $area;
my $lDiv;
while (($iDiv, $ifpReg, $reg, $bu, $area, $lDiv) = $sth->fetchrow_array) {
  write;
}

format STDOUT_TOP=
IFP Div  IFP Reg Region                 Area                   BU                     Lawson Div
-------  ------- ---------------------- ---------------------- ---------------------- ----------
.

format STDOUT=
@<<<<<<< @<<<<<< @<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<
$iDiv,   $ifpReg, $reg,                 $area,                 $bu,                   $lDiv
.
