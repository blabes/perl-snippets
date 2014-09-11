#!perl -w
#
# With input consisting of two lines, the first being a tab-separated
# list of column names, the second being a tab-separated list of
# column values, print a two-column version of the information.  Works
# well with a clipboard paste from 1 row of SSMS

use strict;
use DBI;

warn "Enter your two tab-separated lines below:\n";

chomp(my $cols = <>);
chomp(my $vals = <>);

print "\n\n";

my @cols = split(/\t/,$cols);
my @vals = split(/\t/,$vals);

my $val;
my $col;
foreach $col (@cols) {
  $val = shift @vals;
  write;
}

format STDOUT_TOP=
Column Name                   Value
----------------------------- --------------------------------------------------
.

format STDOUT=
@<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$col,                         $val
.
