#!/usr/bin/perl

#!/usr/bin/perl
# $ : scalar
# @ : array
# % : hash
#
use strict;
# use warnings;
# use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
use File::Basename 'basename', 'dirname';
use Getopt::Long 'GetOptions';
use Encode 'decode', 'encode' ;

my $dirname = File::Basename::dirname $0;
require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------


sub	test_pd2num {
	my	$ll;
	my	$errmsg;

	print "-- pd2num --\n";
	print "success\n";
	print ":" . &cobfile::pd2num(\$errmsg, "1C") 		. ":$errmsg\n";
	print ":" . &cobfile::pd2num(\$errmsg, "123D") 		. ":$errmsg\n";
	print ":" . &cobfile::pd2num(\$errmsg, "12345F") 	. ":$errmsg\n";
	print ":" . &cobfile::pd2num(\$errmsg, "001C") 		. ":$errmsg\n";
	print ":" . &cobfile::pd2num(\$errmsg, "012D") 		. ":$errmsg\n";
	print ":" . &cobfile::pd2num(\$errmsg, "00123F") 	. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::pd2num(\$errmsg, "01") 		. ":$errmsg\n";	# no-sign
	print ":" . &cobfile::pd2num(\$errmsg, "F1") 		. ":$errmsg\n";	# not numeric
	print ":" . &cobfile::pd2num(\$errmsg, "123E") 		. ":$errmsg\n";	# sign
	print ":" . &cobfile::pd2num(\$errmsg, "1234F") 	. ":$errmsg\n";	# not-even

}

sub	test_zd2num {
	my	$ll;
	my	$errmsg;

	print "-- zd2num --\n";
	print "success\n";
	print ":" . &cobfile::zd2num(\$errmsg, "+1") 		. ":$errmsg\n";
	print ":" . &cobfile::zd2num(\$errmsg, "31+1") 		. ":$errmsg\n";
	print ":" . &cobfile::zd2num(\$errmsg, "32-2") 		. ":$errmsg\n";
	print ":" . &cobfile::zd2num(\$errmsg, "33@3") 		. ":$errmsg\n";
	print ":" . &cobfile::zd2num(\$errmsg, "3132@3") 	. ":$errmsg\n";
	print ":" . &cobfile::zd2num(\$errmsg, "3031-2") 	. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::zd2num(\$errmsg, "31") 		. ":$errmsg\n";	# not sign
	print ":" . &cobfile::zd2num(\$errmsg, "31A1") 		. ":$errmsg\n";	# not sign
	print ":" . &cobfile::zd2num(\$errmsg, "+A") 		. ":$errmsg\n";	# not numeric
	print ":" . &cobfile::zd2num(\$errmsg, "3A+1") 		. ":$errmsg\n";	# not numeric
	print ":" . &cobfile::zd2num(\$errmsg, "1") 		. ":$errmsg\n";	# not even
	print ":" . &cobfile::zd2num(\$errmsg, "313") 		. ":$errmsg\n";	# not even

}

sub	test_bl2num {
	my	$ll;
	my	$errmsg;

	print "-- bl2num --\n";
	print "success\n";
	print ":" . &cobfile::bl2num(\$errmsg, "01") 					. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "0102") 					. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "01020304") 				. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "0102030405060708") 		. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "FF") 					. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "FFFF") 					. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "FFFFFFFF") 				. ":$errmsg\n";
	print ":" . &cobfile::bl2num(\$errmsg, "FFFFFFFFFFFFFFFF") 		. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::bl2num(\$errmsg, "0") 		. ":$errmsg\n";

}
sub	test_bb2num {
	my	$ll;
	my	$errmsg;

	print "-- bb2num --\n";
	print "success\n";
	print ":" . &cobfile::bb2num(\$errmsg, "01") 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, 01) 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "1234") 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, 1234) 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "04030201") 				. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "0807060504030201") 		. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "FF") 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "FFFF") 					. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "FFFFFFFF") 				. ":$errmsg\n";
	print ":" . &cobfile::bb2num(\$errmsg, "FFFFFFFFFFFFFFFF") 		. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::bb2num(\$errmsg, "0") 		. ":$errmsg\n";

}


sub test_bb {
	my	$num;
	my	$hex;
	my	$bb;
	my	$bl;
	my	$errmsg;

	print "-- binary --\n";
	$hex = "1020" ;
		$num = &cobfile::bb2num(\$errmsg, $hex);
		$bb	 = &cobfile::num2bb(\$errmsg, $num, 4);
		$bl  = &cobfile::num2bl(\$errmsg, $num, 4);
		print "HEX(BB):$hex -> BB:$bb,BL:$bl, NUM:$num \n";
	$hex = "2010" ;
		$num = &cobfile::bl2num(\$errmsg, $hex);
		$bb	 = &cobfile::num2bb(\$errmsg, $num, 4);
		$bl  = &cobfile::num2bl(\$errmsg, $num, 4);
		print "HEX(BL):$hex -> BB:$bb,BL:$bl, NUM:$num \n";
	$num = -1;
		$bb	 = &cobfile::num2bb(\$errmsg, $num, 4);
		$bl  = &cobfile::num2bl(\$errmsg, $num, 4);
		print "NUM:$num -> BB:$bb,BL:$bl \n";
	$num = -2;
		$bb	 = &cobfile::num2bb(\$errmsg, $num, 4);
		$bl  = &cobfile::num2bl(\$errmsg, $num, 4);
		print "NUM:$num -> BB:$bb,BL:$bl \n";

}

	&test_pd2num;
	&test_zd2num;
	&test_bl2num;
	&test_bb2num;
	&test_bb;

1; # TRUE
