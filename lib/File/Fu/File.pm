package File::Fu::File;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use IO::File ();

=head1 NAME

File::Fu::File - a filename object

=head1 SYNOPSIS

=cut

use base 'File::Fu::Base';

use Class::Accessor::Classy;
lv 'file';
ro 'dir';  aka dir  => 'dirname', 'parent';
no  Class::Accessor::Classy;

#use overload ();

=head1 Constructor

=head2 new

  my $file = File::Fu::File->new($path);

  my $file = File::Fu::File->new(@path);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {$class->_init(@_)};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 new_direct

  my $file = File::Fu::File->new_direct(
    dir => $dir_obj,
    file => $name
  );

=cut

sub new_direct {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {@_};
  bless($self, $class);
  return($self);
} # end subroutine new_direct definition
########################################################################

=head2 dir_class

Return the corresponding dir class for this file object.

  my $dc = $class->dir_class;

=cut

use constant dir_class => 'File::Fu::Dir';
########################################################################

=for internal head2 _init
  my %fields = $class->_init(@_);

=cut

sub _init {
  my $class = shift;
  my @dirs = @_ or croak("file must have a name");
  my $file = pop(@dirs);
  if($file =~ m#/#) {
    croak("strange mix: ", join(',', @_, $file)) if(@dirs);
    my %p = $class->dir_class->_init($file);
    @dirs = @{$p{dirs}};
    $file = pop(@dirs);
  }

  return(dir => $class->dir_class->new(@dirs), file => $file);
} # end subroutine _init definition
########################################################################

=head1 Parts

=head2 basename

Returns a new object representing only the file part of the name.

  my $obj = $file->basename;

=cut

sub basename {
  my $self = shift;
  $self->new($self->file);
} # end subroutine basename definition
########################################################################

=head1 Methods

=head2 stringify

  my $string = $file->stringify;

=cut

sub stringify {
  my $self = shift;
  my $dir = $self->dir;
  #warn "stringify(..., $_[1], $_[2])";
  #Carp::carp("stringify ", overload::StrVal($self), " ($self->{file})");
  $dir = $dir->is_cwd ? '' : $dir->stringify;
  return($dir . $self->file);
} # end subroutine stringify definition
########################################################################

=head2 append

  $newfile = $file->append('.gz');

  $file .= '.gz';

=cut

sub append {
  my $self = shift;
  my ($tail) = @_;
  $self->file .= $tail;
  $self;
} # end subroutine append definition
########################################################################

=head2 map

  $file->map(sub {...});

  $file &= sub {...};

=cut

sub map :method {
  my $self = shift;
  my ($sub) = shift;
  local $_ = $self->file;
  $sub->();
  $self->file = $_;
  $self;
} # end subroutine map definition
########################################################################

=head2 absolute

Get an absolute name

=cut

sub absolute {
  my ($self) = shift;
  return($self->dir->absolute->file($self->file));
}

=head1 Doing stuff

=head2 open

Open the file with $mode ('<', 'r', '>', 'w', etc) -- see L<IO::File>.

  my $fh = $file->open($mode, $permissions);

Throws an error if anything goes wrong or if the resulting filehandle
happens to be a directory.

=cut

sub open :method {
  my $self = shift;
  my $fh = IO::File->new($self, @_) or croak("cannot open '$self' $!");
  -d $fh and croak("$self is a directory");
  return($fh);
} # end subroutine open definition
########################################################################

=head2 link

  my $link = $file->link($name);

=cut

sub link :method {
  my $self = shift;
  my ($name) = @_;
  link($self, $name) or croak("link '$self' to '$name' failed $!");
  return($self->new($name));
} # end subroutine link definition
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
  symlink($self, $name) or
    croak("symlink '$self' to '$name' failed $!");
  return($self->new($name));
} # end subroutine symlink definition
########################################################################

# TODO
# my $link = $file->dwimlink(absolute|relative|samedir => $linkname);

=head2 rename

Calls the builtin rename() on the $file and returns a new object with
that name.

  $file = $file->rename($newname);

=cut

sub rename :method {
  my $self = shift;
  my ($name) = @_;

  rename($self, $name) or
    croak("cannot rename '$self' to '$name' $!");
  return($self->new($name));
} # end subroutine rename definition
########################################################################

=head2 unlink

  $file->unlink;

=cut

sub unlink :method {
  my $self = shift;
  unlink("$self") or croak("unlink '$self' failed $!");
} # end subroutine unlink definition
########################################################################

=head2 readlink

  my $to = $file->readlink;

=cut

sub readlink {
  my $self = shift;
  my $name = readlink($self);
  defined($name) or croak("cannot readlink '$self' $!");
  return($self->new($name));
} # end subroutine readlink definition
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
