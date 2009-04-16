package File::is;

=head1 NAME

File::is - file is older? oldest? is newer? newest? similar? the same?

=head1 VERSION

Version 0.01

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Carp;

our %stat_map = (
    'dev'     => 0,
    'ino'     => 1,
    'mode'    => 2,
    'nlink'   => 3,
    'uid'     => 4,
    'gid'     => 5,
    'rdev'    => 6,
    'size'    => 7,
    'atime'   => 8,
    'mtime'   => 9,
    'ctime'   => 10,
    'blksize' => 11,
    'blocks'  => 12,
);

=head1 SYNOPSIS

    use File::is;

    # return if F<file1> is newer than F<file2> or F<file3>.
    return
        if File::is->newer('file1', 'file2', 'file3');

    # do something if F<path1/file1> is older than F<file2> or F<path3/file3>.
    do_some_work()
        if File::is->older([ 'path1', 'file1'], 'file2', [ 'path3', 'file3' ]);

=head1 DESCRIPTION

This module is a result of /me not wanting to write:

    if ($(stat('filename'))[9] < $(stat('tmp/other-filename'))[9]) { do_someting(); };

Instead I wrote a module with ~80 lines of code and ~90 lines of tests
for it... So how is the module different from the above C<if>? Should be
reusable, has more functionality, should be clear from the code it self
what the condition is doing and was fun to play with it. Another advantage
is that the file names can be passed as array refs. In this case
L<File::Spec/catfile> is used to construct the filename. The resulting code
is:

    if (File::is->older('filename', [ 'tmp', 'other-filename' ])) { do_something(); };

=head1 FUNCTIONS

=head2 newer($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is newer (has modification
timestamp recent) then any of the rest passed as argument.

=head2 newest($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is newest (has the biggest
modification timestamp) compared to the rest of the passed filenames.

=head2 older($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is older (has the later
modification timestamp) then any of the rest passed as argument.

=head2 oldest($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is oldest (has the latest
modification timestamp) compared to the rest of the passed filenames.

=head2 similar($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> has the same size and modification
timestamp than any of the rest of the passed filenames.

=head2 thesame($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> has the same inode (is hard link)
to any of the rest of the passed filenames.

=head2 bigger($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is bigger (has the bigger
size) then any of the rest passed as argument.

=head2 biggest($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is biggest (has the biggest
size) compared to the rest of the passed filenames.

=head2 smaller($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is smaller (has the smaller
size) then any of the rest passed as argument.

=head2 smallest($primary_filename, $other_filename, $other_filename2, ...)

Returns true/false if the C<$primary_filename> is smallest (has the smallest
size) compared to the rest of the passed filenames.

=cut

sub newer {
    return shift->_cmp_stat(1, sub { $_[0]->[$stat_map{'mtime'}] > $_[1]->[$stat_map{'mtime'}] }, @_);
}
sub newest {
    return shift->_cmp_stat(0, sub { $_[0]->[$stat_map{'mtime'}] <= $_[1]->[$stat_map{'mtime'}] }, @_);
}
sub older {
    return shift->_cmp_stat(1, sub { $_[0]->[$stat_map{'mtime'}] < $_[1]->[$stat_map{'mtime'}] }, @_);
}
sub oldest {
    return shift->_cmp_stat(0, sub { $_[0]->[$stat_map{'mtime'}] >= $_[1]->[$stat_map{'mtime'}] }, @_);
}
sub similar {
    return shift->_cmp_stat(
        1,
        sub {
            $_[0]->[$stat_map{'size'}] == $_[1]->[$stat_map{'size'}]
            and $_[0]->[$stat_map{ 'mtime'}] == $_[1]->[$stat_map{'mtime'}]
        },
        @_
    );
}
sub thesame {
    return shift->_cmp_stat(1, sub { $_[0]->[$stat_map{'ino'}] == $_[1]->[$stat_map{'ino'}] }, @_);
}
sub bigger {
    return shift->_cmp_stat(1, sub { $_[0]->[$stat_map{'size'}] > $_[1]->[$stat_map{'size'}] }, @_);
}
sub biggest {
    return shift->_cmp_stat(0, sub { $_[0]->[$stat_map{'size'}] <= $_[1]->[$stat_map{'size'}] }, @_);
}
sub smaller {
    return shift->_cmp_stat(1, sub { $_[0]->[$stat_map{'size'}] < $_[1]->[$stat_map{'size'}] }, @_);
}
sub smallest {
    return shift->_cmp_stat(0, sub { $_[0]->[$stat_map{'size'}] >= $_[1]->[$stat_map{'size'}] }, @_);
}

=head1 INTERNALS

Call/use at your own risk ;-)

=head2 _construct_filename()

Accepts one or more arguments. It passes them to C<<File::Spec->catfile()>>
dereferencing the array if one argument array ref is passed.

Example:

    _construct_filename('file')               => 'file'
    _construct_filename([ 'folder', 'file' ]) => File::Spec->catfile('folder', 'file');
    _construct_filename('folder', 'file')     => File::Spec->catfile('folder', 'file');

This function is called on every argument passed to comparision methods
(newer, smaller, older, ...).

=cut

sub _construct_filename {
    croak 'need at least one argument'
        if @_ == 0;
    
    return File::Spec->catfile(@{$_[0]})
        if (@_ == 1) and (ref $_[0] eq 'ARRAY');
    
    return File::Spec->catfile(@_);
}


=head2 _cmp_stat($class, $return_value_if_match, $cmp_function, $primary_filename, $other_filename, $other_filename2, ...)

This function is called by all of the public C<newer()>, C<smaller()>, C<older()>,
... methods do loop through files and do some comparism on them.

=cut

sub _cmp_stat {
    my $class    = shift;
    my $return   = shift;
    my $cmp_func = shift;
    my $file1 = _construct_filename(shift);
    my @files = @_;
    
    my @file1_stat = stat($file1);
    croak 'file "'.$file1.'" not reachable'
        if not @file1_stat;

    foreach my $file (@files) {
        $file = _construct_filename($file);
        my @file_stat = stat($file);
        croak 'file "'.$file.'" not reachable'
            if not @file_stat;
        
        # return success if condition is met
        return $return
            if $cmp_func->(\@file1_stat, \@file_stat);
    }
    
    # no file was newer
    return not $return;
}

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-is at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-is>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::is


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-is>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-is>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-is>

=item * Search CPAN

L<http://search.cpan.org/dist/File-is>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

'sleeeeeeeeeeep';
