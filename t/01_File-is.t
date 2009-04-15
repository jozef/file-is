#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 19;
use Test::Differences;
use Test::Exception;

use File::Temp 'tempdir';
use File::Path 'mkpath';

BEGIN {
    use_ok ( 'File::is' ) or exit;
}

exit main();

sub main {
	# test _construct_filename()
	dies_ok { File::is::_construct_filename(); } 'die when no arg to _construct_filename()';
	is(
		File::is::_construct_filename('file'),
		'file',
		'_construct_filename() with one argument'
	);
	is(
		File::is::_construct_filename('folder', 'subfolder', 'file'),
		File::Spec->catfile('folder', 'subfolder', 'file'),
		'_construct_filename() with more argument'
	);
	is(
		File::is::_construct_filename([ 'folder', 'subfolder', 'file' ]),
		File::Spec->catfile('folder', 'subfolder', 'file'),
		'_construct_filename() with array ref argument'
	);
	
	# setup three files in different folders
	my $tfolder = tempdir( CLEANUP => 1 );
	my $tfolder1 = File::Spec->catdir($tfolder, 'sub', 'sub');
	mkpath($tfolder1);
	my $tfolder2 = File::Spec->catdir($tfolder, 'sub1', 'sub2');
	mkpath($tfolder2);
	my $tfolder3 = File::Spec->catdir($tfolder, 'sub3', 'sub4');
	mkpath($tfolder3);
	my $fn1 = File::Spec->catfile($tfolder1, 'f1');
	my $fn2 = File::Spec->catfile($tfolder2, 'f2');
	my $fn3 = File::Spec->catfile($tfolder3, 'f3');
	diag 'three files ('.$fn1.', '.$fn2.', '.$fn3.')';
	open my $fh1, '>', $fn1;
	open my $fh2, '>', $fn2;
	open my $fh3, '>', $fn3;
	
	# test newer
	ok(!File::is->newer($fn1, $fn2, $fn3), 'file1 was created as first cannot be newer');
	utime time(), time()-5, $fn1;
	utime time(), time()-10, $fn2;
	ok(!File::is->newer($fn1, $fn3), 'file1 still not never then file3');
	ok(!File::is->newer($fn1, [ $tfolder, 'sub3', 'sub4', 'f3' ]), 'file1 still not never then file3');
	ok(File::is->newer($fn1, $fn2), 'but newer than file2 ( time()-10 )');
	ok(File::is->newer([ $tfolder, 'sub', 'sub', '..', 'sub', 'f1' ], [ $tfolder, 'sub1', 'sub2', 'f2' ]), 'but newer than file2 ( time()-10 )');
	
	# test newest
	ok(File::is->newest($fn3, $fn2, $fn1), 'file2 is newset of them');
	ok(!File::is->newest($fn2, $fn1, $fn3), 'file3 is NOT newset of them');
	ok(!File::is->newest($fn1, $fn3, $fn2), 'file1 is NOT newset of them');

	# test older
	ok(File::is->older($fn2, $fn1), 'file2 is older then file1');
	ok(!File::is->older($fn3, $fn1), 'file3 not older than file1');

	# test oldest
	ok(File::is->oldest($fn2, $fn1, $fn3), 'file2 is oldest of them');
	ok(!File::is->oldest($fn3, $fn1, $fn2), 'file3 is NOT oldest of them');
	ok(!File::is->oldest($fn1, $fn3, $fn2), 'file1 is NOT oldest of them');

	# test die
	dies_ok { File::is->older($fn2, 'non-existing' ) } 'die with non existing file';
	
	return 0;
}

