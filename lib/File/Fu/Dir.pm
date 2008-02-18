package File::Fu::Dir;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

File::Fu::Dir - a directoryname object

=head1 SYNOPSIS

=cut

use base 'File::Fu::Base';

use overload (
  '+'  => 'file',
  '/'  => 'subdir',
);

=head1 Constructor

=head2 new

  my $dir = File::Fu::Dir->new($path);

  my $dir = File::Fu::Dir->new(@path);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {$class->_init(@_)};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 file_class

Return the corresponding file class for this dir object.

  my $fc = $class->file_class;

=cut

use constant file_class => 'File::Fu::File';
########################################################################

=for internal head2 _init
  my %fields = $class->_init(@_);

=cut

sub _init {
  my $class = shift;
  @_ or return(dirs => ['.']);
  my $dirs = [map({
    $_ eq '' ? ('') : split(/\/+/, $_)
  } @_)];
  @$dirs or $dirs = ['']; # XXX
  return(dirs => $dirs);
} # end subroutine _init definition
########################################################################

=head1 Methods

=head2 stringify

  my $string = $dir->stringify;

=cut

sub stringify {
  my $self = shift;
  #Carp::carp("stringify", overload::StrVal($self));
  #defined($self->{dirs}) or croak("how did this happen?");
  my @dirs = @{$self->{dirs}};
  #warn "I'm (", join(',', @{$self->{dirs}}), ")";
  @dirs or return('/');
  # TODO volume
  join('/', @dirs, ''); # always a trailing slash
} # end subroutine stringify definition
########################################################################

=head2 file

Create a filename object with $dir as its parent.

  my $file = $dir->file($filename);

  my $file = $dir + $filename;

=cut

sub file {
  my $self = shift;
  my ($name, $rev) = @_;
  $rev and croak("bah");

  return($self->file_class->new_direct(dir => $self, file => $name));
} # end subroutine file definition
########################################################################

=head2 append

  $newdir = $dir->append('.tmp');

  $dir .= "something";

=cut

sub append {
  my $self = shift;
  my ($bit, $rev) = @_;

  $rev and return($bit . "$self"); # stringify is out-of-order
  #carp("appending $bit");
  #$self = $self->clone;
  $self->{dirs}[-1] .= $bit;
  return($self);
} # end subroutine append definition
########################################################################

=head2 subdir

  $newdir = $dir->subdir('foo');

  $dir /= 'foo';

=cut

sub subdir {
  my $self = shift;
  my ($name, $rev) = @_;
  $rev and croak("bah");

  # appending to cwd means starting over
  return($self->new($name)) if($self->is_cwd);

  my %newbits = $self->_init($name);
  $self = $self->clone;
  push(@{$self->{dirs}}, @{$newbits{dirs}});
  $self;
} # end subroutine subdir definition
########################################################################

=head2 part

Returns the $i'th part of the directory list.

  my $part = $dir->part($i);

$dir->part(-1) is like $dir->basename, but not an object and not quite
like File::Basename::basename() when it comes to the / directory.

=cut

sub part {
  my $self = shift;
  my ($i) = @_;
  return($self->{dirs}[$i]);
} # end subroutine part definition
########################################################################

=head2 map

  $dir->map(sub {...});

=cut

sub map :method {
  my $self = shift;
  my ($sub) = shift;
  foreach my $dir (@{$self->{dirs}}) {
    local $_ = $dir;
    $sub->();
    $dir = $_;
  }
  $self;
} # end subroutine map definition
########################################################################

=head1 Properties

=head2 is_cwd

True if the $dir represents a relative (e.g. '.') directory.

  my $bool = $dir->is_cwd;

=cut

sub is_cwd {
  my $self = shift;

  my @dirs = @{$self->{dirs}};
  return(@dirs == 1 and $dirs[0] eq '.');
} # end subroutine is_cwd definition
########################################################################

=for note
dirname('.') and basename('.') are both '.' -- also true for '/'

=head2 basename

Returns the last part of the path as a Dir object.

  my $bit = $dir->basename;

=cut

sub basename {
  my $self = shift;
  return($self->new($self->{dirs}[-1]));
} # end subroutine basename definition
########################################################################

=head2 dirname

Returns the parent parts of the path as a Dir object.

  my $parent = $dir->dirname;

=cut

sub dirname {
  my $self = shift;
  $self = $self->clone;
  my $dirs = $self->{dirs};
  if(@$dirs == 1 and $dirs->[0] eq '') {
    return($self->new('/'));
  }
  pop(@$dirs);
  @$dirs or return($self->new);
  return($self);
} # end subroutine dirname definition
########################################################################

=head1 Doing stuff

=head2 open

Calls opendir(), but throws an error if it fails.

  my $dh = $dir->open;

Returns a directory handle, for e.g. readdir().

  my @files = map({$dir + $_} grep({$_ !~ m/^\./} readdir($dh)));

=cut

sub open :method {
  my $self = shift;

  opendir(my $dh, "$self") or die "cannot opendir '$self' $!";
  return($dh);
} # end subroutine open definition
########################################################################

=head2 listing

  my @paths = $dir->listing(all => 1);

=cut

sub listing {
  my $self = shift;

  map({my $d = $self/$_; -d $d ? $d : $self+$_} $self->contents(@_));
} # end subroutine listing definition
########################################################################

=head2 iterate_listing

  my $subref = $dir->iterate_listing(all => 1);

=cut

sub iterate_listing {
  my $self = shift;
  my $csub = $self->iterate_contents(@_);
  my $sub = sub {
    $csub or return();
    while(defined(my $n = $csub->())) {
      my $d = $self/$n;
      return(-d $d ? $d : $self+$n)
    }
    $csub = undef;
    return();
  };
  return($sub);
} # end subroutine iterate_listing definition
########################################################################

=head2 contents

Equivelant to readdir.  With the 'all' option true, returns hidden names
too (but not the '.' and '..' entries.)

The return values are strings, not File::Fu objects.

  my @names = $dir->contents(all => 1);

=cut

sub contents {
  my $self = shift;
  (@_ % 2) and croak('odd number of items in options hash');
  my %opts = @_;
  my $dh = $self->open;
  # XXX needs more cross-platformness
  $opts{all} and return(grep({$_ !~ m/^\.{1,2}$/} readdir($dh)));
  return(grep({$_ !~ m/^\./} readdir($dh)));
} # end subroutine contents definition
########################################################################

=head2 iterate_contents

Returns a subref which will iterate over the directory's contents.

  my $subref = $dir->iterate_contents(all => 1);

=cut

sub iterate_contents {
  my $self = shift;
  (@_ % 2) and croak('odd number of items in options hash');
  my %opts = @_;
  my $all = $opts{all};
  my $dh = $self->open;
  # XXX needs more cross-platformness
  return sub {
    $dh or return();
    while(defined(my $n = readdir($dh))) {
      if($all) {
        return($n) unless($n =~ m/^\.{1,2}$/);
      }
      else {
        return($n) unless($n =~ m/^\./);
      }
    }
    $dh = undef;
    return();
  };
} # end subroutine iterate_contents definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
