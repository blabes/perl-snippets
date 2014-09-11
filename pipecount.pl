#!perl -w

my $pipecount;
my $rowcount;
while(<>) {
  $pipecount=0;
  $pipecount++ while $_ =~ /\|/g;
  print "$.: $pipecount\n" if $pipecount!=20;
  $rowcount++
}

print "rowcount=$rowcount\n";

