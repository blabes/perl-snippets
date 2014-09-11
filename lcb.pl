#!/usr/bin/perl -w

use XML::Twig;

my $twig=XML::Twig->new();

$twig->parsefile('model.xml');
my $root = $twig->root;

my $name;
my $lastChanged;
my $lastChangedBy;

my $elt = $root;
while($elt=$elt->next_elt($root,'lastChangedBy')) {
  $name = $elt->prev_sibling('name')->text;
  $lastChanged = $elt->prev_sibling('lastChanged')->text;
  $lastChangedBy = $elt->text;
  $lastChanged = defined $lastChanged ? $lastChanged : '';
  $lastChangedBy = defined $lastChangedBy ? $lastChangedBy : '';
  write;
}

format STDOUT=
@<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$lastChanged,         $lastChangedBy,           $name
.
