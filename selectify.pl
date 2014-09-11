#!perl -w
#
# With input consisting of two lines, the first being a tab-separated
# list of column names, the second being a tab-separated list of
# column values, return a SQL where clause in the form of
# colname='colvalue'

use strict;
use DBI;

warn "Enter your two tab-separated lines below:\n";

chomp(my $cols = <>);
chomp(my $vals = <>);

my @cols = split(/\t/,$cols);
my @vals = split(/\t/,$vals);

print "\nWHERE ";
my @equ;
foreach my $col (@cols) {
  my $val = shift @vals;
  push(@equ, "$col='$val'\n");
}

print join('  AND ', @equ);
