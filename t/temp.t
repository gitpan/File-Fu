#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $tmp = File::Fu->dir->temp_dir('tmp.');
can_ok($tmp, 'basename');
can_ok($tmp, 'dirname');
is($tmp->dirname, './');
like($tmp->basename, qr/^tmp\./);
eval {$tmp /= "foo"};
like($@, qr/^cannot mutate/);
my $subdir = $tmp / 'foo';
ok(! $subdir->isa('File::Fu::Dir::Temp'));

{
  my $fn;
  {
    my $fh = File::Fu->dir->temp_file;
    $fn = $fh->name;
    is($fn->dirname, File::Fu->dir);
    ok($fn->e);
    ok(-e $fn);
    $fn = "$fn";
  }
  ok(! -e $fn, 'gone');
}
{
  my $fn;
  {
    my $fh = File::Fu->temp_file('foo');
    $fn = $fh->name;
    like($fn->basename, qr/^foo/);
    is($fn->dirname, File::Fu->tmp);
    ok($fn->e);
    ok(-e $fn);
    $fn = "$fn";
  }
  ok(! -e $fn, 'gone');
}


# vim:ts=2:sw=2:et:sta
