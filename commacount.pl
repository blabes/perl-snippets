#!perl -w

my $commacount;
my $rowcount;
while(<>) {
  $commacount=0;
  $commacount++ while $_ =~ /,/g;
  print "$.: $commacount\n" if $commacount!=9;
  $rowcount++
}

print "rowcount=$rowcount\n";

