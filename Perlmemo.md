# Perlメモ

## 関数
| 概要 | 関数 | 返却値 |
| --- | ---- | --- |
| 置換 | $x =~ tr/検索/置換/ | 左辺を変更 |
| 部分文字列 | substr($文字列, 開始, 長さ) | 部分文字列。開始、長さは文字数 |
| 関数名 | (caller 0)[3] | 自身の関数名。関数内で &dbglog() の引数で利用 |
| バイナリを１６進文字列 | \$hexstr = unpack("H*", $hexval) | バイナリREADの結果（$hexval）を１６進文字列に |
| １６進文字列をバイナリ | \$hexval = pack("H*", $hexstr) | １６進文字列をバイナリWRITE |


## エンコード・デコード
### ソース・STDOUT,STDERR
```pl
use utf8;           # スクリプト内の文字を、UTF8 -> 内部コードに変換する
binmode STDOUT, ":utf8" ;
binmode STDERR, ":utf8" ;
```
### 文字コードを指定して、テキストファイルをオープンする
```pl
open my $fh, "<:encoding($dec)", $fname ;
open my $fh, ">:encoding($enc)", $fname ;
```

### ファイルハンドルから入力と、CRLFの削除
```pl
while( my $line = <$gInf_fh> ) {
	chomp($line);	# 改行コードLFを削除
	if(substr($line, length($line) - 1, 1) eq "\r") {	# CRがあれば削除
		chop($line);
	}
}
```

## バイナリファイルを読み込み、１６進文字列にunpackする
```pl
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
```

## １６進文字列を、バイナリにpackしてファイルに書き込む
```pl
if($fname eq '')	{ print STDOUT pack("H*", $rec);}
```


## モジュール分割
### 起動スクリプトを同ディレクトリの、別ファイルをインポートする
```pl
my  $dirname0 = dirname $0;
require "$dirname0" . "/subfile.pl" ;
```

## デバックテクニック
### DBGLOG関数
```pl
my  $Loglevel   = 2;    # output loglevel
our @Msgtag = ("ALL", "CRI", "ERR", "WRN", "INF", "DBG", "FNC", "LV7");
our %Msglevel = (ALL => 0, CRI => 1, ERR => 2, WRN => 3, INF => 4, DBG => 5, FNC => 6, LV7 => 7 ) ;
sub setLoglevel { return ($Loglevel = $_[0]); }
sub getLoglevel { return $Loglevel; }

sub	dbglog {
	my	($msglevel, @msg)	=	@_;
# dbglogの呼び元情報
    my ($package_name, $file_name, $line) = caller;
    if($msglevel eq "") {  die "!!DIE msglevel($msglevel) is null, $package_name,$file_name,$line:$!";  }

    ($msglevel > 7 || $msglevel < 0) && die "!!DIE msglevel invalid:$msglevel:$!";
    if($msglevel <= $Loglevel) {
        foreach my $msg(@msg) {
			if($msglevel eq $Msglevel{'ALL'}) { printf STDERR ("!!%s::%s\n", $Msgtag[$msglevel], $msg);
			} else {                            printf STDERR ("!!%s:%s,%s:%s\n", $Msgtag[$msglevel], ($file_name,$line),$msg);}
        }
    }
    return $TRUE;
}

my $myname = (caller 0)[3]
&dbglog($Msglevel{'ALL'}, ("MSG1", "MSG2"));
&dbglog($Msglevel{'ERR'}, "$myname,err ot_recfm:$otrecfm");
```

| pri | loglevel | 処理継続 | 用途 |
| --- | ---- | --- | --- |
| ALL | 0 | ○ | JOB開始、終了 |
| CRI | 1 | × | 即時、die |
| ERR | 2 | × | 終了処理をして、ABENDする |
| WRN | 3 | ○ | エラー回復して、処理継続 |
| INF | 4 | ○ | 処理状況 |
| DBG | 5 | ○ | デバック出力 |
| FNC | 6 | ○ | 詳細なデバッグ |
| LV7 | 7 | ○ | (未定義) |

### ERR-MSGの統一
```pl
our %Errcd = (NUM => 'ERR(NUM)', FILE => 'ERR(FIL)');
&dbglog($Msglevel{'ERR'}, "$myname,$Errcd{FIL}:not found:$fname");
```


## その他
### 構造体

- 構造体の定義
```pl
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

```

- 構造体のインスタンス化と値設定
```pl
my $Otfile = Fctrl->new();		# $Otfileはリファレンス型として定義されている
$Otfile->fname( 'FNAME' );		# 値の設定

sub	setDCB {
	my	($ref, $fname, $recfm, $lrecl, $decenc)	=	@_;
	if(defined($fname))	{ $ref->fname($fname);}
	if(defined($recfm)) { $ref->recfm($recfm);}
	if(defined($lrecl)) { $ref->lrecl($lrecl);}
	if(defined($decenc)){ $ref->decenc($decenc);}
	return $TRUE;
}

&setDCB($Otfile, 			# ref to Fctrl
	$cobfile::gOpt_otf,		# fname
	'T',					# recfm
	'',						# lrecl
	'utf8'					# encode
);

```

### オプション
```pl
use Getopt::Long 'GetOptions';
our %gOpts = ();
GetOptions( \%gOpts,
  'recfm=s' ,
  'lrecl=i' ,
  'inf=s' , 
  'otf=s' ,
  'dmp=s' ,
  'edit=s' ,
  'logl=s' ,
  'req=s' ,
  'iferr=s' ,
  'help'
);

if( defined($gOpts{'help'}) ) {
	# --help 指定あり
} else {
	# --help 指定なし
}
```

### 配列の全要素を処理する、foreach
```pl
foreach my $msg(@msg) {
	print $msg;
}
```

### ハッシュの全要素を処理する, 
```pl
while(my ($key,$val) = each(%gOpts)) {
	print "$key = $val\n";
}

foreach my $key(keys(%gOpts)) {
	print $key;
	print $gOpts{$key};
}
```

