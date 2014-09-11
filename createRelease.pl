#!perl -w
#
# Given a file which contains a list of filenames (one per row) find
# those files in the current directory structure and copy them to a
# new folder
#
# Usage:
#
#   createRelease.pl <infile> <newdir>
#
# Sample Usage:
#
#   D:
#   cd \LongTerm_Project_4\DSTGV81\Projects\Jobs
#   perl c:\Landing\Doug\createRelease.pl c:\Landing\Doug\jobnames.txt new_dir
#
# Another Way (in bash):
#
#   mkdir newdir
#   for file in `cat c:/landing/doug/jobnames.txt`
#   do
#     find . -name newdir -prune -o -name $file -print -exec echo cp \{} ./newdir/ \;
#   done

use File::Find;
use Cwd;

my $infile = shift or die "Usage: $0 <infile> <newdir>\n";
my $newdir = shift or die "Usage: $0 <infile> <newdir>\n";
my $cwd = Cwd::getcwd();
$newdir = "$cwd/$newdir";
warn "newdir=$newdir\n";

open(IN, "$infile") or die "$0: Can't open $infile for input -- $!\n";

my $file;
mkdir $newdir or die "$0: Can't create $newdir -- $!\n";
while($file = <IN>) {
  chomp($file);
  find(\&wanted, ".");
}

sub wanted {
  return unless -f;
  return unless /^$file$/;
  warn "cp $_ $newdir\n";
  system("cp $_ $newdir");
}
