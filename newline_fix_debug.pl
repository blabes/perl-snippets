#!/usr/bin/perl -w
#
# Look for DOS CR/LF line-endings (hex 0d)(hex 0a) and replace them
# with nothing, then continue with the functionality usually provided
# by delimit.pl
#
# Sample Usage: newline_fix.pl  J:/projects/DEV_R2/inbound/ BIPSUC.D* J:/projects/DEV_R2/processing/
#
use strict;
##################################
## user supplied variables
##################################
my $input_directory=$ARGV[0];
my $pattern=$ARGV[1];
my $output_directory=$ARGV[2];
##################################
# Read directories from input folder
##################################
opendir(IN,$input_directory) or die("Cannot open input directory");
my @input_files= readdir(IN);
closedir(IN);
##################################
# loop through files
##################################
my $bufsiz = 32767;
my $delimsExpected=44;          # number of delimiters we expect per row

my $buffer = '';
my $delimCount=0;
my @delimCount=();

foreach my $file (@input_files) {
  if ( $file =~ m/$pattern/i ) {
    open(INFILE,"< $input_directory$file") or die("Cannot open file $input_directory$file for reading");
    open(OUTFILE,"> $input_directory$file.tmp") or die("Cannot open file $input_directory$file.tmp for writing");
    binmode(INFILE);            # keep from turning Unix line-endings into DOS ones on read

    # first we do buffer-based reads so we can find and remove CR/LF's
    while(read(INFILE, $buffer, $bufsiz)) {
      warn "found CR/LF in $file\n" if $buffer =~ /\x0d\x0a/;
      $buffer =~ s/\x0d\x0a//g; # globally replace control-M control-J with nothing
      $buffer =~ s/\0//g;       # get rid of NUL characters
      $buffer =~ s/\|//g;       # get rid of pipe characters
      print OUTFILE $buffer;
    }
    close(INFILE);
    close(OUTFILE);

    open(INFILE,"< $input_directory$file.tmp") or die("Cannot open file $input_directory$file.tmp for reading");
    open(OUTFILE,"> $output_directory$file") or die("Cannot open file $output_directory$file for writing");
    print "Opening file $input_directory$file.tmp for reading\n";
    print "Opening file $output_directory$file for writing\n";

    # now we do traditional line-based reads for other clean-ups
    while (<INFILE>) {
      s/^\s+//; 		# trim leading whitespace
      s/\s+$//; 		# trim trailing whitespace
      s/","/|/g;                # change "," to |
      s/\s+/ /g;                # change multi-whitespace to single
      s/^.//g;                  # trim starting char (hopefully ")
      s/"$//;                   # trim ending "
      $delimCount = tr/|//;     # efficiently count the number of pipes on this line

      print OUTFILE $_, "\n" if $delimCount == $delimsExpected; # exclude "broken" rows
    }
    close(OUTFILE);
    close(INFILE);
  }
}
