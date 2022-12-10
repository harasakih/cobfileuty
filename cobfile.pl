#!/usr/bin/perl
#               access    		clear		SETVAL
# $ : scalar	$var			$val=0,"'		**
# @ : array		$array[]		@array=()	@array=(a,b,c,,)
# % : hash		$hash{'key'}	%hash=()	%hash=(key => val,,)
#
# 関数名(PKG名付)			$myname	= (caller 0)[3];
# 呼び元の関数名(PKG名付)	$callername = (caller 1)[3];
#									

## TODO
## DONE	$errmsgの初期化を追加、依頼時のMSGをそのまま戻していた（char2xx, hex2xx）

# -------------------------------------
package	cobfile;
# -------------------------------------
use strict;
use warnings;
use Encode 'decode', 'encode' ;
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use Getopt::Long 'GetOptions';
use File::Basename 'basename', 'dirname';
# use Encode;
## add perl-lib, samepath of this script
# use FindBin;
# use lib "$FindBin::Bin";
#############################
# use my perl
#############################
{
    my  $dirname0 = dirname $0;
#    require "$dirname0" . "/Common.const.pl" ;
}

#############################
# Export function, vals
#############################
use Exporter 'import';
#############################
## export only functions, exporting vals cause unexpected result
## if you want to accecc vals from outside of package,use get/set
#############################
## export, from Dgblog and our functions
our @EXPORT_OK = qw/dbglog getProfile setLoglevel getLoglevel/ ;
#############################
# Profiles
#############################
our $version        = "00.01";
our $revision       = "20221112" ;
our $description    = "COBFILE functions.";
#
#############################
# Public vals
#############################
my  $Loglevel   = 2;    # output loglevel
# LOG-LEVEL-TAG 0-7
## require 'thisfile' でも参照できるように、 our で定義する
our	@Msgtag = ("ALL", "CRI", "ERR", "WRN", "INF", "DBG", "FNC", "LV7");
our	%Msglevel = (ALL => 0, CRI => 1, ERR => 2, WRN => 3, INF => 4, DBG => 5, FNC => 6, LV7 => 7 ) ;
#### Msglevel毎の出力基準
##         処理継続
##  ALL 0  o
##  CRI 1  x       即時,dieする
##  ERR 2  x       ABENDする
##  WRN 3  o       エラー発生するが、処理継続
##  INF 4  o       主要な通過点
##  DBG 5  o       主にエラーの詳細
##  FNC 6  o       無条件にMSGを出力
## require file
our	$Reqfile	= '';
#
our	%Errcd	=	(NUM => 'ERR(NUM)', KET => 'ERR(KET)', HEX => 'ERR(HEX)');

#############################
# CONSTANT
#############################
## our : require 'thisfile' でも参照可能
## my  : require 'thisfile' では参照不可
our	$TRUE	=	1;
our	$FALSE	=	0;
our	$EOF	=	-1;
our	$Big16bit_us	=	'n';	# 符号なし１６ビット
our	$Big32bit_us	=	'N';	# 符号なし３２ビット
our	$Little16bit_us	=	'v';	# 符号なし１６ビット
our	$Little32bit_us	=	'V';	# 符号なし１６ビット
## Perl内部形式(LittleEndian)からのUNPACK
our	$pkupk_S8bit	= "c";	our	$pkupk_U8bit	= "C";
our	$pkupk_S16bit	= "s";	our	$pkupk_U16bit	= "S";
our	$pkupk_S32bit	= "l";	our	$pkupk_U32bit	= "L";
our	$pkupk_S64bit	= "q";	our	$pkupk_U64bit	= "Q";
## COBOL PACK,ZONEの符号キャラ
our	$PackSignPlus	= 	'C';	# num2xpdの符号部、pd2numの符号チェック
our	$PackSignMinus	=	'D';
our	$PackSignAbs	=	'F';
our	$ZoneSignPlus	= 	'+';	# num2xzdの符号部、zd2numの符号チェック
our	$ZoneSignMinus	=	'-';
our	$ZoneSignAbs	=	'@';	
our	$ZoneUpHalfPad	=	'3';	# num2xzdの中間部上４ビット
##
our	$HanSP_hex		=	'20';	# char2xx のパディング
#
#############################
# Struct
#############################
use	Class::Struct ;
struct	Fctrl => {
	fname	=> '$',		# ファイル名
	recfm	=> '$',		# F|V|T
	lrecl	=> '$',		# recfm=F:レコード長さ recfm=V:無効 recfm=T:無効
	isopened	=> '$',	# オープンされているか
	iocnt	=> '$',		# 入出力件数
	decenc	=> '$',		# ファイルのデコード（入力時）、エンコード（出力時）
	fh		=> '$'		# File Handle
} ;
#############################
# SHARED only package
#############################
# 
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
	print STDOUT "usage: $basename --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] \n";
	print STDOUT "usage: $basename --recfm=V --inf=INFILE [--otf=OTFILE] \n";
	print STDOUT "\n";
	print STDOUT "optional\n";
	print STDOUT "for common\n";
	print STDOUT "  --otf   STDOUT or filename\n";
	print STDOUT "  --logl  CRI|ERR|WRN|INF|DBG|FNC\n";
	print STDOUT "for hexdpM.pl\n";
	print STDOUT "  --dmp   lst|hexstr\n";
	print STDOUT "for hexeditM.pl,hexfmtM.pl\n";
	print STDOUT "  --edit  edit|fmtpr\n";
	print STDOUT "  --req   subfile_name for edit,fmtpr\n";
	print STDOUT "  --iferr null|hex. if num-err return null or &H+HEXSTR\n";
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
  'recfm=s' ,
  'lrecl=i'	,
  'inf=s' , 
  'otf=s' ,
  'dmp=s' ,
  'edit=s' ,
  'logl=s' ,
  'req=s' ,
  'iferr=s' ,
  'pad=s' ,
  'help'
);
our	$gOpt_help ;
our	$gOpt_recfm ;
our	$gOpt_lrecl ;
our	$gOpt_inf ;
our	$gOpt_otf ;
our	$gOpt_dmp ;
our	$gOpt_edit ;
our	$gOpt_logl ;
our	$gOpt_req ;
our	$gOpt_iferr ;
our	$gOpt_pad ;
#
sub	optck { my	($usagemsg)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$err = 0;
	my	$bk_logl	=	&getLoglevel;
	if( defined(my $logl = $gOpts{'logl'}) ) {	&setLoglevel($Msglevel{$logl}); }
	while( my ($key, $val) = each(%gOpts)) {
		if($key eq 'help')		{$gOpt_help = $val;}
		elsif($key eq 'recfm')	{$gOpt_recfm = $val;}
		elsif($key eq 'lrecl')	{$gOpt_lrecl = $val;}
		elsif($key eq 'inf')	{$gOpt_inf = $val;}
		elsif($key eq 'otf')	{$gOpt_otf = $val;}
		elsif($key eq 'dmp')	{$gOpt_dmp = $val;}
		elsif($key eq 'edit')	{$gOpt_edit = $val;}
		elsif($key eq 'logl') 	{$gOpt_logl = $val;}
		elsif($key eq 'req') 	{$gOpt_req = $val;}
		elsif($key eq 'iferr') 	{$gOpt_iferr = $val;}
		elsif($key eq 'pad') 	{$gOpt_pad = $val;}
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
## $gOpt_recfm ; 必須
	if(! defined($gOpt_recfm)) {	&dbglog($Msglevel{'ERR'}, "$myname,no recfm:");				$err += 1;}
	elsif( $gOpt_recfm =~ /^[FV]$/ ) { ; }
	else {							&dbglog($Msglevel{'ERR'}, "$myname,err recfm:$gOpt_recfm");	$err += 1; }
## $gOpt_inf ; 必須
	if(! defined($gOpt_inf)) {		&dbglog($Msglevel{'ERR'}, "$myname,no inf:");				$err += 1;}
	elsif($gOpt_inf ne '') { ; }
	else {							&dbglog($Msglevel{'ERR'}, "$myname,null inf:$gOpt_inf");	$err += 1;}
## $gOpt_otf ; 任意、未設定はSTDOUT出力にするので、チェックしない
## $gOpt_dmp ; 任意、未設定時[lst]
	if(! defined($gOpt_dmp)) { $gOpt_dmp	= "lst"; }
	if($gOpt_dmp eq "lst" || $gOpt_dmp eq "hexstr") { ; } 
	else {							&dbglog($Msglevel{'ERR'}, "$myname,dmp must lst|hexstr:$gOpt_dmp");		$err += 1;}
## $gOpt_dmp ; 任意、未設定時['']
	if(! defined($gOpt_edit)) { $gOpt_edit	= ''; }
	if($gOpt_edit eq "edit" || $gOpt_edit eq "fmtpr" || $gOpt_edit eq '') { ; } 
	else { 							&dbglog($Msglevel{'ERR'}, "$myname,edit must edit|fmtpr:$gOpt_edit");	$err += 1;}
## $gOpt_logl ; 任意、未設定時[$Loglevelのレベル]・設定時は値チェック
	if(! defined($gOpt_logl)) {	$gOpt_logl	= $Msgtag[getLoglevel()]; }
	if(defined $Msglevel{$gOpt_logl}) {	&setLoglevel($Msglevel{$gOpt_logl}); } 
	else {							&dbglog($Msglevel{'ERR'}, "$myname,err logl:$gOpt_logl");				$err += 1;}
## $gOpt_req ; 任意、未設定時['']・設定時ファイルチェック
	if(defined($gOpt_req)) { 
		if(! -f $gOpt_req) {		&dbglog($Msglevel{'ERR'}, ("$myname,req no file:$gOpt_req"));			$err += 1;}
		$Reqfile	=	$gOpt_req;
	} else {
		$Reqfile	=	''; 
	}
## $gOpt_iferr ; 任意、未設定時['']
	if(! defined($gOpt_iferr)) { $gOpt_iferr = ''; }
	if($gOpt_iferr eq "null" || $gOpt_iferr eq "hex" || $gOpt_iferr eq '') { ; } 
	else {							&dbglog($Msglevel{'ERR'}, "$myname,err iferr:$gOpt_iferr");				$err += 1;}
## $gOpt_pad ; 任意、未設定時['']
	if(! defined($gOpt_pad)) { $gOpt_pad = ''; }
	if($gOpt_pad eq '' || $gOpt_pad =~ /^[0-9a-fA-F]{2}$/ ) { ; } 
	else {							&dbglog($Msglevel{'ERR'}, "$myname,err pad:$gOpt_pad");				$err += 1;}
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
# 相関CK : recfm=F & lrecl<>null, recfm=V & lrecl==null
#######################################
	if($gOpt_recfm eq 'F') {
		if($gOpt_lrecl =~ /^[0-9]+$/) { ; }
		else {	&dbglog($Msglevel{'ERR'}, "$myname,err lrecl:$gOpt_recfm,$gOpt_lrecl");			$err += 1; 	}
	} elsif($gOpt_recfm eq 'V') {
		if(! defined($gOpt_lrecl) || $gOpt_lrecl eq '') { ; }
		else{ 	&dbglog($Msglevel{'ERR'}, "$myname,lrecl not null:$gOpt_recfm,$gOpt_lrecl");	$err += 1; 	}
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
# METHOD        : TRUE|FALSE : hexedit($Infile, $Otfile, $output)
# DESCRIPTION   : Framework for [init,editrec,term]. editrecで出力有無を判定し、バイナリファイルに出力orPRINTする。OPEN-CLOSEをする
# PARAM
#  i:$Infile	: 構造体Fctrl（リファレンス）
#  i:$Otfile	: 構造体Fctrl（リファレンス）
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	hexedit {
	my	($Infile, $Otfile)	=	@_;

	my	$myname	= (caller 0)[3];
## START-MSG
#	my	$editmode = defined($gOpt_edit) ? $gOpt_edit : '';
	my	$editmode = $gOpt_edit;
	my	$addmsg	= "[";
	$addmsg .= 	"logl=" . $Msgtag[&getLoglevel()] . ",";
	$addmsg	.=	"edit=" . $editmode . ",";
	$addmsg .= 	"iferr=" . $gOpt_iferr . ",";
	$addmsg	.=	"req=" . $Reqfile . "";
	$addmsg	.=	"]";
	&dbglog($Msglevel{'ALL'}, ("---- $0,$myname START $addmsg ----"));
# -----------------------------------------------------------------------
	if(&hexedit::init_pre($Infile, $Otfile) != $TRUE) { die "$myname,init_pre returns FALSE:$!"; }
# -----------------------------------------------------------------------
## OPEN-INPUT
	if(&openBinput($Infile)) { ; } else { die "!!DIE $!"; }
## OPEN-OUTPUT
	my	$otrecfm	= $Otfile->recfm;
	if($otrecfm =~ /^[FV]$/)	{ &openBoutput($Otfile) || die "!!DIE $!"; }
	elsif($otrecfm eq 'T') 		{ &openToutput($Otfile) || die "!!DIE $!"; }
	else {
		&dbglog($Msglevel{'ERR'}, "$myname,err ot_recfm:$otrecfm");
		die "!!DIE $!"; 
	}
# -----------------------------------------------------------------------
	if(&hexedit::init_aft($Infile, $Otfile) != $TRUE) { die "$myname,init_aft returns FALSE:$!"; }
# -----------------------------------------------------------------------
## READ-LOOP
	my	$inhex;
	my	$othex;
	while((my $ll = &readBrec($Infile, \$inhex)) != $EOF ) {
# -----------------------------------------------------------------------
		if( &hexedit::record_exit($Infile, $Otfile, $inhex, \$othex) == $EOF ){ last; };
# -----------------------------------------------------------------------
	}
# -----------------------------------------------------------------------
	if(&hexedit::term_pre($Infile, $Otfile) != $TRUE) { die "$myname,term_pre returns FALSE:$!"; }
# -----------------------------------------------------------------------
## CLOSE-INPUT
	if( &closeAny( $Infile ) == $TRUE ) { 
		my	$iocnt	=	$Infile->iocnt;
		my	$fname	=	$Infile->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	 } else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close infile");
		return $FALSE;
	}
## CLOSE-OUTPUT
	if( &closeAny( $Otfile ) == $TRUE ) {
		my	$iocnt	=	$Otfile->iocnt;
		my	$fname	=	$Otfile->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close otfile");
		return $FALSE;
	}
# -----------------------------------------------------------------------
	if(&hexedit::term_aft($Infile, $Otfile) != $TRUE) { die "$myname,term_aft returns FALSE:$!"; }
# -----------------------------------------------------------------------
## END-MSG
	&dbglog($Msglevel{'ALL'}, ("---- $0 NORMAL-END ----"));
	return	$TRUE;

}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : hexedit_rep(\$record,$st,$len,$hexstr)
# DESCRIPTION   : substr(\$record,$st,$len)を、$hexstrで置き換える
# PARAM
#  o:record		: ref to HEXSTR
#  i:st			: Start positon, BTYE
#  i:len		: Length, BYTE
#  i:hexstr		: HEXSTR to replace
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	hexedit_rep	{
	my	($record, $st, $len, $hexstr)	=	@_;

	my	$myname	= (caller 0)[3];
	my	$bk_record	= $$record;
## 単項目
# 正値
	if($st < 0 || $len < 0) {
		&dbglog($Msglevel{'WRN'}, "$myname,negative value($st,$len,$hexstr)");	return	$FALSE; }
# HEXSTRの長さは偶数
	if((length($hexstr) % 2) != 0) {
		&dbglog($Msglevel{'WRN'}, "$myname,length of hexstr not even($st,$len,$hexstr)");	return	$FALSE; }
# HEXSTRは１６進数
	if($hexstr =~ /^[0-9A-Fa-f]+$/) { ; }
	else {
		&dbglog($Msglevel{'WRN'}, "$myname,not HEXSTR($st,$len,$hexstr)");	return	$FALSE; }

## 相関チェック
	my	$llrec	=	length($$record);
	my	$llhex	=	length($hexstr);
# ST!RECORD  変換開始(st)はllrec以内
	if(($st * 2) < $llrec) { ; }				# 0*2 < 2(X'01') -- OK / 1*2 > 2(X'01') -- NG
	else {
		&dbglog($Msglevel{'WRN'}, "$myname,start exceed record($st,$len,$llrec)");	return	$FALSE; }
# LEN!RECORD  変換終了(st+ll)はlrecl以内  
	if((($st + $len)* 2) <= $llrec) { ; }		# (0 + 1)*2 <= 2(X'01') -- OK / (0 + 2)*2 <= 2(X'0102') -- NG
	else {
		&dbglog($Msglevel{'WRN'}, "$myname,start + length exceed record($st,$len,$llrec)");	return	$FALSE; }
# LEN!HEXSTR  変換対象とHEXSTRの長さ一致
	if(($len * 2) != length($hexstr))	{
		&dbglog($Msglevel{'WRN'}, "$myname,len ne length of hexstr($st,$len,$hexstr)");	return	$FALSE; }

# -------------------------------
# 置換実行
# -------------------------------
	my	$left;
	my	$mid;
	my	$right;
# LEFT
	if($st != 0) {	$left	=	substr($$record, 0, ($st * 2)); } 
	else {			$left	=	''; }
# MIDDLE
	$mid	=	substr($$record, ($st * 2), ($len * 2)) ; 
# RIGHT
	if($llrec - ($st * 2 + $len * 2) != 0) {
		$right	=	substr($$record, ($st * 2 + $len * 2), $llrec - ($st * 2 + $len * 2)) ;
	} else {
		$right	=	'';
	}

	$$record = $left . $hexstr . $right;
	&dbglog($Msglevel{'FNC'}, "$myname:ST:$st,LL:$len,HX:$hexstr",
		"  $bk_record",
		"->$$record"
	);
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : perlval : getitem(\$ref, \$errmsg, $hexstr, $st, $len, $type, $midashi, $enc)
# DESCRIPTION   : getitem2のラッパー。$midashiを除く
# --------------------------------------------------------------
sub	getitem {
	my	($ref, $errmsg, $hexstr, $st, $len, $type, $midashi, $enc)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$item	= &getitem2($ref, $errmsg, $hexstr, $st, $len, $type, $enc);
	if($gOpt_edit eq 'fmtpr' && $gOpt_iferr eq 'hex' && $$errmsg ne ''){
		$item	= "&H" . substr($hexstr, $st*2, $len*2);
	} else { ; }
	&dbglog($Msglevel{'FNC'}, "$myname,get[$item]from",
		"ST:$st,LL:$len,TY:$type,MD:$midashi,ENC:$enc",
		"$hexstr"
	);
	return	$item;
}

# --------------------------------------------------------------
# METHOD        : perlval : getitem2(\$ref, \$errmsg, $hexstr, $st, $len, $type, $enc)
# DESCRIPTION   : hexstr,[st,len]をtype属性に変換したperlvalを返却する。'CH' は$ref->decencでデコードし、$encでエンコードする
# DESC-SUB		: PD -> pd2num / ZD -> zd2num / CH -> xx2char / XX -> bin2xx 
# PARAM
#  i:\$ref		: 構造体Fctrl（リファレンス）
#  o:\$errmsg	: この処理で検知したエラーMSG（リファレンス）
#  i:$hexstr	: 変換対象の HEXSTR
#  i:$st		: 取得する項目のバイト位置（バイナリファイルの開始位置）
#  i:$len		: 取得する項目のバイト長さ
#  i:$type		: 属性 PD|ZD|CH|XX
#  i:$midashi	: 項目見出し※未使用
# REURN
#  R perlval
# --------------------------------------------------------------
sub	getitem2 {
	my	($ref, $errmsg, $hexstr, $st, $len, $type, $enc)	=	@_;
	my	$ret;

	my	$myname	= (caller 0)[3];
#
	if(! defined($enc)) { $enc = ''; }
	&dbglog($Msglevel{'FNC'}, "$myname,ST:$st,LL:$len,TY:$type,ENC:$enc",
		">$hexstr"
	);

	my	$myerrmsg = '';
	if($type eq 'PD') 		{
		$ret = &pd2num(\$myerrmsg, substr($hexstr, $st*2, $len*2));
	 } elsif($type eq 'ZD')	{ 
		$ret = &zd2num(\$myerrmsg, substr($hexstr, $st*2, $len*2));
	} elsif($type eq 'CH')	{ 
		my	$decode	= $ref->decenc;
		if(! defined($enc)) { $enc = '';}	# 省略はエンコードなし（perl内部コードにエンコード）
		$ret = &xx2char(\$myerrmsg, substr($hexstr, $st*2, $len*2), $decode, $enc);
	} elsif($type eq 'XX')	{ 
		$ret = substr($hexstr, $st*2, $len*2);
	} else { ; }

	if($myerrmsg ne '' ) {	&dbglog($Msglevel{'WRN'}, "$myname,$myerrmsg"); }
	&dbglog($Msglevel{'FNC'}, 
		"<$ret"
	);
	$$errmsg = $myerrmsg;
	return $ret;
} # getitem2

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : setDCB(\$ref,$fname,$recfm,$lrecl,$decenc)
# DESCRIPTION   : ファイル構造体にDCBを設定する。
# PARAM
#  i:\$ref		: 構造体Fctrl（リファレンス）
#  i:$fname		: ファイル名
#  i:$recfm		: F|V|T
#  i:$lrecl		: レコード長
#  i:$decenc	: 文字コード
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	setDCB {
	my	($ref, $fname, $recfm, $lrecl, $decenc)	=	@_;
	if(defined($fname))	{ $ref->fname($fname);}
	if(defined($recfm)) { $ref->recfm($recfm);}
	if(defined($lrecl)) { $ref->lrecl($lrecl);}
	if(defined($decenc)){ $ref->decenc($decenc);}
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : @array : getDCB(\$ref)
# DESCRIPTION   : ファイル構造体からDCBを返却する
# PARAM
#  i:\$ref		: 構造体Fctrl（リファレンス）
# REURN
#  R ($fname,$recfm,$lrecl,$decenc)
# --------------------------------------------------------------
sub	getDCB {
	my	($ref)	=	@_;

	my	($fname, $recfm, $lrecl, $decenc);
	if($ref->fname) { $fname = $ref->fname; }
	if($ref->recfm) { $recfm = $ref->recfm; }
	if($ref->lrecl) { $lrecl = $ref->lrecl; }
	if($ref->decenc){ $decenc = $ref->decenc;}
	return ($fname, $recfm, $lrecl, $decenc);
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : openBinput(\$ref)
# DESCRIPTION   : ファイルを <raw でオープンする
# PARAM
#  i:$ref		: 構造体Fctrl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	openBinput {
	my	($ref)	=	@_;

	my	$myname	= (caller 0)[3];
# fname
	my	$fname	=	$ref->fname;
	if(! -e $fname) {
		&dbglog($Msglevel{"ERR"}, "$myname,no file:$fname");
		return $FALSE;
	}
# recfm
	my	$recfm	=	$ref->recfm;
	if($recfm =~ /^[FV]$/) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm:$recfm");
		return $FALSE;
	}
# lrecl
	my	$lrecl	=	$ref->lrecl;
	if($recfm eq 'V' || ($recfm eq 'F' && $lrecl =~ /^[0-9]+$/)) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm,lrecl:$recfm,$lrecl");
		return $FALSE;
	}
# OPEN
	if( open my $fh, "<:raw", $fname  ) {
		binmode $fh;
		$ref->isopened( $TRUE );
		$ref->iocnt( 0 );
		$ref->fh( $fh );
		return $TRUE;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,cannot open:$fname");
		return $FALSE;
	}
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : openTinput(\$ref)
# DESCRIPTION   : ファイルを <encoding() でオープンする
# PARAM
#  i:\$ref		: 構造体Fctrl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	openTinput {
	my	($ref)	=	@_;

	my	$myname	= (caller 0)[3];
# fname
	my	$fname	=	$ref->fname;
	if(! -e $fname) {
		&dbglog($Msglevel{"ERR"}, "$myname,no file:$fname");
		return $FALSE;
	}
# recfm
	my	$recfm	=	$ref->recfm;
	if($recfm =~ /^[T]$/) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,recfm must T:$recfm");
		return $FALSE;
	}
# OPEN(Tinput)
	my	$dec	=	$ref->decenc;
	if($dec eq '') {
		&dbglog($Msglevel{"ERR"}, "$myname,decenc is null:$dec");
		return $FALSE;
	}
	if( open my $fh, "<:encoding($dec)", $fname  ) {
		$ref->isopened( $TRUE );
		$ref->iocnt( 0 );
		$ref->fh( $fh );
		return $TRUE;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,cannot open:$fname");
		return $FALSE;
	}
	return $TRUE;
} # OpenTinput

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : openBoutput(\$ref)
# DESCRIPTION   : ファイルを >(encodeなし) でオープンする
# DESC-SUB		: $ref->fname eq '' はSTDOUT出力なので、OPENしない
# PARAM
#  i:\$ref		: 構造体Fctrl
# REURN
#  R OK/NG
# BUG
#  標準出力への対応が魅了(ref openToutput)
# --------------------------------------------------------------
sub	openBoutput {
	my	($ref)	=	@_;

	my	$myname	= (caller 0)[3];
# fname
	my	$fname	=	$ref->fname;
	if(-e $fname) {
		&dbglog($Msglevel{"ERR"}, "$myname,file exist:$fname");
		return $FALSE;
	}
# recfm
	my	$recfm	=	$ref->recfm;
	if($recfm =~ /^[FV]$/) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm:$recfm");
		return $FALSE;
	}
# lrecl
	my	$lrecl	=	$ref->lrecl;
	if($recfm eq 'V' || ($recfm eq 'F' && $lrecl =~ /^[0-9]+$/)) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm,lrecl:$recfm,$lrecl");
		return $FALSE;
	}
# OPEN(Boutput)
	if( $fname eq '') {
		$ref->isopened( $TRUE );
		$ref->iocnt( 0 );
		;
	} else {
		if( open my $fh, ">", $fname  ) {
			binmode $fh;
			$ref->isopened( $TRUE );
			$ref->iocnt( 0 );
			$ref->fh( $fh );
			return $TRUE;
		} else {
			&dbglog($Msglevel{"ERR"}, "$myname,cannot open:$fname");
			return $FALSE;
		}
	}
	return $TRUE;
} # OpenBoutput

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : openToutput(\$ref)
# DESCRIPTION   : ファイルを >encoding() でオープンする
# DESC-SUB		: $ref->fname eq '' はSTDOUT出力なので、OPENしない
# PARAM
#  i:\$ref		: 構造体Fctrl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	openToutput {
	my	($ref)	=	@_;

	my	$myname	= (caller 0)[3];
# fname
	my	$fname	=	$ref->fname;
	if($fname ne '' && -e $fname) {
		&dbglog($Msglevel{"ERR"}, "$myname,file exist:$fname");
		return $FALSE;
	}
# recfm
	my	$recfm	=	$ref->recfm;
	if($recfm =~ /^[T]$/) {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,recfm must T:$recfm");
		return $FALSE;
	}
# OPEN(Toutput)
	if( $fname eq '') {
		$ref->isopened( $TRUE );
		$ref->iocnt( 0 );
		;
	} else {
		my	$enc	=	$ref->decenc;
		if($enc eq '') {
			&dbglog($Msglevel{"ERR"}, "$myname,decenc is null:$enc");
			return $FALSE;
		}
		if( open my $fh, ">:encoding($enc)", $fname  ) {
			$ref->isopened( $TRUE );
			$ref->iocnt( 0 );
			$ref->fh( $fh );
			return $TRUE;
		} else {
			&dbglog($Msglevel{"ERR"}, "$myname,cannot open:$fname");
			return $FALSE;
		}
	}
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : closeAny(\$ref)
# DESCRIPTION   : ファイルをクローズする
# DESC-SUB		: $ref->fname eq '' はSTDOUT出力なので、CLOSEしない
# PARAM
#  i:\$ref		: 構造体Fctrl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	closeAny {
	my	($ref)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$fh		=	$ref->fh;
	my	$fname	=	$ref->fname;

	if( $fname eq '' ) { 
		$ref->isopened( $FALSE );
		return $TRUE;
	} 
	if( close $fh ) {
		$ref->isopened( $FALSE );
		return $TRUE;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,cannot close:$fname");
		return $FALSE;
	}
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : EOF(-1)|読み込んだ長さ : readTrec(\$ref, \$rec)
# DESCRIPTION   : ファイルから改行区切りで１レコードを読みこんで、リファレンス\$recに格納
# DESC-SUB		: $$recは、$ref->decencでデコードされたPERL内部コードで格納されいている
# PARAM
#  i:\$ref		: 構造体Fctrl（リファレンス）
#  o:\$rec		: レコードを格納するリファレンス。 $$rec = 'xxx' で値を格納
# REURN
#  R 読み込んだバイト数。エラー時は$EOF
# BUGS
#  返却値は、バイト数ではなく「文字数」になっている。length()が文字数返却のため
# --------------------------------------------------------------
sub	readTrec {
	my	($ref, $rec)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$fname	=	$ref->fname;
	my	$fh		=	$ref->fh;
	my	$recfm	=	$ref->recfm;

	if( $recfm eq 'T') {
		;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm:$recfm($fname)");
		return $EOF;
	}
## READ
	if(defined(my $line = <$fh>)){
		chomp($line);										# 改行コードLFを削除
		if(substr($line, length($line) - 1, 1) eq "\r") {	# CRがあれば削除
			chop($line);
		}
		$$rec	=	$line;
## IOCNT
		my	$wk	=	$ref->iocnt;
		$wk++;
		$ref->iocnt( $wk );						# IOCNTをインクリメント
## LRECL & RETURN
		my	$lrecl	=	length($line);
		return	$lrecl;							# 読み込みバイド数をRETURN
	} else {
		return	$EOF;
	}
	&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR:$recfm($fname)");
	return $FALSE;
}

# --------------------------------------------------------------
# METHOD        : EOF(-1)|読み込んだ長さ : readBrec(\$ref, \$rec)
# DESCRIPTION   : ファイルから改行区切りで１レコードを読みこんで、HEXSTRに変換しリファレンス\$recに格納
# PARAM
#  i:\$ref		: 構造体Fctrl
#  o:\$rec		: HEXSTRを格納するリファレンス。 $$rec = 'xxx' で値を格納
# REURN
#  R 読み込んだバイト数。エラー時は$EOF
# --------------------------------------------------------------
sub	readBrec {
	my	($ref, $rec)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$fname	=	$ref->fname;
	my	$fh		=	$ref->fh;
	my	$recfm	=	$ref->recfm;

## 固定長READ
	if($recfm eq 'F') {
		my	$lrecl	=	$ref->lrecl;
		my	$hexval;
		my	$hexstr	=	'';
## レコード
		my	$ret	= read $fh, $hexval, $lrecl;	# ファイルをlreclバイトREAD
		if(defined($ret)) {
			$hexstr	= unpack("H*", $hexval);		# InternalVal to hex-str(dump)
			$hexstr	=~	tr/a-f/A-F/;
			if($ret == 0) {					# EOF検知
				$$rec	=	$hexstr;		#   recにHEX文字列を設定して
				return $EOF;}				#   EOFをリターン
			elsif($ret > 0) {				# 正常READ
				;
			}
		} else {
			&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR:$recfm($fname)");
			return $EOF;
		}
		$lrecl	=	length($hexval);				# lreclは読み込んだバイト数
		$$rec	=	$hexstr;						# HEX文字列を編集して
		my	$wk	=	$ref->iocnt;
		$wk++;
		$ref->iocnt( $wk );							# IOCNTをインクリメント
		return	$lrecl;								# 読み込みバイド数をRETURN
## 可変長READ
	} elsif($recfm eq 'V') {
## 先頭RDW
		my	$lrecl1 = &readRdw($fh, $Little16bit_us);
		if($lrecl1 == $EOF) { return $EOF; }
## レコード
		my	$hexval;
		my	$hexstr;
		my	$ret;

		if($lrecl1 != 0) {
			$ret	= read $fh, $hexval, $lrecl1;		# レコードz
			if(defined($ret)) {							# 正常にREADできた時
				$hexstr	= unpack("H*", $hexval);		# InternalVal lto HEXSTR
				$hexstr	=~	tr/a-f/A-F/;
				if($ret == 0) {						# EOF検知
					$$rec	=	$hexstr;			#	$recにHEXSTRを設定し
					return	$EOF;					#	EOFをリターン			
				} elsif($ret > 0) {					# 正常READの時
					;
				}
			} else {
				&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR:$recfm($fname)");
				return $EOF;
			}	
			$$rec	=	$hexstr;
		} else {
			$$rec	=	'';
		}
## 後続RDW
		my	$lrecl2	= &readRdw($fh, $Little16bit_us);
		if($lrecl2 == $EOF) { return $EOF};

		my	$wk	=	$ref->iocnt;
		$wk++;
		$ref->iocnt( $wk );						# IOCNTをインクリメント
		return	$lrecl1;						# 読み込みバイド数をRETURN
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,err recfm:$recfm($fname)");
		return $EOF;
	}
	&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR:$recfm($fname)");
	return $FALSE;
}

# --------------------------------------------------------------
# METHOD        : EOF|$lrecl : readRdw($filehandle,$rdw_type)
# DESCRIPTION   : COBOL可変調のRDW４バイトを読み込む
# PARAM
#  i:$filehandle: Filehandle to be readed.
#  i:$rdw_type	: RDWのエンディアン、unpackのパラメタに設定
# REURN
#  R COBOL可変調のLRECL。エラー時は$EOF
# --------------------------------------------------------------
sub	readRdw {
	my	($fh, $rdw_type)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$hexval;
	my	$ret;
	my	$rdw;
	$ret = read $fh, $hexval, 2;					# 先頭RDW
	if(defined($ret)) {								# 正常にREADできた時
		if($ret == 0) {								# EOF検知
			return	$EOF;
		} elsif($ret > 0) {							# 正常READの時
			$rdw	= unpack($rdw_type, $hexval);	# RDWのendianでアンパック
		}
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR()");
		return $EOF;
	}	

	my	$lowval;
	$ret = read $fh, $hexval, 2;					# 先頭LOWVAL
	if(defined($ret)) {								# 正常にREADできた時
		if($ret == 0) {								# EOF検知
			return	$EOF;
		} elsif($ret > 0) {							# 正常READの時
			$lowval	= unpack($rdw_type, $hexval);	# RDWのendianでアンパック
		}
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,IO-ERR()");
		return $EOF;
	}	

	my	$hex_rdw	= sprintf("%04X", $rdw);
	my	$hex_low	= sprintf("%04X", $lowval);
	&dbglog($Msglevel{'FNC'}, "$myname,LRECL=$hex_rdw$hex_low");				
	return	$rdw;
}

# --------------------------------------------------------------
# METHOD        : TRUE|EOF|$lrcl : writeBrec(\$ref, $rec)
# DESCRIPTION   : HEXSTRをバイナリ変換しバイナリファイルに書き込む、Fcntl->recfmに従い可変長はRDWを付加.
# PARAM
#  i:\$ref		: 構造体Fctrl
#  i:$rec		: 出力内容（HEXSTR）
# REURN
#  R 書き込んだバイト数. エラー時は$EOF
# --------------------------------------------------------------
sub	writeBrec {
	my	($ref, $rec)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$fname	=	$ref->fname;
	my	$fh		=	$ref->fh;
	my	$recfm	=	$ref->recfm;

## レコード長チェック
	my	$hexl	=	length($rec);		# HEX文字列の長さ
 	my	$lrecl;							# レコード長 ＝ HEX文字列長 ÷ ２
	if(defined($hexl)) {;}
	else {
		&dbglog($Msglevel{'ERR'}, "$myname,hexl null");
		return $EOF;
	}
	if($hexl % 2 != 0){
		&dbglog($Msglevel{'ERR'}, "$myname,hexl is odd:$hexl");
		return $EOF;
	} else {
		$lrecl	=	$hexl / 2;
	}
## HEX文字列チェック
	if($lrecl == 0) {
		;
	} elsif ($rec =~ /^[0-9A-Fa-f]*$/) {
		;
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,err hexstr:$rec");
		return $EOF;
	}

## 固定長
	if($recfm eq 'F') {
														# レコード
		if($fname eq '')	{ print STDOUT pack("H*", $rec);}
		else				{ print $fh pack("H*", $rec);}
		my	$wk	=	$ref->iocnt;
		$wk++;
		$ref->iocnt( $wk );								# IOCNTをインクリメント
		return	$lrecl;									# 読み込みバイド数をRETURN
## 可変長
	} elsif($recfm eq 'V') {
		if($fname eq '')	{
			print STDOUT pack($Little16bit_us, $lrecl);		# 先頭RDW、ファイルに２バイトWRITE
			print STDOUT pack($Little16bit_us, 0);			# LOWVAL-2Byte、ファイルに２バイトWRITE
			if($lrecl != 0) {
				print STDOUT pack("H*", $rec);				# レコード
			}
			print STDOUT pack($Little16bit_us, $lrecl);		# 後続RDW、ファイルに２バイトWRITE
			print STDOUT pack($Little16bit_us, 0);			# LOWVAL-2Byte、ファイルに２バイトWRITE
		} else {
			print $fh pack($Little16bit_us, $lrecl);		# 先頭RDW、ファイルに２バイトWRITE
			print $fh pack($Little16bit_us, 0);				# LOWVAL-2Byte、ファイルに２バイトWRITE
			if($lrecl != 0) {
				print $fh pack("H*", $rec);					# レコード
			}
			print $fh pack($Little16bit_us, $lrecl);		# 後続RDW、ファイルに２バイトWRITE
			print $fh pack($Little16bit_us, 0);				# LOWVAL-2Byte、ファイルに２バイトWRITE
		}
		my	$wk	=	$ref->iocnt;						# IOCNTをインクリメント
		$wk++;
		$ref->iocnt( $wk );									# IOCNTをインクリメント
		return $lrecl;
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,invalid recfm:$recfm($fname)");
		return $EOF;
	}
	return $TRUE;
}

# --------------------------------------------------------------
# METHOD        : TRUE|EOF|$lrcl : writeTrec(\$ref, $rec)
# DESCRIPTION   : $recをファイルに書き込む
# PARAM
#  i:\$ref		: 構造体Fctrl
#  i:$rec		: 出力内容（文字列）
# REURN
#  R 書き込んだバイト数. エラー時は$EOF
# --------------------------------------------------------------
sub	writeTrec {
	my	($ref, $rec)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$fname	=	$ref->fname;
	my	$fh		=	$ref->fh;
	my	$recfm	=	$ref->recfm;
	my	$lrecl	=	length($rec);

## 改行付きテキスト
	if($recfm eq 'T') {
		my	$wk	=	$ref->iocnt;
		$wk++;
		$ref->iocnt( $wk );			# IOCNTをインクリメント
		if($fname eq '')	{ print $rec . "\n"; } 
		else 				{ print $fh $rec . "\n"; }
		return	$lrecl;				# 読み込みバイド数をRETURN
	} else {
		&dbglog($Msglevel{"ERR"}, "$myname,invalid recfm:$recfm($fname)");
		return $EOF;
	}
	return $FALSE;					# ここでリターンはエラー
}

# --------------------------------------------------------------
# METHOD        : STR with LF : hexdumpRec($hexstr)
# DESCRIPTION   : １レコード分のデータを、ダンプ形式（３２バイト改行付き）に編集、出力はしない。
# PARAM
#  i:$hexstr	: HEXSTR
# REURN
#  R ダンプ形式に編集した文字列
# --------------------------------------------------------------
sub	hexdumpRec {
	my	($hexstr)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$hexstr_len	=	length($hexstr);
	my	$ret = '';

	if($hexstr_len == 0) {
		$ret .= sprintf "%08X ", 0;	
	} else {
		for(my $i = 0; $i < $hexstr_len; $i++, $i++) {
			my	$ii = $i / 2;
			my	$hex_byte	=	substr($hexstr, $i, 2);
			if($ii == 0) { 				$ret .= sprintf "%08X ", $ii;	$ret .= sprintf "%2s", $hex_byte;
			} elsif(($ii % 32) == 0) {	$ret .= sprintf "\n";
										$ret .= sprintf "%08X ", $ii;	$ret .= sprintf "%2s", $hex_byte;
			} elsif(($ii % 16) == 0) {	$ret .= sprintf " - ";			$ret .= sprintf "%2s", $hex_byte;
			} elsif(($ii % 4 ) == 0) {	$ret .= sprintf " ";			$ret .= sprintf "%2s", $hex_byte;
			} else { 													$ret .= sprintf "%2s", $hex_byte;
			}
		}
	}
	$ret .= sprintf "\n\n";
	return $ret;
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : hexdp(\$Inf,\$Otf,$type)
# DESCRIPTION   : ファイルをバイナリREADしHEXDUMPする。OPEN-CLOSEをする
# DESC-SUB		: $type=lst,print with SP separate / $type=hexstr,simply print for hexput
# PARAM
#  i:\$Inf		: 入力ファイルのFcntl
#  i:\$Otf		: 出力ファイルのFcntl	
#  i:$type		: lst：リスト形式 / hexstr:１６進文字列
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	hexdp {
	my	($Inf, $Otf, $type)	=	@_;

	my	$myname	= (caller 0)[3];
## START-MSG
	my	$addmsg	= "[";
	$addmsg .= 	"logl=" . $Msgtag[&getLoglevel()] . "";
	$addmsg	.=	"]";
	&dbglog($Msglevel{'ALL'}, ("---- $0,$myname START $addmsg ----"));
#######################################
# open
#######################################
	if( &openBinput( $Inf ) == $TRUE ) { ; } 
	else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot open infile");
		die "$!";
	}

	my	$otfname	= $Otf->fname;
#	$Otf->decenc( 'utf8' );		# 出力のエンコードは、呼び出し元で設定する
	if( &openToutput( $Otf ) == $TRUE ) {
		;
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot open otfile");
		die "$!";
	}

	if($type eq "lst" || $type eq "hexstr"){
		;
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,type not lst,hexstr");
		die "$!";
	}

#######################################
# execute
#######################################
	my	$inrec;
	my	$ll;
	my	$fh = $Otf->fh;
	while( ($ll = &readBrec($Inf, \$inrec)) != $EOF ) {
		if($type eq "lst") {
			if($otfname eq '') {
				printf STDOUT "# %6d LRECL=%d:%x\n", $Inf->iocnt, $ll, $ll;
				printf STDOUT &hexdumpRec($inrec);
				my	$wk	= $Otf->iocnt; $wk++;
				$Otf->iocnt( $wk );
			} else {
				printf $fh "# %6d LRECL=%d:%x\n", $Inf->iocnt, $ll, $ll;
				printf $fh &hexdumpRec($inrec);
				my	$wk	= $Otf->iocnt; $wk++;
				$Otf->iocnt( $wk );
			}
		} elsif($type eq "hexstr") {
			my	$hexstr = unpack("H*", pack("H*", $inrec));
			$hexstr	=~	tr/a-f/A-F/;
			if($otfname eq '') {
				printf STDOUT  $hexstr . "\n";
				my	$wk	= $Otf->iocnt; $wk++;
				$Otf->iocnt( $wk );
			} else {
				printf $fh $hexstr . "\n";
				my	$wk	= $Otf->iocnt; $wk++;
				$Otf->iocnt( $wk );
			}
		}
	}

#######################################
# close
#######################################
## INPUT
	if( &closeAny( $Inf ) == $TRUE ) { 
		my	$iocnt	=	$Inf->iocnt;
		my	$fname	=	$Inf->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close infile");
		die "$!";
	}
## OUTPUT
	if($otfname eq '') {
		my	$iocnt	=	$Otf->iocnt;
		my	$fname	=	'STDOUT';
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} elsif( &closeAny( $Otf ) == $TRUE ) {
		my	$iocnt	=	$Otf->iocnt;
		my	$fname	=	$Otf->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close otfile");
		die "$!";
	}
	&dbglog($Msglevel{'ALL'}, ("---- $0 NORMAL-END ----"));
	return $TRUE;
} # hexdp

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : hexdplstFile(\$Inf,\$Otf)
# DESCRIPTION   : ファイルをリスト形式でHEXDUMPする。hexdpのラッパー
# PARAM
#  i:\$Inf	: 入力ファイルのFcntl
#  i:\$Otf	: 出力ファイルのFcntl	
# REURN
#  R return val of hexdp
# --------------------------------------------------------------
sub	hexdplstFile {
	my	($Inf, $Otf)	=	@_;
	return	&hexdp($Inf, $Otf, "lst");
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : hexdpFile(\$Inf,\$Otf)
# DESCRIPTION   : ファイルをHEXSTR形式でHEXDUMPする。hexdpのラッパー
# PARAM
#  i:$Inf		: 入力ファイルのFcntl
#  i:$Otf		: 出力ファイルのFcntl	
# REURN
#  R return val of hexdp
# --------------------------------------------------------------
sub	hexdpFile {
	my	($Inf, $Otf)	=	@_;
	return	&hexdp($Inf, $Otf, "hexstr");
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : hexputFile(\$Inf,\$Otf)
# DESCRIPTION   : HEXSTRのテキストファイルを、バイナリファイルに変換する。OPEN-CLOSEする
# PARAM
#  i:\$Inf		: 入力ファイルのFcntl
#  i:\$Otf		: 出力ファイルのFcntl	
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	hexputFile {
	my	($Inf, $Otf)	=	@_;

	my	$myname	= (caller 0)[3];
## START-MSG
	my	$addmsg	= "[";
	$addmsg .= 	"logl=" . $Msgtag[&getLoglevel()] . "";
	$addmsg	.=	"]";
	&dbglog($Msglevel{'ALL'}, ("---- $0,$myname START $addmsg ----"));

#######################################
# open
#######################################
	if( &openTinput( $Inf ) == $TRUE ) { ; } 
	else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot open infile");	
		die "$!";
	}

	my	$otfname	= $Otf->fname;
	if( $otfname eq '' || &openBoutput( $Otf ) == $TRUE ) { ; } 
	else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot open otfile");
		die "$!";
	}

#######################################
# execute
#######################################
	my	$inrec;
	while( &readTrec($Inf, \$inrec) != $EOF) {
		my	$errmsg;
		if(&ishexstr(\$errmsg, $inrec) != $TRUE) {
			&dbglog($Msglevel{'ERR'}, "$myname,not hexstr:$inrec");
			last;		# exit while-loop
		}
		if($Otf->recfm eq 'F' && $gOpt_pad ne '') {
			my	$ll	= length($inrec) / 2;
			my	$lrecl		= $Otf->lrecl;
			my	$shorter	= $lrecl - $ll;
			if($shorter gt 0) {
				$inrec	=	$inrec . ($gOpt_pad x $shorter) ; 
			} else {
				$inrec	=	substr($inrec, 0, $lrecl*2);
			}
		}
		&writeBrec($Otf, $inrec);
	}

#######################################
# close
#######################################
## INPUT
	if( &closeAny( $Inf ) == $TRUE ) { 
		my	$iocnt	=	$Inf->iocnt;
		my	$fname	=	$Inf->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close infile");
		die "$!";
	}
## OUTPUT
	if( $otfname eq '') {
		my	$iocnt	=	$Otf->iocnt;
		my	$fname	=	'STDOUT';
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} elsif( &closeAny( $Otf ) == $TRUE ) {
		my	$iocnt	=	$Otf->iocnt;
		my	$fname	=	$Otf->fname;
		&dbglog($Msglevel{'ALL'}, "IOCNT[$fname]=$iocnt");
	} else {
		&dbglog($Msglevel{'ERR'}, "$myname,cannot close otfile");
		die "$!";
	}
	&dbglog($Msglevel{'ALL'}, ("---- $0 NORMAL-END ----"));
	return $TRUE;
} # hexputFile

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2spd(\$errmsg,$num,$kpd)
# DESCRIPTION   : 数字 to SignedPackDecimal
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$num		: 数字 [+-]?[0-9]
#  i:$kpd		: SignedPackDecimalの数値桁数
# 
# REURN
#  ''    : Err occured
# --------------------------------------------------------------
sub	num2spd {
	my	($errmsg, $num, $kpd)	=	@_;

	$$errmsg = '';
## INCK
	if($num =~ /^[+-]?[0-9]+$/) { ; }
	else { 
		$$errmsg	= $Errcd{NUM} . ":not numeric($num)";
		return '';
	}
## 符号判定
	my	$sign;		# PACKの符号
	my	$val;		# numの数値部分
	my	$lval;		# length($val)
	if(substr($num, 0, 1) eq '+') {
		$sign	= $PackSignPlus;		$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) eq '-'){
		$sign	= $PackSignMinus;		$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) =~ /[0-9]/){
		$sign	= $PackSignPlus;		$val	= substr($num, 0);
	} else {
		$$errmsg	= $Errcd{NUM} . ":not sign($num)";
		return '';
	}
	$lval	= length($val);
## 桁数から返却値桁数
	my	$lpd;
	if(($kpd % 2) == 0) {	$lpd	= $kpd + 1;
	} else {				$lpd	= $kpd;	}
## 桁あふれチェック
	if( $lval > $lpd ) {
		$$errmsg	= $Errcd{KET} . ":keta overflow($num,$kpd)";
		return '';
	}
## 前ゼロパディイング
	my $retval	= '0' x ($lpd - $lval) . $val . $sign;
	
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2upd(\$errmsg,$num,$kpd)
# DESCRIPTION   : 数字 to UnsignedPackDecimal
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$num		: 数字 [+]?[0-9]
#  i:$kpd		: SignedPackDecimalの数値桁数
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	num2upd {
	my	($errmsg, $num, $kpd)	=	@_;

	$$errmsg = '';
## INCK
	if($num =~ /^[+]?[0-9]+$/) { ; }
	else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($num)";
		return '';
	}
## 符号判定
	my	$sign;		# PACKの符号
	my	$val;		# numの数値部分
	my	$lval;		# length($val)
	if(substr($num, 0, 1) eq '+') {
		$sign	= $PackSignAbs;			$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) =~ /[0-9]/){
		$sign	= $PackSignAbs;			$val	= substr($num, 0);
	} else {
		$$errmsg	= $Errcd{NUM} . ":not sign($num)";
		return '';
	}
	$lval	= length($val);
## 桁数から返却値桁数
	my	$lpd;
	if(($kpd % 2) == 0) {	$lpd	= $kpd + 1;
	} else {				$lpd	= $kpd;	}
## 桁あふれチェック
	if( $lval > $lpd ) {
		$$errmsg	= $Errcd{KET} . ":keta overflow($num,$kpd)";
		return '';
	}
## 前ゼロパディイング
	my $retval	= '0' x ($lpd - $lval) . $val . $sign;
	
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2szd(\$errmsg,$num,$kzd)
# DESCRIPTION   : 数字 to SignedZoneDecimal
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$num		: 数字 [+-]?[0-9]
#  i:4kzd		: ZonDecimalの数値桁数
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	num2szd {
	my	($errmsg, $num, $kzd)	=	@_;

	$$errmsg = '';
## INCK
	if($num =~ /^[+-]?[0-9]+$/) { ; }
	else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($num)";
		return '';
	}
## 符号判定
	my	$sign;		# ZONEの符号
	my	$val;		# numの数値部分
	my	$lval;		# length($val)
	if(substr($num, 0, 1) eq '+') {
		$sign	= $ZoneSignPlus;		$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) eq '-'){
		$sign	= $ZoneSignMinus;		$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) =~ /[0-9]/){
		$sign	= $ZoneSignPlus;		$val	= substr($num, 0);
	} else {
		$$errmsg	= $Errcd{NUM} . ":not sign($num)";
		return '';
	}
	$lval	= length($val);
## 桁数から返却値桁数
	my	$lzd;
	$lzd	=	$kzd;
## 桁あふれチェック
	if( $lval > $lzd ) {
		$$errmsg	= $Errcd{KET} . ":keta overflow($num,$kzd)";
		return '';
	}
## 前ゼロパディイング
	my $retval	= ($ZoneUpHalfPad . "0") x ($lzd - $lval);
## 中間部
	for(my $i = 0; $i < $lval - 1; $i++) {
		$retval	.= ($ZoneUpHalfPad . substr($val, $i, 1));
	}
## 最終部
	$retval	.=	($sign . substr($val, $lval - 1, 1));
	
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2uzd(\$errmsg,$num,$kzd)
# DESCRIPTION   : 数字 to UnsignedZoneDecimal
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$num		: 数字 [+]*[0-9]
#  i:$kzd		: ZonDecimalの数値桁数
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	num2uzd {
	my	($errmsg, $num, $kzd)	=	@_;

	$$errmsg = '';
## INCK
	if($num =~ /^[+]?[0-9]+$/) { ; }
	else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($num)";
		return '';
	}
## 符号判定
	my	$sign;		# ZONEの符号
	my	$val;		# numの数値部分
	my	$lval;		# length($val)
	if(substr($num, 0, 1) eq '+') {
		$sign	= $ZoneSignAbs;		$val	= substr($num, 1);
	} elsif(substr($num, 0, 1) =~ /[0-9]/){
		$sign	= $ZoneSignAbs;		$val	= substr($num, 0);
	} else {
		$$errmsg	= $Errcd{NUM} . ":not sign($num)";
		return '';
	}
	$lval	= length($val);
## 桁数から返却値桁数
	my	$lzd;
	$lzd	=	$kzd;
## 桁あふれチェック
	if( $lval > $lzd ) {
		$$errmsg	= $Errcd{KET} . ":keta overflow($num,$kzd)";
		return '';
	}
## 前ゼロパディイング
	my $retval	= ($ZoneUpHalfPad . "0") x ($lzd - $lval);
## 中間部
	for(my $i = 0; $i < $lval - 1; $i++) {
		$retval	.= ($ZoneUpHalfPad . substr($val, $i, 1));
	}
## 最終部
	$retval	.=	($sign . substr($val, $lval - 1, 1));
	
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2bl(\$errmsg, $num, $bhx)
# DESCRIPTION   : 数値をBinaryLittleEndでバイナリ化したHEXSTRを返却
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:num		: 数値(Perl内部形式)
#  i:bhx		: 返却値の桁数＝バイト数。length()÷2。1/2/4/8
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	num2bl {
	my	($errmsg, $num, $bhx)	=	@_;

	my	$val;
	$$errmsg = '';
## INCK
	if($num =~ /^[+-]?[0-9]+$/) { ; } 
	else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($num,$bhx)";
		return '';
	}
## バイト数
	if($bhx == 1) {
		$val	= unpack("H*", pack($pkupk_S8bit, $num));
	} elsif($bhx == 2) {
		$val	= unpack("H*", pack($pkupk_S16bit, $num));
	} elsif($bhx == 4) {
		$val	= unpack("H*", pack($pkupk_S32bit, $num));
	} elsif($bhx == 8) { 
		$val	= unpack("H*", pack($pkupk_S64bit, $num));
	} else {
		$$errmsg	= $Errcd{KET} . ":irregal bytes($num,$bhx)";
		return '';
	}

	return $val;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : num2bb(\$errmsg, $num, $bhx)
# DESCRIPTION   : 数値をBinaryBigEndでバイナリ化したHEXSTR
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$num		: 数値(Perl内部形式)
#  i:$bhx		: 返却値の桁数＝バイト数。length()÷2
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	num2bb {
	my	($errmsg, $num, $bhx)	=	@_;

	$$errmsg = '';
	my	$bl		= &num2bl($errmsg, $num, $bhx); 
	my	$lbl	= length($bl);

	my	$bb	= '';
	for(my $i = 0; $i < $lbl; $i++, $i++) {
		my $ii	= $lbl - $i - 2;		# 0 -> $lbb -2 / 2 -> $ldd - 4
		$bb .= substr($bl, $ii, 2);
	}
	return $bb;
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : char2xx_tosjishex(\$errmsg,$char,$bxx)
# DESCRIPTION   : $charの文字をsjis文字コードで返却（HEXSTR）。char2xxのラッパー
# PARAM
#   o:\$errmsg
#	i:$char		: 文字列(perl内部形式)
#	i:$bxx
# --------------------------------------------------------------
sub	char2xx_tosjishex {
	my	($errmsg, $char, $bxx)	=	@_;

	$$errmsg = '';
	my	$dec = '';
	my	$enc = 'cp932';
	return char2xx($errmsg, $char, $bxx, $dec, $enc);
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : char2xx_toutf8hex(\$errmsg,$char,$bxx)
# DESCRIPTION   : $charの文字をutf8文字コードで返却（HEXSTR）。char2xxのラッパー
#   o:\$errmsg
#	i:$char		: 文字列(perl内部形式)
#	i:$bxx
# --------------------------------------------------------------
sub	char2xx_toutf8hex {
	my	($errmsg, $char, $bxx)	=	@_;

	$$errmsg = '';
	my	$dec = '';
	my	$enc = 'utf8';
	return char2xx($errmsg, $char, $bxx, $dec, $enc);
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : char2xx(\$errmsg,$char,$bxx,$dec,$enc)
# DESCRIPTION   : 文字を文字コード（HEXSTR）に変換。バイト長未満は0x20パディング。
# DESC-SUB		: $charをデコード＆エンコードして、UNPACKでHEXSTRにする。
#	$charがperl内部形式時は、$dec=''とする。
#	$encで文字コードを指定する
#	decode($dec, $char)		$charが$decの文字コードで格納されている前提で、perl内部形式に変換する
#	encode($enc, $plchar)	perl内部形式の$plcharを、$encの文字コードに変換。格納形式はperl内部形式
#	unpack("H*", $aa)		$aaをHEXSTRに変換
# PARAM
#  o:\$errmsg	ERRMSG
#  i:$char		文字(perl内部コード)
#  i:$bxx		返却値の桁数＝バイト数。length()÷2
#  i:$dec		$charがどの文字コードで格納されているか、perl内部形式は''
#  i:$enc		$charをどの文字コードのコード値にするか、perl内部形式は''
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	char2xx {
	my	($errmsg, $char, $bxx, $dec, $enc)	=	@_;

	$$errmsg = '';
## INCK
	my	$achar;
	if($dec ne '' and $enc ne '')	 { $achar = encode($enc, decode($dec, $char)); }
	elsif($dec eq '' and $enc ne '') { $achar = encode($enc, $char); }
	elsif($dec ne '' and $enc eq '') { $achar = decode($dec, $char); }
	elsif($dec eq '' and $enc eq '') { $achar = $char; }
	else { ; }

	my	$ahex	= unpack("H*", $achar);	
	$ahex	=~	tr/a-f/A-F/;
	my	$ll		= length($ahex);
	my	$ll2 	= $ll / 2;
	my	$retval	= '';
## 桁あふれチェック
	if($ll > ($bxx * 2)) {
		$$errmsg	= $Errcd{KET} . ":keta over byte($char,$ll2,$bxx)";
	} elsif($ll < ($bxx * 2)) {
		$$errmsg	= $Errcd{KET} . ":keta short byte($char,$ll2,$bxx)";
	} else { 
		$$errmsg	= "";
	}
## 指定バイト長にあわせて格納
	if($bxx == 0) {						## バイト長０は、ジャストで返却
		$$errmsg = '';					## errmsgはクリア
		$retval	= $ahex;
	} elsif ($ll > ($bxx * 2)) {		## バイト長オーバは、後半削除して返却
		$retval = substr($ahex, 0, $bxx*2);
	} else {							## バイト長不足時は、半角HEXをパディング
		my	$ll_padding	= $bxx - int($ll / 2);
		$retval	=	$ahex . ($HanSP_hex x $ll_padding);
	}
	return $retval;
}


# --------------------------------------------------------------
# METHOD        : plCHAR : xx2char_fromsjishex(\$errmsg,$xx)
# DESCRIPTION   : HEXSTRをsjisの文字コードで解釈（デコードして）、perl内部コードの文字にする。xx2charのラッパー
# PARAM
#	:\$errmsg
#	i:$xx		: HEXSTR（SJIS文字コード）
# RETURN
#	文字列(perl内部形式)
# --------------------------------------------------------------
sub	xx2char_fromsjishex {
	my	($errmsg, $hexstr)	=	@_;

	$$errmsg = '';
	my	$dec	= 'cp932';
	my	$enc	= '';
	return &xx2char($errmsg, $hexstr, $dec, $enc);
}

# --------------------------------------------------------------
# METHOD        : plCHAR : xx2char_fromutf8hex(\$errmsg, $xx)
# DESCRIPTION   : HEXSTRをutf8の文字コードで解釈（デコードして）、perl内部コードの文字にする。xx2charのラッパー
# PARAM
#	o:\$errmsg
#	i:$xx		: HEXSTR（UTF8文字コード）
# RETURN
#	文字列(perl内部形式)
# --------------------------------------------------------------
sub	xx2char_fromutf8hex {
	my	($errmsg, $hexstr)	=	@_;

	$$errmsg = '';
	my	$dec	= 'utf8';
	my	$enc	= '';
	return &xx2char($errmsg, $hexstr, $dec, $enc);
}

# --------------------------------------------------------------
# METHOD        : plCHAR : xx2char(\$errmsg,$xx,$dec,$enc)
# DESCRIPTION   : HEXSTRを$decの文字コードで解釈し、$encの文字コードに変換する
# PARAM
#	o:\$errmsg	:
#	i:$xx		: HEXSTR
#	i:$dec		: HEXSTRを解釈する文字コード
#	i:$enc		: 変換先の文字コード
# RETURN
#	文字列（$encの文字コードで格納）
# --------------------------------------------------------------
sub	xx2char {
	my	($errmsg, $hexstr, $dec, $enc)	=	@_;

	$$errmsg = '';
	my	$hexval	= pack("H*", $hexstr);
#####
	my	$achar;
	if($dec ne '' and $enc ne '')	 { $achar = encode($enc , decode($dec, $hexval)); }
	elsif($dec eq '' and $enc ne '') { $achar = encode($enc , $hexval); }
	elsif($dec ne '' and $enc eq '') { $achar = decode($dec , $hexval); }
	elsif($dec eq '' and $enc eq '') { $achar = $hexval; }
	else { ; }
	return $achar;
}


# --------------------------------------------------------------
# METHOD        : plNUM : pd2num(\$errmsg, $pd)
# DESCRIPTION   : PackDecimal(HEXSTR) to 数字（Perl内部形式）
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$pd		: [0-9]+[CDF]
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	pd2num {
	my	($errmsg, $pd)	=	@_;

	$$errmsg = '';
	my	$lpd = length($pd);
	my	$val = substr($pd, 0, $lpd - 1);	# 数値部

## INCK:桁数
	if(($lpd % 2) != 0) {
		$$errmsg	= $Errcd{KET} . ":length not even($pd)";
		return '';
	}

## INCK:数値部
	if( $val =~ /^[0-9]+$/) { ; }
	else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($pd)";
		return '';
	}
## INCK:符号部
	my	$sign;		#　PACKの符号
	if(substr($pd, $lpd - 1, 1) eq $PackSignPlus) {
		$sign	= +1;
	} elsif(substr($pd, $lpd - 1, 1) eq $PackSignMinus) {
		$sign	= -1;
	} elsif(substr($pd, $lpd - 1, 1) eq $PackSignAbs) {
		$sign	= +1;
	} else {
		$$errmsg	= $Errcd{NUM} . ":not sign($pd)";
		return '';
	}

	my $retval	= $val * $sign;
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : plNUM : zd2num(\$errmsg, $zd)
# DESCRIPTION   : ZoneDecimal(HEXSTR) to 数字(Perl内部形式)
# PARAM
#  o:\$errmsg	ERRMSG
#  i:pd			{[3][0-9]}+[CDF][0-9]
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	zd2num {
	my	($errmsg, $zd)	=	@_;

	$$errmsg = '';
	my	$lzd = length($zd);
	my	$val; 

## INCK:桁数
	if(($lzd % 2) != 0) {
		$$errmsg	= $Errcd{KET} . ":length not even($zd)";
		return '';
	}
## INCK:数値部バイト
	$val	= '';
	for(my $i = 0; $i < $lzd - 2; $i++, $i++) {
		my	$signH	= substr($zd, $i, 1);		# 上位４ビット、チェックなし
		my	$digit	= substr($zd, $i + 1, 1);	# 下位４ビット
		if($digit =~ /[0-9]/) {
			$val	.=	$digit;
		} else {
			$$errmsg	= $Errcd{NUM} . ":not numeric($zd)";
			return '';
		}
	}

## INCK:符号部バイト
	my	$signH	= substr($zd, $lzd - 2, 1);
	my	$digit	= substr($zd, $lzd - 1, 1);
	if($digit =~ /[0-9]/) {
		$val	.=	$digit;
		if($signH eq $ZoneSignPlus) 		{ $val	=	$val * 1; } 
		elsif($signH eq $ZoneSignMinus) 	{ $val	=	$val * -1; } 
		elsif($signH eq $ZoneSignAbs) 		{ $val	=	$val * 1; }
		else {
			$$errmsg	= $Errcd{NUM} . ":not sign($zd)";
			return '';
		}
	} else {
		$$errmsg	= $Errcd{NUM} . ":not numeric($zd)";
		return '';
	}

	my $retval	= $val + 0;
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : plNUM : bl2num(\$errmsg, $bl)
# DESCRIPTION   : BinaryLittleEnd(HEXSTR) to 数字(Perl内部形式)
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$bb		: [0-F]+
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
## Scanfが使えない
## use	String::Scanf 'sscanf';
sub	bl2num {
	my	($errmsg, $bl)	=	@_;

	$$errmsg = '';
	my	$lbl = length($bl);
	my	$val; 

## INCK:桁数CK＆変換
# １６進文字列でPACK(Perl内部表現化)して、長さに合わせてUNPACK(数値化)
	if(($lbl / 2) == 1) {
		$val	= unpack($pkupk_S8bit, pack("H*", $bl));	
	} elsif(($lbl / 2) == 2) {
		$val	= unpack($pkupk_S16bit, pack("H*", $bl));
	} elsif(($lbl / 2) == 4) {
		$val	= unpack($pkupk_S32bit, pack("H*", $bl));
	} elsif(($lbl / 2) == 8) {
		$val	= unpack($pkupk_S64bit, pack("H*", $bl));
	} else {
		$$errmsg	= $Errcd{KET} . ":length not even($bl,$lbl)";
		return '';
	}

	my $retval	= $val + 0;
	$$errmsg = '';
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : plNUM : bb2num(\$errmsg, $bb)
# DESCRIPTION   : BinaryBIgEnd(HEXSTR) to 数字(Perl内部形式)
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:$bb		: [0-F]+
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	bb2num {
	my	($errmsg, $bb)	=	@_;

	$$errmsg = '';
	my	$lbb = length($bb);
	my	$bl; 

	$bl	= '';
	for(my $i = 0; $i < $lbb; $i++, $i++) {
		my $ii	= $lbb - $i - 2;		# 0 -> $lbb -2 / 2 -> $ldd - 4
		$bl .= substr($bb, $ii, 2);
	}

	return &bl2num($errmsg, $bl);
}

# --------------------------------------------------------------
# METHOD        : HEXSTR : hex2xx(\$errmsg, $hex, $bxx)
# DESCRIPTION   : &H + HEXSTR to HEXSTR without &H
# PARAM
#  o:\$errmsg	: ERRMSG
#  i:bxx		: &H + HEXSTR
#  i:bhx		: 返却値の桁数＝バイト数。length()÷2
# REURN
#  ''    : Err occured,
# --------------------------------------------------------------
sub	hex2xx {
	my	($errmsg, $hex, $bxx)	=	@_;

	$$errmsg = '';
## INCK：先頭の指定
	if( substr($hex, 0, 2) eq "&H") {
		$hex	= substr($hex, 2);
	}
## INCK:
	if( $hex =~ /^[0-9A-Fa-f]+$/) {
		;
	} else {
		$$errmsg	= $Errcd{HEX} . ":not hex($hex,$bxx)";
		return '';
	}
	my	$ll	=	length($hex);
	my	$ll2 = $ll / 2;
	my	$retval = '';
## 桁あふれチェック
	if($ll > ($bxx * 2)) {
		$$errmsg	= $Errcd{KET} . ":keta over bytes($hex,$ll2,$bxx)";
	} elsif ($ll < ($bxx * 2)) {
		$$errmsg	= $Errcd{NUM} . ":keta short bytes($hex,$ll2,$bxx)";
	} else {
		$$errmsg	= "";
	}
## バイト長にあわせて格納
	if($bxx == 0) {						## バイト長０は、そのまま返却りリターン
		$$errmsg = '';
		$retval	= $hex;
		return $retval;
	}
## HEXSTR の長さが奇数の時、一文字削除
	if(($ll % 2) != 0){	
		$hex	= substr($hex, 0, int($ll2) * 2);
		$ll		= length($hex);
		$ll2	= $ll / 2;
	}
## バイト長にあわせて格納
	if ($ll > ($bxx * 2)) {		## バイト長あふれは、後半削除
		$retval = substr($hex, 0, $bxx * 2);
	} else {							## バイト長不足時は、半角HEXをパディング
		my	$ll_padding	= $bxx - int($ll/2);
		$retval	= $hex . ($HanSP_hex x $ll_padding);
	}
	return $retval;
}

# --------------------------------------------------------------
# METHOD        : &H + HEXSTR : xx2hex(\$errmsg, $xx)
# DESCRIPTION   : HEXSTR to &H + HEXSTR
# --------------------------------------------------------------
sub	xx2hex {
	my	($errmsg, $xx)	=	@_;
	$$errmsg = '';

## INCK：先頭の補正
	if( substr($xx, 0, 2) eq "&H") {
		$xx	= substr($xx, 2);
	}
## INCK:HEX
	if( $xx =~ /^[0-9A-Fa-f]+$/) {	; } 
	else { 
		$$errmsg	= $Errcd{HEX} . ":not hex($xx)";
		return '';
	}
## INCK:length is even
	if( (length($xx) % 2) == 0 ) { ; }
	else {
		$$errmsg	= $Errcd{HEX} . ":length not even($xx)";
		return '';
	}
	return	("&H" . $xx);
}

# --------------------------------------------------------------
# METHOD        : TRUE|FALSE : ishexstr($$errmsg, $hexstr)
# DESCRIPTION   : check [0-9a-fA-F]+ , length(hexstr) % 2 == 0
# --------------------------------------------------------------
sub	ishexstr {
	my	($errmsg, $hexstr)	=	@_;

## INCK:HEX。null-strを許容するので、^[..]＊
	if( $hexstr =~ /^[0-9A-Fa-f]*$/) {	; } 
	else { 
		$$errmsg	= $Errcd{HEX} . ":not hex($hexstr)";
		return $FALSE;
	}
## INCK:length is even
	if( (length($hexstr) % 2) == 0 ) { ; }
	else {
		$$errmsg	= $Errcd{HEX} . ":length not even($hexstr)";
		return $FALSE;
	}
	return	$TRUE;
}

# ---------------------------------------------------
#	EXIT-PACKAGE
# ---------------------------------------------------
1 ; # TRUE
