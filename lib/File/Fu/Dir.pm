package File::Fu::Dir;
$VERSION = v0.0.3;

use warnings;
use strict;
use Carp;

use File::Path (); # for now

use File::Fu::Dir::Temp;
use File::Fu::File::Temp;

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

=head1 Class Constants/Methods

=head2 file_class

Return the corresponding file class for this dir object.

  my $fc = $class->file_class;

=head2 is_dir

Always true for a directory.

=head2 is_file

Always false for a directory.

=cut

use constant file_class => 'File::Fu::File';
use constant is_dir => 1;
use constant is_file => 0;

########################################################################

=head2 temp_dir_class

  my $class = File::Fu::Dir->temp_dir_class;

=cut

sub temp_dir_class {
  my $package = shift;
  my $class = ref($package) . '::Temp';
  $class = __PACKAGE__ . '::Temp' unless($class->can('new'));
  return($class);
} # end subroutine temp_dir_class definition
########################################################################

=head2 temp_file_class

  my $class = File::Fu::Dir->temp_file_class;

=cut

sub temp_file_class {
  my $package = shift;
  my $class = $package->file_class . '::Temp';
  $class = __PACKAGE__->file_class.'::Temp' unless($class->can('new'));
  return($class);
} # end subroutine temp_file_class definition
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

=for note bareness
A dir which is a symlink doesn't show -l if checked with '/' on the end
of the string.

=cut

=begin shutup_pod_cover

=head2 l

=end shutup_pod_cover

=cut

*l = sub {-l shift->bare};

=head2 bare

Stringify without the trailing slash/assertion.

  my $str = $self->bare;

The trailing slash causes trouble when trying to address a symlink to a
directory via a dir object.  Thus, C<-l $dir> doesn't work, but
C<$dir->l> does.

=cut

sub bare {
  my $self = shift;
  my @dirs = @{$self->{dirs}};
  @dirs or return('/');
  # TODO volume
  join('/', @dirs); # always a trailing slash
} # end subroutine bare definition
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

=head2 end

Shorthand for part(-1);

=cut

sub end {shift->part(-1)};

=head2 map

Execute a callback on each part of $dir.  The sub should modify $_ (yes,
this is slightly unlike the map() builtin.)

  $dir->map(sub {...});

  $dir &= sub {s/foo$/bar/};

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

=head2 touch

Update the timestamp of a directory (croak if it doesn't exist.)

  $dir->touch;

=cut

sub touch {
  my $self = shift;
  $self->utime(time);
} # end subroutine touch definition
########################################################################

=head2 list

  my @paths = $dir->list(all => 1);

=cut

sub list {
  my $self = shift;

  map({my $d = $self/$_; -d $d ? $d : $self+$_} $self->contents(@_));
} # end subroutine list definition
########################################################################

=head2 lister

  my $subref = $dir->lister(all => 1);

=cut

sub lister {
  my $self = shift;
  my $csub = $self->iterate_contents(@_);
  my $sub = sub {
    $csub or return();
    while(defined(my $n = $csub->())) {
      my $d = $self/$n;
      return(-d $d->bare ? $d : $self+$n)
    }
    $csub = undef;
    return();
  };
  return($sub);
} # end subroutine lister definition
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

=head2 find

Not the same as File::Find::find().

  my @files = $dir->find(sub {m/foo/});

=cut

sub find {
  my $self = shift;

  my @return;
  my $finder = $self->finder(@_);
  while(defined(my $ans = $finder->())) {
    $ans or next;
    push(@return, $ans);
  }
  return(@return);
} # end subroutine find definition
########################################################################

=head2 finder

Returns an iterator for finding files.

  my $subref = $dir->finder(sub {$_->is_file and $_->file =~ m/foo/});

This allows a non-blocking find.

  while(defined(my $path = $subref->())) {
    $path or next; # 0 means 'not done yet'
    # do something with $path (is a file or dir object)
  }

And there is a knob:

  my $finder = $dir->finder(sub {
    return shift->prune
      if($_->is_dir and $_->part(-1) =~ m/^\.svn$/);
    $_->is_file and m/\.pm$/;
  });

=cut

sub finder {
  my $self = shift;
  my ($matcher, @opt) = @_;

  my %opt = (all => 1);

  my $reader;
  my @stack;
  my $it = sub {
    my $loops = 0;
    FIND: {
      $reader ||= $self->lister(all => $opt{all});
      $loops++;
      if(defined(my $path = $reader->())) {
        if($path->is_dir and not $path->l) {
          push(@stack, [$self, $reader]);
          ($self, $reader) = ($path, undef);
        }
        local $_ = $path;
        #warn "  check $path\n";
        my $ok = $matcher->(my $knob = File::Fu::Dir::FindKnob->new);
        if($knob->pruned) {
          ($self, $reader) = @{pop(@stack)};
        }
        if($ok) {
          return($path);
        }
        redo FIND if($loops < 50);
        return(0); # no match, but continue
      }
      else {
        @stack or return();
        ($self, $reader) = @{pop(@stack)};
        redo FIND;
      }
    }
  };
  return($it);
} # end subroutine finder definition
########################################################################

BEGIN {
package File::Fu::Dir::FindKnob;
use Class::Accessor::Classy;
with 'new';
ri 'pruned';
no  Class::Accessor::Classy;
sub prune {shift->set_pruned(1); 0}
} # File::Fu::Dir::FindKnob
########################################################################

=head2 mkdir

Create the directory or croak with an error.

  $dir->mkdir;

=cut

sub mkdir :method {
  my $self = shift;
  mkdir($self) or croak("cannot mkdir('$self') $!");
} # end subroutine mkdir definition
########################################################################

=head2 create

Create the directory, with parents if needed.

  $dir->create;

=cut

sub create {
  my $self = shift;
  File::Path::mkpath("$self");
} # end subroutine create definition
########################################################################

=head2 rmdir

Remove the directory or croak with an error.

  $dir->rmdir;

=cut

sub rmdir :method {
  my $self = shift;
  rmdir($self) or croak("cannot rmdir('$self') $!");
} # end subroutine rmdir definition
########################################################################

=head2 remove

Remove the directory and all of its children.

  $dir->remove;

=cut

sub remove {
  my $self = shift;
  my $dir = $self->stringify;
  File::Path::rmtree($dir);
  -e $dir and croak("rmtree failed"); # XXX rmtree is buggy
} # end subroutine remove definition
########################################################################

=head2 unlink

  $link->unlink;

=cut

sub unlink :method {
  my $self = shift;
  $self->l or croak("not a link");
  unlink($self->bare) or croak("unlink '$self' failed $!");
} # end subroutine unlink definition
########################################################################

=head2 symlink

  my $link = $file->symlink($linkname);

Note that symlinks are relative to where they live.

  my $dir = File::Fu->dir("foo");
  my $file = $dir+'file';
  # $file->symlink($dir+'link'); is a broken link
  my $link = $file->basename->symlink($dir+'link');

=cut

sub symlink :method {
  my $self = shift;
  my ($name) = @_;
  symlink($self->bare, $name) or
    croak("symlink '$self' to '$name' failed $!");
  return($self->new($name));
} # end subroutine symlink definition
########################################################################

=head2 readlink

  my $to = $file->readlink;

=cut

sub readlink {
  my $self = shift;
  my $name = readlink($self->bare);
  defined($name) or croak("cannot readlink '$self' $!");
  return($self->new($name));
} # end subroutine readlink definition
########################################################################

=head1 Temporary Directories and Files

These methods use the $dir object as a parent location for the temp
path.  To use your system's global temp space (e.g. '/tmp/'), just
replace $dir with 'File::Fu'.

  File::Fu->temp_dir;              # '/tmp/'
  File::Fu->dir->temp_dir;         # './'
  File::Fu->dir("foo")->temp_dir;  # 'foo/'

  File::Fu->temp_file;             # '/tmp/'
  File::Fu->dir->temp_file;        # './'
  File::Fu->dir("foo")->temp_file; # 'foo/'

=head2 temp_dir

Return a temporary directory in $dir.

  my $dir = $dir->temp_dir;

=cut

sub temp_dir {
  my $self = shift;
  $self->temp_dir_class->new($self, @_);
} # end subroutine temp_dir definition
########################################################################

=head2 temp_file

Return a filehandle to a temporary file in $dir.

  my $handle = $dir->temp_file;

=cut

sub temp_file {
  my $self = shift;
  $self->temp_file_class->new($self, @_);
} # end subroutine temp_file definition
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
