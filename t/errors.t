#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $f = File::Fu->dir;

eval {my $nope = $f - 8};
like($@, qr/^- is not a valid op/);

eval {my $nope = $f * 8};
like($@, qr/^\* is not a valid op/);

eval {my $nope = $f << 8};
like($@, qr/^<< is not a valid op/);

# vim:ts=2:sw=2:et:sta
