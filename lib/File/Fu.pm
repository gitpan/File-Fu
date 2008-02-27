package File::Fu;
$VERSION = v0.0.2;

use warnings;
use strict;
use Carp;

=head1 NAME

File::Fu - file and directory objects

=head1 SYNOPSIS

=cut


use File::Fu::File;
use File::Fu::Dir;
use File::Spec ();

use constant dir_class => 'File::Fu::Dir';
use constant file_class => 'File::Fu::File';

=head1 Constructors

The actual objects are in the 'Dir' and 'File' sub-namespaces.

=head2 dir

  my $dir = File::Fu->dir($path);

See L<File::Fu::Dir/new>

=cut

sub dir {
  my $package = shift;

  $package or croak("huh?");
  # also as a function call
  unless($package and $package->isa(__PACKAGE__)) {
    unshift(@_, $package);
    $package = __PACKAGE__;
  }

  $package->dir_class->new(@_);
} # end subroutine dir definition
########################################################################

=head2 file

  my $file = File::Fu->file($path);

See L<File::Fu::File/new>

=cut

sub file {
  my $package = shift;

  # also as a function call
  unless($package->isa(__PACKAGE__)) {
    unshift(@_, $package);
    $package = __PACKAGE__;
  }

  $package->file_class->new(@_);
} # end subroutine file definition
########################################################################

=head1 Class Constants

=head2 tmp

Your system's '/tmp/' directory (or equivelant of that.)

  my $dir = File::Fu->tmp;

=cut

{
my $tmp; # XXX needs locking?
sub tmp {
  my $package = shift;
  $tmp and return($tmp);
  return($tmp = $package->dir(File::Spec->tmpdir));
}}
########################################################################

=head1 Temporary Directories and Files

These class methods call the corresponding File::Fu::Dir methods on the
value of tmp().  That is, you get a temporary file/dir in the '/tmp/'
directory.

=head2 temp_dir

  my $dir = File::Fu->temp_dir;

=cut

sub temp_dir {
  my $package = shift;
  $package->tmp->temp_dir(@_);
} # end subroutine temp_dir definition
########################################################################

=head2 temp_file

  my $handle = File::Fu->temp_file;

=cut

sub temp_file {
  my $package = shift;
  $package->tmp->temp_file(@_);
} # end subroutine temp_file definition
########################################################################

=head1 Subclassing

You may wish to subclass File:Fu and override the dir_class() and/or
file_class() class methods to point to your own Dir/File subclasses.

  my $class = 'My::FileFu';
  my $dir = $class->dir("foo");

See L<File::Fu::File> and L<File::Fu::Dir> for more info.

=head1 See Also

L<File::Fu::why> if I need to explain my motivations.

L<Path::Class>, from which many an idea was taken.

L<File::stat>, L<IO::File>, L<File::Spec>, L<File::Find>, L<File::Temp>,
L<File::Path>, L<File::Basename>, L<perlfunc>, L<perlopentut>.

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
