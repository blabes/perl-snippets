#!perl -w

my $header=<>;
chomp $header;
print "$header\n";
my @header = split(/\t/,$header);

my $rowcount=0;
my %maxlen;
my @fields;
my $fieldnum;
while(<>) {
  chomp;
  @fields = split(/\t/);
  #warn "fields=", scalar(@fields), "\n";
  if (@fields != 52) {
    warn "line $. was short... skipping\n";
    next;
  }

  $fieldnum=0;
  foreach my $field (@fields) {
    $fieldname=$header[$fieldnum];
    #print "fieldname=$fieldname\n";
    $fieldnum++;
    #print "  field $fieldnum: ", length($field), "\n";
    $maxlen{$fieldname} = length($field) if length($field) > $maxlen{$fieldname};
  }
  $rowcount++;
  #print "\n\n";
  warn "$.\n" if $. % 10000 == 0;
}

print "rowcount=$rowcount\n";

foreach my $fieldname (@header) {
  print $fieldname, ": ", $maxlen{$fieldname}, "\n";
}

