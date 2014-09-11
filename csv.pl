#!perl -w
#

use strict;

while(<>) {
  my @fields = split(/,/);
  print "$.: colcount=", scalar(@fields), ":  $_";
}
