#!/usr/bin/perl
#
use strict;
use warnings;
no warnings 'once';
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換aする
use File::Basename 'basename', 'dirname';

my $dirname = File::Basename::dirname $0;
require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------
sub	test_hexedit_rep {

	my	$record = '';
	my	$ret;


	print "success\n";
	$record	=	"00010203040506070809";							print ">:$record\n";
	$ret	=	&cobfile::hexedit_rep(\$record,  0, 1, "10");	print "$ret:$record\n"; print "\n";

	$record	=	"00010203040506070809";							print ">:$record\n";
	$ret	=	&cobfile::hexedit_rep(\$record,  4, 2, "4455");	print "$ret:$record\n"; print "\n";

	$record	=	"00010203040506070809";							print ">:$record\n";
	$ret	=	&cobfile::hexedit_rep(\$record,  9, 1, "90");	print "$ret:$record\n"; print "\n";

	$record	=	"00010203040506070809";							print ">:$record\n";
	$ret	=	&cobfile::hexedit_rep(\$record,  0, 10, "112233445566778899AA");	
		print "$ret:$record\n"; print "\n";

	print "error\n";
	$record	=	"00010203040506070809";							print ">:$record\n";

	$ret	=	&cobfile::hexedit_rep(\$record,  -1, 1, "1234");	print "$ret:$record\n"; 
	$ret	=	&cobfile::hexedit_rep(\$record,  0, -1, "1234");	print "$ret:$record\n"; 
	$ret	=	&cobfile::hexedit_rep(\$record,  0, 1, "1");		print "$ret:$record\n"; 
	$ret	=	&cobfile::hexedit_rep(\$record,  0, 1, "123");		print "$ret:$record\n"; 
	$ret	=	&cobfile::hexedit_rep(\$record,  0, 1, "0H");		print "$ret:$record\n"; 

	$ret	=	&cobfile::hexedit_rep(\$record,  0, 11, "10");		print "$ret:$record\n"; 
	$ret	=	&cobfile::hexedit_rep(\$record,  9,  2, "0000");	print "$ret:$record\n"; 

	$ret	=	&cobfile::hexedit_rep(\$record,  0,  2, "123");		print "$ret:$record\n"; 

}

	&cobfile::setLoglevel($cobfile::Msglevel{'ERR'});
	&test_hexedit_rep;
1; #