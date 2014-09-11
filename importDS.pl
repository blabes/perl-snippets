#!perl -w

use strict;
use DBI;

use File::Find;
use Cwd;

my $usage = "Usage: $0 <dsProj> <dsUser> <dsPass>\n";
my $dsHost = 'SRAZPHX052:9080';
my $dsPath = 'D:/IBM/InformationServer/Clients/Classic';
my $dsImportCmd = "$dsPath/dsimport.exe";
$dsImportCmd = "$dsPath/dscmdimport.exe";

my $dsProj = shift or die $usage;
my $dsUser = shift or die $usage;
my $dsPass = shift or die $usage;
$dsProj = "SRAZPHX052/$dsProj";

find(\&wanted, '.');

sub wanted {
  return unless -f;
  warn "dir=$File::Find::dir\n";
  return if $File::Find::dir =~ /processed/;
  return unless /\.dsx$/;
  my $cmd = "$dsImportCmd /H=$dsHost /U=$dsUser /P=$dsPass /O=omitflag /NUA $dsProj $_ /V";
  warn "Running $cmd\n";
  system($cmd) == 0 or die "$0: $cmd failed\n";
  die "$0: No 'processed' directory found\n" unless -d 'processed';
  system("mv $_ processed/") == 0 or die "$0: mv failed -- $!\n";
}
