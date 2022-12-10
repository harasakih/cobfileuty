#!/usr/bin/perl

#!/usr/bin/perl
# $ : scalar
# @ : array
# % : hash
#
use strict;
# use warnings;
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
use File::Basename 'basename', 'dirname';
use Getopt::Long 'GetOptions';
use Encode 'decode', 'encode' ;

my $dirname = File::Basename::dirname $0;
require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------

sub	test_num2spd {
	my	$errmsg;
##
	print "-- num2spd --\n";
	print "success\n";
	print "min-pdketa,odd\n";
	print ":" . &cobfile::num2spd(\$errmsg, "1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "+1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "-1", 1) . ":$errmsg:\n";
	print "min-pdketa,even\n";
	print ":" . &cobfile::num2spd(\$errmsg, "1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "+1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "-1", 2) . ":$errmsg:\n";
	print "error\n";
	print "keta-over\n";
	print ":" . &cobfile::num2spd(\$errmsg, "12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "+12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "-12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "+123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "-123", 2) . ":$errmsg:\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2spd(\$errmsg, "+12", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "++1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2spd(\$errmsg, "--1", 2) . ":$errmsg:\n";
}

sub	test_num2upd {
	my	$errmsg;
##
	print "-- num2upd --\n";
	print "success\n";
	print "min-pdketa,odd\n";
	print ":" . &cobfile::num2upd(\$errmsg, "1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+1", 1) . ":$errmsg:\n";
	print "min-pdketa,even\n";
	print ":" . &cobfile::num2upd(\$errmsg, "1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+1", 2) . ":$errmsg:\n";
	print "zeropapd\n";
	print ":" . &cobfile::num2upd(\$errmsg, "1", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+1", 3) . ":$errmsg:\n";
	print "error\n";
	print "minus-sign\n";
	print ":" . &cobfile::num2upd(\$errmsg, "-1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "-1", 2) . ":$errmsg:\n";
	print "keta-over\n";
	print ":" . &cobfile::num2upd(\$errmsg, "12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "-12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "-123", 2) . ":$errmsg:\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2upd(\$errmsg, "123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "+123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "++1", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2upd(\$errmsg, "--1", 3) . ":$errmsg:\n";
}

sub	test_num2szd {
	my	$errmsg;
##
	print "-- num2szd --\n";
	print "success\n";
	print "min-zdketa,odd\n";
	print ":" . &cobfile::num2szd(\$errmsg, "1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-1", 1) . ":$errmsg:\n";
	print "min-zdketa,even\n";
	print ":" . &cobfile::num2szd(\$errmsg, "1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-1", 2) . ":$errmsg:\n";
	print "zeropad\n";
	print ":" . &cobfile::num2szd(\$errmsg, "1", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+1", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-1", 3) . ":$errmsg:\n";
	print "error\n";
	print "keta-over\n";
	print ":" . &cobfile::num2szd(\$errmsg, "12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-123", 2) . ":$errmsg:\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2szd(\$errmsg, "123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "+123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "-123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "++12", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2szd(\$errmsg, "--12", 3) . ":$errmsg:\n";

}

sub	test_num2uzd {
	my	$errmsg;
##
	print "-- num2uzd --\n";
	print "success\n";
	print "min-zdketa,odd\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+1", 1) . ":$errmsg:\n";
	print "min-zdketa,even\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+1", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "1", 2) . ":$errmsg:\n";
	print "zeropad\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+1", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "1", 3) . ":$errmsg:\n";
	print "error\n";
	print "minus-sign\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "-1", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "-1", 2) . ":$errmsg:\n";
	print "keta-over\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "-12", 1) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "-123", 2) . ":$errmsg:\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+123", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "++12", 3) . ":$errmsg:\n";
	print ":" . &cobfile::num2uzd(\$errmsg, "+-12", 3) . ":$errmsg:\n";
}

sub	test_num2bl {
	my	$ll;
	my	$errmsg;

	print "-- num2bl --\n";
	print "success\n";
	print ":" . &cobfile::num2bl(\$errmsg, "1",  1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-1", 1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "2",  1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-2", 1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "1",  2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-1", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "2",  2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-2", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "1",  4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-1", 4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "2",  4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-2", 4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "1",  8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-1", 8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-2", 8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "2",  8) 				. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::num2bl(\$errmsg, "0", 3) 					. ":$errmsg\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2bl(\$errmsg, "++0", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bl(\$errmsg, "-+0", 2) 				. ":$errmsg\n";

}
sub	test_num2bb {
	my	$ll;
	my	$errmsg;

	print "-- num2bb --\n";
	print "success\n";
	print ":" . &cobfile::num2bb(\$errmsg, "1",  1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-1", 1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-2", 1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "2",  1) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "1",  2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-1", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-2", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "2",  2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "1",  4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-1", 4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-2", 4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "2",  4) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "1",  8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-1", 8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-2", 8) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "2",  8) 				. ":$errmsg\n";
	print "error\n";
	print ":" . &cobfile::num2bl(\$errmsg, "0", 3) 					. ":$errmsg\n";
	print "not-numeric\n";
	print ":" . &cobfile::num2bb(\$errmsg, "++0", 2) 				. ":$errmsg\n";
	print ":" . &cobfile::num2bb(\$errmsg, "-+0", 2) 				. ":$errmsg\n";
}


	&test_num2spd;
	&test_num2upd;
	&test_num2szd;
	&test_num2uzd;
	&test_num2bl;
	&test_num2bb;

1; # TRUE