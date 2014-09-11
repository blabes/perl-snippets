#!perl -w

use File::Find;
use Text::CSV_XS;
use Data::Dumper;
use Date::Calc;

my $fileName = shift or die "Usage: $0 <ifpFile>\n";
my $prevDir='';
my $data;
my $div;

# Do a full traversal across all CDC files
#find(\&wanted, '//srazphx063/J/CDC/infopro/');

# Just loop through the ten active regions' directories
#for my $region (qw[ A E F M N O R S V W ]) {
#  find(\&wanted, "//srazphx063/J/CDC/infopro/$region/");
#}

# look at the cufile directory only
find(\&wanted, "//srazphx063/J/CDC/infopro/cufile/");

my $total=0;
my $grandTotal=0;
my $prevDiv='none';
my $mismatch='';
my $fdate;
my $ftime;
foreach $div (sort keys %$data) {
  $printDiv=$div;
  $total=0;
  foreach $file (sort keys %{$data->{$div}}) {
    $printCount = $data->{$div}->{$file}->{CALC_ROWS};
    $mismatch = ($printCount != $data->{$div}->{$file}->{FILE_ROWS}) ? '!' : '';
    $fdate = $data->{$div}->{$file}->{FILE_DATE};
    $ftime = $data->{$div}->{$file}->{FILE_TIME};
    $total += $printCount;
    write;
    $printDiv='';
  }
  print ' ' x 66, "------\n";
  $file = '';
  $fdate = '';
  $ftime = '';
  $printCount = $total;
  $grandTotal += $total;
  write;
  print "\n";
}
$file='Grand Total';
$printCount=$grandTotal;
write;

#print Dumper($data);

format STDOUT=
@<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @<<<<<<<< @##### @
$printDiv, $file,                            $fdate,    $ftime,   $printCount, $mismatch
.

sub wanted {
  return unless -f;
  if ($File::Find::dir ne $prevDir) {
    warn "Dir=$File::Find::dir\n";
    $div = $File::Find::dir;
    $div =~ s%.*/%%;
    warn "div=$div\n";
  }
  $prevDir = $File::Find::dir;

  return if /@/;                # skip non-hardened @ files
  return unless /^$fileName\./o;

  my ($ifpFile, $ds, $ts, $fr) = split(/\./);
  return unless $ifpFile and $ds and $ts and $fr;
  $fr =~ s/^R//;                # grab the row count from the filename, remove the leading R
  $fr+=0;                       # coerce it to a numeric


  # Convert the pseudo-Julian date embedded in the filename into a real date
  my ($yyyy, $ddd) = ($ds =~ /^D(....)(...)/);
  # return  unless $ddd == 235;
  my ($year,$month,$day) = Date::Calc::Add_Delta_Days($yyyy,1,1, $ddd-1);
  my $fdate=sprintf("%0.4d-%0.2d-%0.2d", $year, $month, $day);


  my ($hh, $mm, $ss) = ($ts =~ /^T(..)(..)(..)/);
  my $ftime=sprintf("%0.2d:%0.2d:%0.2d", $hh, $mm, $ss);

  open my $fh, $_ or die "Can't open $_ -- $!\n";
  my $rc=0;
  my $rci=0;
  my $rca=0;
  my $rcd=0;
  my $row;
  while($row = <$fh>) {
    my ($ts, $d, $action, $user) = split(/,/, $row);
    $rc++ if $action eq '"I"';  # increment our counter for Insert, After image, and Delete
    $rc++ if $action eq '"A"';  #   records, but ignore Before image records so as not to
    $rc++ if $action eq '"D"';  #   double count logical updates
    $rci++ if $action eq '"I"';
    $rca++ if $action eq '"A"';
    $rcd++ if $action eq '"D"';
  }
  $data->{$div}->{$_}->{CALC_ROWS} = $rc;
  $data->{$div}->{$_}->{I} = $rci;
  $data->{$div}->{$_}->{A} = $rca;
  $data->{$div}->{$_}->{D} = $rcd;
  $data->{$div}->{$_}->{FILE_ROWS} = $fr;
  $data->{$div}->{$_}->{FILE_DATE} = $fdate;
  $data->{$div}->{$_}->{FILE_TIME} = $ftime;
}
