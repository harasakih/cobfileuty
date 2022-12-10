#!/usr/bin/perl

#!/usr/bin/perl
# $ : scalar
# @ : array
# % : hash
#
use strict;
# use warnings;
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換aする
use File::Basename 'basename', 'dirname';
use Getopt::Long 'GetOptions';
use Encode 'decode', 'encode' ;

my $dirname = File::Basename::dirname $0;
require "$dirname/cobfile.pl" ;

# -------------------------------------
package	main;
# -------------------------------------

sub	test_char2xx_tosjishex { ## OK
	my	$errmsg;
##
	print "-- char2xx_tosjishex --\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "0123", 4) . ":$errmsg:\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "ABC" , 3) . ":$errmsg:\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "ｱｲｳ",  3) . ":$errmsg:\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "、。", 4) . ":$errmsg:\n";
	print "error\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "　", 3) . ":$errmsg:\n";
	print ":" . &cobfile::char2xx_tosjishex(\$errmsg, "0123", 3) . ":$errmsg:\n";
}

sub	test_hex2xx { ## OK
	my	$errmsg;
##
	print "-- hex2xx --\n";
	print "success\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "01",   1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "0123", 2) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "&HAF", 1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "&H01AF", 2) . ":$errmsg:\n";
	print "error\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "012", 1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "&HA", 1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "&H", 1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, " ", 1) . ":$errmsg:\n";
	print ":" . &cobfile::hex2xx(\$errmsg, "ｱｲｳ", 4) . ":$errmsg:\n";
}

sub	test_sjistxt { ## OK
	my	$Infile = Fctrl->new();			# $Infileはリファレンス型として定義されている

## OUTPUT
	my	$Otfile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	$Otfile->fname( '' );
	$Otfile->recfm( 'T' );
	$Otfile->decenc('utf8');
	&cobfile::openToutput( $Otfile);

	my	$inrec;
	my	$ll;
	my	$errmsg;

	print "-- sjistxt(readT,cp932,char2xx) --\n";
	$Infile->fname( 'sjis.txt' );
	$Infile->recfm( 'T' );
	$Infile->lrecl( '' );
	$Infile->decenc('cp932');
	&cobfile::openTinput( $Infile) || die;
	while( ($ll = &cobfile::readTrec($Infile, \$inrec)) != $cobfile::EOF ) {	# cp932で読み込みHEXSTR
		print "$ll:char2xx_tosjishex:$inrec:>:"   . &cobfile::char2xx_tosjishex(\$errmsg, $inrec, 0) . ":$errmsg\n";
	}
	&cobfile::closeAny($Infile);


	print "-- utf8txt(readT,utf8,char2xx) --\n";
	$Infile->fname( 'utf8.txt' );
	$Infile->recfm( 'T' );
	$Infile->lrecl( '' );
	$Infile->decenc('utf8');
	&cobfile::openTinput( $Infile) || die;
	while( ($ll = &cobfile::readTrec($Infile, \$inrec)) != $cobfile::EOF ) {	# utf8で読み込みHEXSTR
		print "$ll:char2xx_toutf8hex:$inrec:>:"   . &cobfile::char2xx_toutf8hex(\$errmsg, $inrec, 0) . ":$errmsg\n";
	}
	&cobfile::closeAny($Infile);

	print "-- sjistxt(readB,lrecl=6) --\n";
	$Infile->fname( 'sjis.txt' );
	$Infile->recfm( 'F' );
	$Infile->lrecl( '6' );
	$Infile->decenc('');
	&cobfile::openBinput( $Infile) || die "$!";
	while( ($ll = &cobfile::readBrec($Infile, \$inrec)) != $cobfile::EOF ) {	# バイナリ読み込み
		print "$ll:inrec:"   . $inrec . ":$errmsg\n";
	}
	&cobfile::closeAny($Infile);

	print "-- sjistxt(readBinary,lrecl=4) --\n";
	$Infile->fname( 'sjis_lrecl4.txt' );
	$Infile->recfm( 'F' );
	$Infile->lrecl( '4' );
	$Infile->decenc('');
	&cobfile::openBinput($Infile) || die "$!";
	my $fh = $Infile->fh;
	my $lrecl = $Infile->lrecl;
	while( read $fh, my $bindata, $lrecl ) {
		print ":read:" . $bindata . ":$errmsg:" . unpack("H*", $bindata) . "\n";
		
	}
	&cobfile::closeAny($Infile);

	&cobfile::closeAny($Otfile);

}

	&test_char2xx_tosjishex ;
	&test_hex2xx ;
	&test_sjistxt ;
	
1 ; # TRUE