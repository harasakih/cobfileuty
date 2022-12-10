#!/usr/bin/perl

#!/usr/bin/perl
# $ : scalar
# @ : array
# % : hash
#
use strict;
# use warnings;
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
use Encode;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use File::Basename 'basename', 'dirname';
use Getopt::Long 'GetOptions';
use Encode 'decode', 'encode' ;

my $dirname = File::Basename::dirname $0;
require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------
&cobfile::setLoglevel($cobfile::Msglevel{'ERR'});


sub	test_xx2char1 { ## OK
	my	$ll;
	my	$errmsg;
#
#	use utf8 : 日本語OK
#	utf8 no  : 日本語文字化け
#
	print "-- xx2char[ HEXSTR to pl内部文字形式 ] --\n";	# use utf8:文字化けなし、no-utf8 文字化けあり
	print "success\n";
	print "、:" . &cobfile::xx2char(\$errmsg, 8141, 'cp932', '') 			. ":$errmsg\n";	# 、
	print "。:" . &cobfile::xx2char(\$errmsg, "8142", 'cp932', '') 		. ":$errmsg\n";	# 。
	print "、。:" . &cobfile::xx2char(\$errmsg, "81418142", 'cp932', '') 	. ":$errmsg\n";	# 、。
	print "AB:" . &cobfile::xx2char(\$errmsg, "4142", 'cp932', '') 		. ":$errmsg\n";	# AB
	print "ab:" . &cobfile::xx2char(\$errmsg, "6162", 'cp932', '') 		. ":$errmsg\n";	# ab
	print ".[:" . &cobfile::xx2char(\$errmsg, "A1A2", 'cp932', '') 		. ":$errmsg\n";	# .[
	print "ｱｲ:" . &cobfile::xx2char(\$errmsg, "B1B2", 'cp932', '') 		. ":$errmsg\n";	# ｱｲ

}
sub	test_xx2char {	##  OK HEXSTRをSJIS文字コードで解釈し、該当するunicode文字(perl内部)に変換する
	my	$ll;
	my	$errmsg;
#
	print "-- xx2char[ HEXSTR to pl内部文字形式 ] --\n";	# use utf8:文字化けなし、no-utf8 文字化けあり
	print "success\n";
	print ":" . &cobfile::xx2char_fromsjishex(\$errmsg, "8341") 			. ":$errmsg\n";	# 、
	print ":" . &cobfile::xx2char_fromsjishex(\$errmsg, "81418142") 		. ":$errmsg\n";	# 、。
	print ":" . &cobfile::xx2char(\$errmsg, "B1B2", 'cp932', '')		. ":$errmsg\n";	# ｱｲ
	print ":" . &cobfile::xx2char(\$errmsg, "B1B2", 'cp932', 'unicode')	. ":$errmsg\n";	# ｱｲ
	if( &cobfile::xx2char(\$errmsg, "8341",'cp932', '') eq "ア") {
		printf("8341 == ア\n");  # use utf8 の時　
	} else {
		printf("8341 <> ア\n");  # no utf8 の時「ア」が文字化け
	}

}

sub	test_char2xx {  ## OK perlの文字列（内部コード）を、HEXSTRに変換する
	my	$ll;
	my	$errmsg;
	my	($sjischar, $sjishex, $status);
	my	($plchar, $buf);
	print "-- char2xx [ 文字 to SJISHEXSTR ] --\n";	
	$plchar	=	"ア";
	$buf	= $plchar;
	$status = Encode::from_to($buf, 'unicode', 'shiftjis') ;
	$sjischar	=	$buf;
	$sjishex	=	unpack("H*", $sjischar);
	print "$plchar:SJISHEX:$sjishex\n" ;

}

sub	test_char2xx_xx2char { ## OK perlの文字列（内部コード）を、SJIS/UTF8の文字コードHEXSTRに変換する
	my	$errmsg;
	my	($plchar, $hex, $sjischar, $utf8char);
	my	($sjishex, $utf8hex);

	$plchar = "ｱｲ";
	print "-- char2xx[$plchar] -- \n";
	$sjishex	= &cobfile::char2xx_tosjishex(\$errmsg, $plchar, 0);
	print "sjisHEX:" . $sjishex . ":". $errmsg . ":\n";
	$utf8hex	= &cobfile::char2xx_toutf8hex(\$errmsg, $plchar,0);
	print "utf8HEX:" . $utf8hex . ":". $errmsg . ":\n";
#
	$sjischar	= &cobfile::xx2char_fromsjishex(\$errmsg, $sjishex);
	print "Fromsjis:" . $sjischar . ":". $errmsg . ":\n";
	$utf8char	= &cobfile::xx2char_fromutf8hex(\$errmsg, $utf8hex);
	print "Fromutf8:" . $utf8char . ":". $errmsg . ":\n";
#
	print "SJIS:$plchar:$sjishex:$sjischar\n";
	print "UTF8:$plchar:$utf8hex:$utf8char\n";

	$plchar = "アイ";
	print "-- char2xx[$plchar] -- \n";
	$sjishex	= &cobfile::char2xx_tosjishex(\$errmsg, $plchar, 0);
	print "sjisHEX:" . $sjishex . ":". $errmsg . ":\n";
	$utf8hex	= &cobfile::char2xx_toutf8hex(\$errmsg, $plchar,0);
	print "utf8HEX:" . $utf8hex . ":". $errmsg . ":\n";
#
	$sjischar	= &cobfile::xx2char_fromsjishex(\$errmsg, $sjishex);
	print "Fromsjis:" . $sjischar . ":". $errmsg . ":\n";
	$utf8char	= &cobfile::xx2char_fromutf8hex(\$errmsg, $utf8hex);
	print "Fromutf8:" . $utf8char . ":". $errmsg . ":\n";
#
	print "SJIS:$plchar:$sjishex:$sjischar\n";
	print "UTF8:$plchar:$utf8hex:$utf8char\n";

}

sub	test_xx2char_char2xx {  ## OK SJIS/UTF8の文字コードHEXSTRを、perlの文字列（内部コード）に変換する
	my	$errmsg;
	my	($plchar, $hex, $sjischar, $utf8char);
	my	($sjishex, $utf8hex);

	$sjishex	= "B1B2"; 	# ｱｲ
	print "-- xx2char,SJIS[$sjishex] -- \n";
	$sjischar	= &cobfile::xx2char_fromsjishex(\$errmsg, $sjishex);
	print "SJIS:" . $sjishex . ">" . $sjischar . ":". $errmsg . ":\n";

	$sjishex	= "83418343"; 	# ｱｲ
	print "-- xx2char,SJIS[$sjishex] -- \n";
	$sjischar	= &cobfile::xx2char_fromsjishex(\$errmsg, $sjishex);
	print "SJIS:" . $sjishex . ">" . $sjischar . ":". $errmsg . ":\n";

	$utf8hex	= "EFBDB1EFBDB2"; 	# ｱｲ
	print "-- xx2char,UTF8[$utf8hex] -- \n";
	$utf8char	= &cobfile::xx2char_fromutf8hex(\$errmsg, $utf8hex);
	print "UTF8:" . $utf8hex . ">" . $utf8char . ":". $errmsg . ":\n";

	$utf8hex	= "E382A2E382A4"; 	# ｱｲ
	print "-- xx2char,UTF8[$utf8hex] -- \n";
	$utf8char	= &cobfile::xx2char_fromutf8hex(\$errmsg, $utf8hex);
	print "UTF8:" . $utf8hex . ">" . $utf8char . ":". $errmsg . ":\n";


}


#	test_xx2char1;
#	test_xx2char;
#	test_char2xx;

	&test_char2xx_xx2char;
	&test_xx2char_char2xx;

1; # TRUE