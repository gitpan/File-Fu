#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use File::Fu;

my $topdir = File::Fu->dir('tmp.' . $$);
END { $topdir->remove; }

$topdir->mkdir;
($topdir+$_)->touch for('a'..'z');
my $foo = $topdir->subdir("foo");
$foo->mkdir;
$foo->basename->symlink($topdir/'link');
($foo+$_)->touch for('a'..'z');

# bah!
my $x = do {
  my @files = $topdir->list;
  my ($i) = grep({$files[$_]->basename eq 'foo/'} 0..$#files);
  $_->unlink for(@files[($i+1)..$#files]);
  #warn join("|", $topdir->contents);
  $files[0]->basename;
};

my @files = $topdir->find(sub {
  #warn $_;
  $_->is_dir and return(shift->prune);
  $_->basename eq $x
});

is(scalar(@files), 1);

# vim:ts=2:sw=2:et:sta
