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
#### 変更START #################################################
## レコードフォーマット＃１
my	%hash_fmt1	=	(
	ITEM_1 => [0,2,'CH','key1'], 
	ITEM2 => [2,2,'CH','val1'], 
	ITEM3 => [4,2,'XX','crlf']
);
## レコードフォーマットへのリファレンス
my	%hash_for_hash_fmts = (
	FMT1 => \%hash_fmt1, FMT2 => \%hash_fmt1
);

## レコードフォーマット＃２、レコードフォーマット＃１と同じもの
my	@array_fmt1	=	(
	[0,2,'CH','key1'], 
	[0,4,'CH','val1'], 
	[4,2,'XX','crlf']
);
## レコードフォーマットへのリファレンス
my	%hash_for_array_fmts = (
	FMT1 => \@array_fmt1, FMT2 => \@array_fmt1
);
#### 変更END ###################################################

# --------------------------------------------------------------
# METHOD        : FMTID : getfmtid(\$refin, \$errmsg, $hexstr)
# DESCRIPTION	: 入力レコードのFMTIDを返却する。
# DESC-SUB		: FMTIDは、%hash_for_hash_fmtsのKEYであること。
# PARAM
#	i:\$refin	: 入力ファイルのFcntl
#	o:\$errmsg	
#	i:$hexstr	: 読み込んだレコード（HEXSTR）
# REURN
#	FMTID		: %hash_for_hash_fmtsのKEY
# --------------------------------------------------------------
# case1
#	my	$refto_hash_fmtN	= $hash_for_hash_fmts{ FMT1 };
#	my @array 	= @{$$refto_hash_fmtN{ 'ITEM_1' }};
#	my	$hantei	= &cobfile::getitem($refin, \$myerrmsg, $hexstr, @array,  '');
# case2
#	my	@array	=	@{$hash_fmt1{ ITEM1 }};
#	my	$hantei	=	&cobfile::getitem($refin, \$myerrmsg, $hexstr, @array,  '');
# case3
#	my	@array	=	@{$array_fmt1[0]};		# 配列の０番目の要素を取得し、@ででリファレンス
#	my	$hantei	=	&cobfile::getitem($refin, \$myerrmsg, $hexstr, @array,  '');
sub	getfmtid {
	my	($refin, $errmsg, $hexstr)	=	@_;
	my	$myerrmsg;

	my	$myname	= (caller 0)[3];
#### 変更START #################################################

# case0
#	my	$refto_hash_fmtN	= $hash_for_hash_fmts{ FMT1 };
	my	@array 	= @{${$hash_for_hash_fmts{ FMT1 }}{ ITEM_1 }};
	my	$hantei	= &cobfile::getitem($refin, \$myerrmsg, $hexstr, @array,  '');

	my	$fmtid = '';
	if   ($hantei eq 'AB')	{	$fmtid	=	"FMT1";	} 
	elsif($hantei eq 'ｱｲ') 	{	$fmtid	=	"FMT2";	} 
	elsif($hantei eq '漢') 	{	$fmtid	=	"FMT2";	} 
	elsif($hantei eq '12') 	{	$fmtid	=	"FMT1";	} 
	else { ; }
#### 変更END ###################################################
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
	my	$ret_record_exit = '';
	if($cobfile::gOpt_edit eq 'edit') {
		$ret_record_exit = &editrec($refin, $refot, $hexstr, $retstr);
		&cobfile::dbglog($cobfile::Msglevel{'DBG'}, "$myname,editrec returns:$$retstr");
	} elsif($cobfile::gOpt_edit eq 'fmtpr') {
		$ret_record_exit = &fmtprint($refin, $refot, $hexstr, $retstr);
		&cobfile::dbglog($cobfile::Msglevel{'DBG'}, "$myname,fmtprint returns:$$retstr");
	}
	if( $ret_record_exit == $cobfile::TRUE ) {
		if($refot->recfm =~ /^[FV]$/)	{ &cobfile::writeBrec($refot, $$retstr); }
		elsif($refot->recfm eq 'T')		{ &cobfile::writeTrec($refot, $$retstr); }
		else { &dbglog($bobfile::Msglevel{'ERR'}, ("$myname,err ot_recfm"));}
	}
	return	$ret_record_exit;
}

# --------------------------------------------------------------
# METHOD        : TRUE : editrec(\$refin, \$refot, $hexstr, \$retstr)
# DESCRIPTION   : 入力レコード毎の出口、FMT判定と出力を行う。
# DESC-SUB		: TRUE以外を返却すると、その時点で &hexedit は終了する
# PARAM
#  i:\$refin	: 入力ファイルのFcntl
#  i:\$refot	: 出力ファイルのFcntl
#  i:hexstr		: 編集対象の１６進文字列(HEXSTR)
#  o:\retstr	: 編集後の１６進文字列 (HEXSTR)
# REURN
#  R OK/NG
# --------------------------------------------------------------
sub	editrec {
	my	($refin, $refot, $hexstr, $retstr)	=	@_;

	my	$myname	= (caller 0)[3];
	my	$errmsg;
###########################################################
## レコードFMT[ $whichfmt ]の確定
###########################################################
	my	$whichfmt	= &getfmtid($refin, \$errmsg, $hexstr);
	my	$iocnt	=	$refin->iocnt;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "$myname,rec[$iocnt],RECFMT[$whichfmt]");
###########################################################
## レコードFMTの中から、ITEMを取得
## heedit_repで、項目を編集する   
###########################################################
	my	$enc = '';

	my	$refto_hash_fmtN	= $hash_for_hash_fmts{ $whichfmt };
	my	($st,$len,$type,$tag);
#### 変更START ##########################################################
	if($whichfmt eq "FMT1") {
		my	$buf	=	$hexstr;
		($st,$len,$type,$tag)	= @{$$refto_hash_fmtN{ 'ITEM2' }};
		&cobfile::hexedit_rep(\$buf, $st, $len, &cobfile::char2xx_tosjishex(\$errmsg, '..', 2));
# -------------------------------------------------------------------
		$$retstr	=	$buf;
	}
	if($whichfmt eq "FMT2") {
		my	$buf	=	$hexstr;
		my	$item1	=	&cobfile::getitem($refin, \$errmsg, $hexstr, (@{$$refto_hash_fmtN{ 'ITEM_1' }}), $enc) ; 
		my	$item2	=	&cobfile::getitem($refin, \$errmsg, $hexstr, (@{$$refto_hash_fmtN{ 'ITEM2' }}), $enc) ; 
		($st,$len,$type,$tag)	= @{$$refto_hash_fmtN{ 'ITEM2' }};
		&cobfile::hexedit_rep(\$buf, $st, $len, &cobfile::char2xx_tosjishex(\$errmsg, $item1, 2));
		($st,$len,$type,$tag)	= @{$$refto_hash_fmtN{ 'ITEM_1' }};
		&cobfile::hexedit_rep(\$buf, $st, $len, &cobfile::char2xx_tosjishex(\$errmsg, $item2, 2));
# -------------------------------------------------------------------
		$$retstr	=	$buf;
	} 
	#### 変更END ########################################################
	return $cobfile::TRUE;
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
#### 変更START
#### 変更END
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
#### 変更START
#### 変更END
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
#### 変更START
#### 変更END
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
#### 変更START
#### 変更END
	return $cobfile::TRUE;
}

# ---------------------------------------------------
#	EXIT-TRUE
# ---------------------------------------------------
1 ; # TRUE
