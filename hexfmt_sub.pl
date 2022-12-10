# --------------------------------------------------------------
# hexM.pl -> cobfile.pl -> &hexedit() から呼び出されるユーザ出口関数
#  init_pre,init_aft	: 初期出口
#  record_exit			: レコード編集出力出口、入力毎に呼び出される
#  term_pre,term_aft	: 終了出口
# --------------------------------------------------------------
# 関数名(PKG名付)			$myname	= (caller 0)[3];
# 呼び元の関数名(PKG名付)	$callername = (caller 1)[3];
# -------------------------------------
package	hexedit;
# -------------------------------------
use	strict;
use	warnings;
use utf8;
use Encode 'decode', 'encode' ;
$cobfile::ZoneSignPlus	= 	'C';	# num2xzdの符号部、zd2numの符号チェック
$cobfile::ZoneSignMinus	=	'D';
$cobfile::ZoneSignAbs	=	'F';	

# --------------------------------------------------------------
#	フォーマット定義
# --------------------------------------------------------------
## レコードフォーマット
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
my	@array_fmt1	=	(
	[0,4,'ZD','item11'], 
	[4,4,'PD','item12'], 
	[8,4,'CH','item13']
);
my	@array_fmt2	=	(
	[0,4,'ZD','item21'], 
	[4,4,'PD','item22'], 
	[8,4,'CH','item23'], 
	[12,4,'XX','item24'],
	[16,12,'CH','item25']
);
## レコードフォーマットへのリファレンス
my	%hash_for_array_fmts = (
	FMT1 => \@array_fmt1, FMT2 => \@array_fmt2
);
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

# --------------------------------------------------------------
# METHOD        : FMTID : getfmtid(\$refin, \$errmsg, $hexstr)
# DESCRIPTION	: 入力レコードのFMTIDを返却する。
# DESC-SUB		: FMTIDは、%hash_for_hash_fmtsのKEYであること。
# PARAM
#	i:\$refin	: 入力ファイルのFcntl
#	o:\$errmsg	
#	i:$hexstr	: 読み込んだレコード（HEXSTR）
# REURN
#	FMTID		: %hash_for_array_fmts のKEY
# --------------------------------------------------------------
sub	getfmtid {
	my	($refin, $errmsg, $hexstr)	=	@_;
	my	$myerrmsg;
	my	$decenc	= '';
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
	my	@wk_hantei = (0, 4, 'XX', '');
	my	$hantei	=	&cobfile::getitem($refin, \$myerrmsg, $hexstr, @wk_hantei, $decenc);
	my	$fmtid = '';
	if   ($hantei eq 'F0F1F2F3') {	$fmtid	=	"FMT1";	} 
	elsif($hantei eq 'F3F5F6F7') {	$fmtid	=	"FMT1";	} 
	elsif($hantei eq 'F1F2F3F4') {	$fmtid	=	"FMT2";	} 
#	elsif($hantei eq 'F1F6F7F8') {	$fmtid	=	"FMT2";	} 
	else { ; }
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	$$errmsg = $myerrmsg;
	return	$fmtid;
}

# --------------------------------------------------------------
# METHOD        : TRUE|EOF|FALSE : record_exit(\$refin, \$refot, $hexstr, \$retstr)
# DESCRIPTION	: FWから呼び出される入力レコード毎の出口。fmtprint,edirrecへのラッパー
# DESC-SUB		: EOFを返却すると、FWは終了処理へ向かう、以外はループ
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
#  i:$hexstr	: 読み込んだレコード（HEXSTR変換後）が渡される
#  o:\$retstr	: FWに返却するレコード
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	record_exit {
	my	($refin, $refot, $hexstr, $retstr)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$ret_record_exit	= &fmtprint($refin, $refot, $hexstr, $retstr);
	&cobfile::dbglog($cobfile::Msglevel{'DBG'}, "$myname,fmtprint returns:$$retstr");
#
	if( $ret_record_exit == $cobfile::TRUE ) {
		if($refot->recfm =~ /^[FV]$/)	{ ; }
		elsif($refot->recfm eq 'T')		{ &cobfile::writeTrec($refot, $$retstr); }
		else { &dbglog($bobfile::Msglevel{'ERR'}, ("$myname,incorrect output"));}
	}
	return	$ret_record_exit;
}

# --------------------------------------------------------------
# METHOD        : TRUE : fmtprint(\$refin, \$refot, $hexstr, \$retstr)
# DESCRIPTION   : 入力レコード毎の出口、FMT判定とフォーマットダンプ出力を行う。
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
#  i:hexstr		: 編集対象の１６進文字列(HEXSTR)
#  o:\retstr	: 編集後の１６進文字列 (HEXSTR)
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	fmtprint {
	my	($refin, $refot, $hexstr, $retstr)	=	@_;

	my	$myname	= (caller 0)[3];
#
	my	$errmsg;
###########################################################
## レコードFMT[ $whichfmt ]の確定
###########################################################
	my	$whichfmt	=	&getfmtid($refin, \$errmsg, $hexstr);
	my	$iocnt	=	$refin->iocnt;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "$myname,rec[$iocnt],RECFMT[$whichfmt]");
	if($whichfmt eq '') {
		&cobfile::dbglog($cobfile::Msglevel{'DBG'}, "$myname,RECFMT not found");
		$iocnt	= $refot->iocnt;
		$iocnt++;
		$$retstr	=	(sprintf "%s[%s]=%s ", '(null)', 'XX', $hexstr);
		return	$cobfile::FALSE;
	}
###########################################################
## レコードFMTに従い、項目ダンプを出力
###########################################################
	$$retstr	= '';
	my	$refto_array_fmtN	= $hash_for_array_fmts{ $whichfmt };
	my	@tmparray			= @$refto_array_fmtN;
	foreach	my $refto_lst (@tmparray) {
		my	($st,$ll,$type,$tag)	=	@$refto_lst;
		&cobfile::dbglog($cobfile::Msglevel{'FNC'}, "$myname,ST:$st,LL:$ll,TY:$type,TG:$tag");
		my	$item	= &cobfile::getitem($refin, \$errmsg, $hexstr, $st, $ll, $type, $tag, '');
		$$retstr .= (sprintf "%s[%s]=%s ", $tag, $type, $item);
	}
	$iocnt	= $refot->iocnt;
	$iocnt++;
	$$retstr	= sprintf("[%6d] ", $iocnt) . $$retstr;
	return $cobfile::TRUE;
}

# --------------------------------------------------------------
# METHOD        : TRUE : init_pre(\$refin, \$refot)
# DESCRIPTION   : 初期出口、入力・出力ファイルのオープン「前」に呼び出される
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	init_pre {
	my	($refin, $refot)	=	@_;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "hexedit::init_pre START");
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	return $cobfile::TRUE;
}
# --------------------------------------------------------------
# METHOD        : TRUE : init_aft(\$refin, \$refot)
# DESCRIPTION   : 初期出口、入力・出力ファイルのオープン「後」に呼び出される
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	init_aft {
	my	($refin, $refot)	=	@_;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "hexedit::init_aft START");
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	return $cobfile::TRUE;
}
# --------------------------------------------------------------
# METHOD        : TRUE : term_pre(\$refin, \$refot)
# DESCRIPTION   : 終了出口、入力・出力ファイルのクローズ「前」に呼び出される
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	term_pre {
	my	($refin, $refot)	=	@_;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "hexedit::term_pre START");
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	return $cobfile::TRUE;
}
# --------------------------------------------------------------
# METHOD        : TRUE : term_aft(\$refin, \$refot)
# DESCRIPTION   : 終了出口、入力・出力ファイルのクローズ「後」に呼び出される
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	term_aft {
	my	($refin, $refot)	=	@_;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "hexedit::term_aft START");
#### 変更START ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
#### 変更END   ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
	return $cobfile::TRUE;
}

# ---------------------------------------------------
#	EXIT-TRUE
# ---------------------------------------------------
1 ; # TRUE
