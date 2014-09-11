#!/perl -w
#
# Program: ror_copy.pl
#
# Purpose: copy ROR PDF files from a source directory to a destination
#          directory.  The destination directory depends on the PDF
#          filename
#
#  Author: Doug Bloebaum (SEI)
#
# Changes: initial version - Bloebaum - 2012-02-03
#

use File::Find;

logit("Starting\n");
my $sourceDir='E:\\Cognos10Burst\\ror_base';
my $destBase='E:\\Cognos10Burst';

$sourceDir='c:\\cygwin\\home\\Doug Bloebaum\\ror_base'; # DEV ONLY
$destBase='c:\\cygwin\\home\\Doug Bloebaum\\ror_dest';  # DEV ONLY

# map of filename pattern to its destination directory
my %fileMap=(
  '*R1*EAST*.pdf'    => 'ror_east',
  '*R2*SOUTH*.pdf'   => 'ror_south',
  '*R3*MIDWEST*.pdf' => 'ror_midwest',
  '*R4*WEST*.pdf'    => 'ror_west',
);

# get a "before" count of PDF files in the source dir
my $pdfCount=0;
find(\&pdfCount, $sourceDir);
my $sourcePdfCount=$pdfCount;
logit("There are $sourcePdfCount PDF files in the source area\n");

# Loop over each filename pattern and xcopy to the correct dest dir
chdir $sourceDir or die "$0: chdir $sourceDir failed -- $!\n";
for my $pattern (keys %fileMap) {
  my $destDir = $fileMap{$pattern};
  logit("pattern=$pattern destDir=$destDir\n");
  my $cmd = qq{xcopy $pattern "$destBase\\$destDir" /s /d /i /y};
  logit("cmd=$cmd\n");
  system($cmd) == 0 or die "$0: xcopy failed -- $!\n";
}

# get an "after" count of PDF files in the destination directory
$pdfCount=0;
find(\&pdfCount, $destBase);
my $destPdfCount=$pdfCount;
logit("There are $destPdfCount PDF files in the destination area\n");

# print out a count match or mis-match message
if ($sourcePdfCount==$destPdfCount) {
  logit("source and dest PDF file counts match\n");
}
else {
  logit("WARNING -- source and dest PDF file counts mismatch\n");
}

logit("Complete\n");

###################
### Subroutines ###
###################

sub pdfCount {
  return unless /\.pdf$/;
  $pdfCount++;
}

sub getTs {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
  my $ts = sprintf("%d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d", 1900+$year, $mon, $mday, $hour, $min, $sec);
  return $ts;
}

sub logit {
  my $msg = shift;
  my $ts = getTs();
  warn "[$ts] $0 -- $msg";
}
