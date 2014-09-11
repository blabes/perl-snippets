#!/usr/bin/perl -w
#
use strict;
use Text::CSV_XS;

# We expect 45 fields (44 pipes) in each logical BIPSUC row
my $desiredPipeCount=44;

# Read the input filename from the command line
my $file = shift or die "Usage: $0 <csv_filename>\n";

# construct the CSV parser
my $csv = Text::CSV_XS->new ({
  binary             => 1,
  allow_loose_quotes => 1,
  auto_diag          => 1,
  escape_char        => undef,
}) or die "Text::CSV_XS constructor failed: " . Text::CSV_XS->error_diag();

# open the input file for read
open my $inputFH,  "<", $file or die "$file: $!";

# open the output file for write
open my $outputFH, ">", "$file.out" or die "$file.out: $!";

my @out;			# declare variables outside the loops for better performance
my $outputRow;
my $inputRow;
my $pipeCount;
while ($inputRow = $csv->getline($inputFH)) { # iterate over each row in the input file
  @out=();			# empty out the array which will hold our corrected fields
  foreach (@$inputRow) {	# iterate over each field in the input row
    s/[\0\|\n\r]//g;	        # get rid NUL, pipe, CR, and LF characters
    s/\s+/ /g;		        # change multi-whitespace to single
    push(@out,$_);		# push the corrected field on to an array
  }
  $outputRow = join('|',@out);	# create a pipe-delimited line from the corrected array

  $outputRow =~ s/^\s+//;	# trim leading whitespace
  $outputRow =~ s/\s+$//;	# trim trailing whitespace

  $pipeCount = ($outputRow =~ tr/|//); # count the number of pipe characters in the row
  unless ($pipeCount == $desiredPipeCount) {
    warn "On row $.: pipeCount=$pipeCount instead of $desiredPipeCount; skipping it\n";
    next;			# don't write out the row unless it has the right number of fields
  }

  print $outputFH "$outputRow\n";
}
