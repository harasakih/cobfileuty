#!/usr/bin/perl

#!/usr/bin/perl
# $ : scalar
# @ : array
# % : hash
#
use strict;
# use warnings;
# use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use File::Basename 'basename', 'dirname';
use Getopt::Long 'GetOptions';
use Encode 'decode', 'encode' ;

my $dirname = File::Basename::dirname $0;
# require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------



my	$Big16bit_us	=	'n';	# 符号なし１６ビット
my	$Big32bit_us	=	'N';	# 符号なし３２ビット
my	$Little16bit_us	=	'v';	# 符号なし１６ビット
my	$Little32bit_us	=	'V';	# 符号なし１６ビット
## Perl内部形式(LittleEndian)からのUNPACK
my	$pkupk_S8bit	= "c";	my	$pkupk_U8bit	= "C";
my	$pkupk_S16bit	= "s";	my	$pkupk_U16bit	= "S";
my	$pkupk_S32bit	= "l";	my	$pkupk_U32bit	= "L";
my	$pkupk_S64bit	= "q";	my	$pkupk_U64bit	= "Q";

	my	($hexval1, $hexval2);
	my	($sjis, $utf8, $plchar);
## OK 8341 -> ア
	$hexval1	= pack($Big16bit_us, 0x8341);					print "SJIS:" . $hexval1 . "\n";		# 81400a 
	$plchar		= decode('cp932', $hexval1);					print "PLCHAR:" . $plchar . "\n";
	$utf8		= encode('utf8', decode('cp932', $hexval1));	print "UTF8:" . $utf8 . "\n";
	print "----\n";
## OK 8343 -> イ
	$hexval1	= pack("H*", "8343");							print "SJIS:" . $hexval1 . "\n";		# 81400a 
	$plchar		= decode('cp932', $hexval1);					print "PLCHAR:" . $plchar . "\n";
	$utf8		= encode('utf8', decode('cp932', $hexval1));	print "UTF8:" . $utf8 . "\n";
	print "----\n";

1; #