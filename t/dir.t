#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

{
  my $d = File::Fu->dir("foo." . $$);
  $d->e and $d->rmdir;
  $d->mkdir;
  ok($d->e, 'exists');
  ok($d->d, 'is a directory');
  $d->rmdir;
  ok(! $d->e, 'not exists');
  eval { $d->touch };
  like($@, qr/^cannot/);

  my $f = $d + 'foo';
  eval { $f->touch };
  like($@, qr/^cannot.*No such/);
  $d->mkdir;
  $f->touch;
  eval { $d->rmdir };
  like($@, qr/^cannot.*not empty/);
  $f->unlink;
  $d->rmdir;
  ok(! $d->e, 'not exists');

  my $dl = $d->symlink('link.' . $$);
  ok($dl->l, 'is a link');
  is($dl->readlink, "$d");
  ok(! $dl->e, 'not exists');
  eval { $dl->mkdir };
  like($@, qr/^cannot.*exists/, 'link not dir');

  # lstat a broken link is ok, stat isn't
  ok($dl->lstat);
  eval { $dl->stat };
  like($@, qr/^cannot.*No such/);

  $d->mkdir;
  ok($dl->e, 'exists');
  ok($d->e, 'exists');

  # cannot change the time of a link?
  my $lt = $d->lstat->mtime;
  $dl->utime($lt + 8);
  my $dt = $lt + 8;
  is($dl->lstat->mtime, $lt);
  is($d->stat->mtime, $dt);
  is($dl->stat->mtime, $dt, 'mtime');
  # hmm, what else can I test without sleeping?
  $dl->unlink;
  $d->rmdir;
}
{
  my $d = File::Fu->dir('tmp.' . $$);
  $d->e and $d->rmdir;
  $d->mkdir;
  my @files = map({my $f = $d + $_; $f->touch; $f} qw(bar baz foo));
  (my $subdir = $d / 'zonk')->mkdir;
  push(@files, $subdir);
  is_deeply([sort $d->list], [@files], 'list');
  is((sort $d->list)[-1], $d/'zonk');

  my $it = $d->lister;
  my @got;
  while(my $f = $it->()) { push(@got, $f); }
  is_deeply([sort @got], [@files], 'lister');
  $d->remove;
}

# vim:ts=2:sw=2:et:sta
