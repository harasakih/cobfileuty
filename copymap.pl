#!/usr/bin/perl
# $ : scalar / @ : array / % : hash
#
use strict;
use warnings;
use Encode 'decode', 'encode' ;
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use Getopt::Long 'GetOptions';
use File::Basename 'basename', 'dirname';

# -------------------------------------
package	main;
# -------------------------------------
my	$myname	= File::Basename::basename $0;

#############################
# Profiles
#############################
our $version        = "00.01";
our $revision       = "20221127" ;
our $description    = "COPYBOOK to cobfileuty.";
#
#############################
# Public vals
#############################
my  $Loglevel   = 3;    # output loglevel
# LOG-LEVEL-TAG 0-7
our	@Msgtag = ("ALL", "CRI", "ERR", "WRN", "INF", "DBG", "FNC", "LV7");
our	%Msglevel = (ALL => 0, CRI => 1, ERR => 2, WRN => 3, INF => 4, DBG => 5, FNC => 6, LV7 => 7 ) ;
#### Msglevel毎の出力基準
##         処理継続
##  ALL 0  o
##  CRI 1  x       即時,dieする                ERR 2  x       ABENDする
##  WRN 3  o       エラー発生するが、処理継続     INF 4  o       主要な通過点
##  DBG 5  o       主にエラーの詳細             FNC 6  o       無条件にMSGを出力
my	$gInf_fh;
my	$gOtf_fh;
my	$gInf_dec = 'cp932';

#############################
# CONSTANT
#############################
our	$TRUE	=	1;
our	$FALSE	=	0;
our	$EOF	=	-1;
our	%Errcd	=	(NUM => 'ERR(NUM)', KETA => 'ERR(KET)', HEX => 'ERR(HEX)', FILE => 'ERR(FILE)',
	ZOKUSEI => 'ERR(ZOK)'
);

# --------------------------------------------------------------
# functions as bellow
# --------------------------------------------------------------
## set/get
sub getProfile  { return ($version, $revision, $description); }
sub setLoglevel { return ($Loglevel = $_[0]); }
sub getLoglevel { return $Loglevel; }

# --------------------------------------------------------------
# METHOD        : TRUE : usage($msg)
# DESCRIPTION   : usage
# PARAM
#  i:$msg		: Special-MSG
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	usage {
	my	($msg)	=	@_;

	my $basename	= File::Basename::basename $0;
	if(defined($msg)) { print STDOUT "$msg\n"; }
	print STDOUT "usage: $basename --inf=INFILE --otf=OTFILE \n";
	print STDOUT "\n";
	print STDOUT "optional\n";
	print STDOUT "  --otf   STDOUT or FILENAME\n";
	print STDOUT "  --logl  CRI|ERR|WRN|INF|DBG|FNC\n";
	return	$TRUE;
}

# --------------------------------------------------------------
# METHOD        : TRUE|die : optck($usagemsg)
# DESCRIPTION   : option check
# PARAM
#  i:$usagemsg	: Special-MSG
# REURN
#  R OK/NG
# --------------------------------------------------------------
# Options
our	%gOpts	=	();
GetOptions(	\%gOpts,
  'inf=s' , 
  'otf=s' ,
  'logl=s' ,
  'help'
);
our	$gOpt_inf ;
our	$gOpt_otf ;
our	$gOpt_logl ;
our	$gOpt_help ;
#
sub	optck {
	my	($usagemsg)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$err = 0;
	my	$bk_logl	=	&getLoglevel;
	if( defined(my $logl = $gOpts{'logl'}) ) {	&setLoglevel($Msglevel{$logl}); }
	while( my ($key, $val) = each(%gOpts)) {
		if($key eq 'help')		{$gOpt_help = $val;}
		elsif($key eq 'inf')	{$gOpt_inf = $val;}
		elsif($key eq 'otf')	{$gOpt_otf = $val;}
		elsif($key eq 'logl') 	{$gOpt_logl = $val;}
		else {;}
		&dbglog($Msglevel{'INF'}, "$myname,OPT:$key:$val")
	}
	&setLoglevel($bk_logl);
#######################################
# HELP
#######################################
	if($gOpt_help) {
		&usage($usagemsg);
		return $FALSE;
	}
#######################################
# 単項目CK : 必須＆値 or 任意
#######################################
## $gOpt_inf ; 必須
	if(! defined($gOpt_inf)) {		&dbglog($Msglevel{'ERR'}, "$myname,$Errcd{FILE}:no inf:");					$err += 1;}
	elsif($gOpt_inf ne '' && -f $gOpt_inf) { ; }
	else {							&dbglog($Msglevel{'ERR'}, "$myname,$Errcd{FILE}:inf no-file or null:$gOpt_inf");	$err += 1;}
## $gOpt_otf ; 任意、未設定はSTDOUT出力にするので、チェックしない
	if(defined($gOpt_otf)) { 
		if(-f $gOpt_otf) {			&dbglog($Msglevel{'ERR'}, ("$myname,$Errcd{FILE}:otf exist:$gOpt_otf"));		$err += 1;}
	} else {
		$gOpt_otf	=	''; 
	}
#######################################
# RETURN : 単項目チェックエラーの時
#######################################
	if($err > 0) {
		&dbglog($Msglevel{'ALL'}, ("---- $0 ABEND(optck) ----"));
		die "!!DIE $!" ;
	} else {
		;
	}
#######################################
# RETURN
#######################################
	if($err > 0) {
		&dbglog($Msglevel{'ALL'}, ("---- $0 ABEND(optck) ----"));
		die "!!DIE $!" ;
	} else {
		return $TRUE;
	}
} # optck

# --------------------------------------------------------------
# METHOD        : TRUE : dbglog($msglevel,@msg)
# DESCRIPTION   : if($msglevel < $LogLevel) print STDERR
# PARAM
#  i:$msglevel	: $Msglevel{'ERR'}
#  i:@msg		: MSG to print STDERR
# REURN
#  R OK/NG
# --------------------------------------------------------------
##
# [Wide charracter]は、内部文字列のutf8フラグと操作が矛盾している時に出力される
# 対策として　① utf8オンならば、decodeしない、② utf8オフならば、utf8でデコードして、 内部コードに変換する
# そして、内部コードをutf8にエンコードして出力する
##
sub	dbglog {
	my	($msglevel, @msg)	=	@_;
#
    my ($package_name, $file_name, $line) = caller;
    if($msglevel eq "") {
        die "!!DIE msglevel($msglevel) is null, $package_name,$file_name,$line:$!";
    }

    ($msglevel > 7 || $msglevel < 0) && die "!!DIE msglevel invalid:$msglevel:$!";
    if($msglevel <= $Loglevel) {
        foreach my $msg(@msg) {
			if($msglevel eq $Msglevel{'ALL'}) {
	            printf STDERR ("!!%s::%s\n", $Msgtag[$msglevel], $msg);
			} else {
	            printf STDERR ("!!%s:%s,%s:%s\n", $Msgtag[$msglevel], ($file_name,$line),$msg);
			}
        }
    }
    return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : STR : gettype($zokusei)
# DESCRIPTION   : $zokkusei to TYPE(PD|ZD|CH|XX|,,)
# PARAM
#  i:$zokusei	: 
# REURN
#  TYPE
# --------------------------------------------------------------
my	%zk2type	= (
	GROUP_F		=> 'XX',
	ALPHANUM	=> 'CH',
	INT_DEC		=> 'PD',
	EXT_DEC		=> 'ZD',
	STD_BINARY	=> 'XX',
	BINARY		=> 'XX',
	POINTER		=> 'XX',
	NATIONAL	=> 'CH',
	NUM_EDIT	=> 'CH',
	FLOAT_S		=> 'XX',
	FLOAT_L 	=> 'XX'
);
sub	gettype {
	my	($heni,$nagasa,$zokusei,$meihyo,$jigen)	=	@_;

	my	$ret;
	$zokusei	=~	tr/[\-]/_/;
	if(defined( $zk2type{ $zokusei })) {
		my $type	=	$zk2type{ $zokusei };
		$ret	=	sprintf("[%s,%s,'%s','%s'] ,", $heni, $nagasa, $type, $meihyo) ;

		if($zokusei eq 'GROUP_F')	{$ret .= " # I am GROUP-F";	}
		if($jigen ne '') 			{$ret .= " # I have OCCURS"; }
		return	$ret;
	} else {
		&dbglog($Msglevel{'ERR'}, ("$myname,$Errcd{ZOKUSEI}:err unknown zokusei:$zokusei"));
		$ret	=	sprintf("[%s,%s,'%s','%s'] ,", $heni, $nagasa, '*', $meihyo) ;
		return	$ret;
	}
}

# -------------------------------------
#	MAIN
# -------------------------------------
# OPTION CHECK
	if( &optck("copymap") != $TRUE ) {
		exit 1;
	}; 

	my	$addmsg	= "[";
	$addmsg .= 	"logl=" . $Msgtag[&getLoglevel()] . "";
	$addmsg	.=	"]";
	&dbglog($Msglevel{'ALL'}, ("---- $0 START $addmsg ----"));

## --otf省略、STDOUTは、fnameに空白を設定
	if(! defined($gOpt_otf))		{	$gOpt_otf = ''; }
	elsif( $gOpt_otf eq 'STDOUT')	{	$gOpt_otf = ''; } 
	else { ; }

#######################################
# OPEN
#######################################
	if( open $gInf_fh, "<:encoding($gInf_dec)", $gOpt_inf  ) { ; }
	else { 
		&dbglog($Msglevel{'ERR'}, ("$myname,$Errcd{FILE}:open:$gOpt_inf"));
		die "!!DIE $myname:,open error:$!";
	}
	if($gOpt_otf eq ''){ ; }
	else {
		if( open $gOtf_fh, ">", $gOpt_otf ) { ; }
		else {
			&dbglog($Msglevel{"ERR"}, "$myname,$Errcd{FILE}:open:$gOpt_otf");
			die "!!DIE $myname,open error:$!";
		}
	}

#######################################
# LOOP
#######################################
	my	$flg_map	= 0;
	while( my $line = <$gInf_fh> ) {
		chomp($line);										# 改行コードLFを削除
		if(substr($line, length($line) - 1, 1) eq "\r") {	# CRがあれば削除
			chop($line);
		}
		if($flg_map == 0 && $line =~ /行番号.*番地.*変位.*レベル.*名標.*長さ/) {
			$flg_map	= 1;
			next;
		}
		if($flg_map == 1 && $line !~ /^\s*$/) {
			my	@ar		= split(/\s+/, $line);
			my	$nar	= @ar;
			if($nar	>= 10) {
				my ($lno, $address, $heni, $level, $meihyo, $nagasa, $zokusei, $kiten, $heni2) = 
					($ar[1], $ar[2],$ar[3],$ar[4],$ar[5],$ar[6],$ar[7],$ar[8],$ar[9]) ;
				my	$jigen = '';
				if($nar	>= 11) {	$jigen = ($ar[10]) ; } 
				else {				$jigen = '';  }
# COPYMAP情報の判定
				if($lno =~ /^[0-9\-]+$/ && $heni =~ /^[0-9]+$/ && $nagasa =~ /^[0-9]+$/) { ; } 
				else {	next; }												# COPYMAP情報以外は読み飛ばし 

				$lno	=~	tr/[\-]/_/;
				my	$name	=	"L$lno";
				my	$buf	=	&gettype( $heni,$nagasa,$zokusei,$meihyo,$jigen );
# 出力
				if($gOpt_otf eq ''){ 
					if($zokusei eq 'GROUP-F'){
						printf STDOUT "# $name => $buf \n", ;
					} else {
						printf STDOUT "$name => $buf \n", ;
					}
				} else {
					my $buf2  = &encode('utf8', $buf);
					if($zokusei eq 'GROUP-F'){
						printf $gOtf_fh "# $name => $buf2 \n", ;
					} else {
						printf $gOtf_fh "$name => $buf2 \n", ;
					}
				}
			}
		}
	}

#######################################
# CLOSE
#######################################
	if( close $gInf_fh ) { ; }
	else {
		&dbglog($Msglevel{'ERR'}, ("$myname,$Errcd{FILE}:close:$gOpt_inf"));
		die "!!DIE $myname,close error:$!";
	}
	if( $gOpt_otf eq '' ) { ; }
	else {
		if( close $gOtf_fh ) { ; }
		else{
			&dbglog($Msglevel{'ERR'}, ("$myname,$Errcd{FILE}:close:$gOpt_otf"));
			die "!!DIE $myname,close error:$!";
		}
	}
	&dbglog($Msglevel{'ALL'}, ("---- $0 NORMAL-END ----"));

# ---------------------------------------------------
#	EXIT-PACKAGE
# ---------------------------------------------------
1 ; # TRUE
