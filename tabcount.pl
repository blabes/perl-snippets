#!perl -w

my $tabcount;
my $rowcount;
while(<>) {
  $tabcount=0;
  $tabcount++ while $_ =~ /\t/g;
  print "$.: $tabcount\n" if $tabcount != 51;
  $rowcount++
}

print "rowcount=$rowcount\n";

