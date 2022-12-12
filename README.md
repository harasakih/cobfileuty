# cobfileuty

## コマンド一覧(perl-main)
RECFM:COBOLファイルのレコード単位を識別し、レコード単位の処理を行う。

| 概要 | スクリプト名 | RECFM | 使い方 |
| --- | --- | -- | --- |
| == Perl == | | | |
| ファイルのHEXダンプ | hexdpM.pl | o | *1 |
| ファイル作成 | hexputM.pl | o | *1 |
| ファイル編集 | hexeditM.pl | o | *1 |
| フォーマットダンプ | hexfmtM.pl | o | *1 |
| == C言語 == | | |
| ファイルのコンペア | bincmp.c *2 | o | bincmp.txt |
| 可変長フィルの形式変換 | binconv.c *2 | o | binconv.txt | 
| ファイルのコピー、ダンプ（AMSもどき） | bincopy.c *2 | o | bincopy.txt |
| ファイルのHEXダンプ（ファイル単位） | hexdp.c *2 | x | hexdp.txt |

*1 : Perlの処理概要で説明
*2 : 添付の```makefile``にてmake

## Perlの処理概要
### スクリプトに共通なオプション
- recfm=F : 入力ファイルが固定長ファイルであることを示す。lreclバイトでレコードを区切る。
- recfm=V : 入力ファイルが可変長ファイルであることを示す。データ部の前後にレコード長情報部が付加された構造。レコード長情報部でレコードを区切る。
	- レコード = レコード長情報部 + データ部 + レコード長情報部
	- レコード長情報部 = 長さ情報 + 0x0000（２バイト）の４バイト
	- 長さ情報 = リトルエンディアンの２進数２バイト 

- inf : 入力ファイルのファイル名。
- otf : 出力ファイルのファイル名。指定を省略、または```otf=STDOUT```を指定すると、標準出力へ出力する。
- logl : DBG情報の出力レベル。
	- DBG情報は、標準エラー出力へ出力する、
	- ```CRI|ERR|WRN|INF|DBG|FNC```
	- デフォルトは```ERR```

### ファイルのHEXダンプ
recfm,lreclに従い入力ファイルを読み込み、HEXダンプする

```sh
./hexdpM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] [--dmp=lst|hexstr]
./hexdpM.pl --recfm=V --inf=INFILE [--otf=OTFILE] [--dmp=lst|hexstr]
```

- dmp=lst : HEXダンプをリスト形式で出力
- dmp=hexstr : HEXダンプをタイトルや区切りなし、レコード単位で改行して出力、hexputM.plの入力取得での利用を想定。
	- デフォルトは```lst```

### ファイル作成【単純なバイナリ化、パディングなし】
入力ファイルは改行区切りで読み込み、１６進文字列をバイナリ化してrecfm,lreclに従い出力する。

```sh
hexputM.pl --recfm=F --lrecl=LRECL --inf=INFILE --otf=OTFILE
hexputM.pl --recfm=V --inf=INFILE --otf=OTFILE
```
- recfm=F, lrecl=xx, pad指定なし : lreclは無視され、パディング・超過分削除を行わず、レコードを出力する。
- recfm=V : lreclは指定不可,padは無視される。

### ファイル作成【lrecl優先、パディングあり】
``recfm=F,lrecl=xx,pad=hh``の時、lrecl×nレコードのファイルを作成する。

```sh
hexputM.pl --recfm=F --lrecl=LRECL --inf=INFILE --otf=OTFILE --pad=hh
```
- 入力 < lreclの時 : lreclに満たない部分を0xhhでパディングしてレコードを出力する。
- 入力 > lreclの時 : 超過部分を除いてレコードを出力する。


### フォーマットダンプ
レコードを項目分解し、見出しをつけてダンプ出力する。

```sh
hexeditM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] --edit=fmtpr [--req=sub.pl] [--iferr=hex|null|die]
hexeditM.pl --recfm=V --inf=INFILE [--otf=OTFILE] --edit=fmtpr [--req=sub.pl] [--iferr=hex|null|die]
```
### ファイル編集
レコードを項目分解し、編集する。

```sh
hexeditM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex|null|die]
hexeditM.pl --recfm=V --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex|null|die]
```

- req=FILENAME : 項目情報のファイル名を指定する。省略時は、```hexedit_sub.pl```がデフォルト。
- iferr=hex : 分解した項目が形式不正の場合、&H+１６進文字列で出力する。
- iferr=null :　分解した項目が形式不正の場合、空文字となり何も出力しない。
- iferr=die : 分解した項目が形式不正の場合、即時終了。
	- デフォルトは```null```

## 項目情報
``hexeditM.pl``で使用する項目情報は、このファイルを参考とし、``#### 変更START ▼▼▼▼▼▼`` から ``#### 変更END   ▲▲▲▲▲▲`` で囲まれた箇所を修正する。
Perlのコードを書くため、Perl文法に従い記述する。

### hexedit_sub.pl
#### 項目情報の定義(--edit=edit用)
```pl 
## レコードフォーマット情報（編集用）
my	%hash_fmt1	=	(
	ITEM1 => [0,2,'ZD','item11'], 	# 3031
	ITEM2 => [2,2,'BB','item12'], 
	ITEM3 => [4,4,'PD','item13'],
	ITEM4 => [8,4,'CH','item14']
);
my	%hash_fmt2	=	(
	ITEM1 => [0,2,'ZD','item21'], 	# 3032
	ITEM2 => [2,2,'BL','item22'], 
	ITEM3 => [4,4,'PD','item23'],
	ITEM4 => [8,4,'CH','item24'],
	ITEM5 => [12,8,'CH','item35']
);
## レコードフォーマット管理情報（編集用）：レコードフォーマットへ情報（編集用）へのリファレンス
our	%hash_for_hash_fmts = (
	FMT1 => \%hash_fmt1, FMT2 => \%hash_fmt2
);
```

- ```FMT1 => \%hash_fmt1``` フォーマット名を定義する。右辺は、```my %hash_fmt1```で項目の定義をしたハッシュへのリファレンス。
- ```ITEM1 => [0,2,'ZD','item11']``` の形式で、「項目名」と「開始位置（ゼロ基準）、項目長（バイト）、COBOL項目属性、項目見出し」、を指定する


#### 項目情報の定義(--edit=fmtpr用)
```pl
## レコードフォーマット情報（ダンプ用）
my	@array_fmt1	=	(
	[0,2,'ZD','item11'], 	# 3031
	[2,2,'BB','item12'], 
	[4,4,'PD','item13'],
	[8,4,'CH','item14']
);
my	@array_fmt2	=	(
	[0,2,'ZD','item21'], 	# 3032
	[2,2,'BL','item22'], 
	[4,4,'PD','item23'],
	[8,4,'CH','item24'],
	[12,8,'CH','item35']
);
## レコードフォーマット管理情報（ダンプ用）：レコードフォーマットへ情報（ダンプ用）へのリファレンス
our	%hash_for_array_fmts = (
	FMT1 => \@array_fmt1, FMT2 => \@array_fmt2
);
```

```edit=fmtpr```時に、この箇所で指定した順に出力するため指定する。ハッシュを使って出力すると、キーソート順での出力しかできず、記載順の出力ができないため、重複記述となるがやむなし。

- ```FMT1 => \@array_fmt1``` フォーマット名を定義する。右辺は、```my @array_fmt1```で項目の定義をした配列へのリファレンス。
- ```[0,2,'ZD','item11']``` の形式で、開始位置（ゼロ基準）、項目長（バイト）、COBOL項目属性、項目見出し、を指定する

#### フォーマット名の判定:getfmtid()
```pl
	my	@wk_hantei = (0, 2, 'ZD', '');
	my	$hantei	= &cobfile::getitem($refin, \$myerrmsg, $hexstr, @wk_hantei, $decenc);
	my	$fmtid = '';
	if   ($hantei eq "1") {	$fmtid = "FMT1"; } 
	elsif($hantei eq "2") {	$fmtid = "FMT2"; } 
	else { $fmtid = ''; }
```

- 変数```$fmtid```に対して、```$fmtid = "FMT1"```のように、フォーマット名を設定する。
	- 右辺は、```%hash_for_array_fmts```のKEYのどれかであること。(ex:FMT1,FMT2)
- フォーマット名を判定する項目は、```&cobfile::getitem```を用いて取得する。
	- 上記の項目は、```my @wk_hantei = (0, 2, 'ZD', '')```のように、開始位置、項目長、COBOL項目即成、項目見出し(空文字列''で可)、で指定する。
	- 複数項目の組み合わせで判定する場合は、```my @wk_hantei =```から```my $hantei	=```の行を変数名を変えて、同じように増殖する。
	- ```$hantei```は、```@wk_hantei```のCOBOL属性にあわせて判定条件を記述する。(ex:XXは１６進文字列)。

#### 項目編集（フォーマット毎の分岐）:editrec()
次の箇所で、フォーマット名の処理ロジックを記述する
- 入力は ```$hexstr``` 、出力は ```$$retstr`` で固定。
- 出力は、 ```$$retstr``` と、＄が二重であることに注意。

```pl
# editrec()
# 変更は $buf に対して行う
	my	$buf = $hexstr;
	if($whichfmt eq "FMT1") {
# -------------------------------------------------------------------
# FMT1,ITEM2の参照
		($st,$len,$type,$tag)	= @{$ref_hash_hash->{ 'FMT1' }->{'ITEM2'}};
		my	$item2	=	&cobfile::getitem($refin, \$errmsg, $hexstr, ($st,$len,$type,$tag), $enc) ;
# FMT1,ITEM2の変更(ワーク)
		$item2 += 100;
# ワークを１６進文字列に変換
		my	$bb = &cobfile::num2bb(\$errmsg, $item2, $len);
# 元の位置、長さで置換
		&cobfile::hexedit_rep(\$buf, $st, $len, $bb);
# -------------------------------------------------------------------
# $buf を返却用変数 $$retstr に設定する
		$$retstr	=	$buf;
	} elsif($whichfmt eq "FMT2") {
# -------------------------------------------------------------------
# FMT2の時の編集（省略）
		$$retstr	=	$buf;
	} else {
# -------------------------------------------------------------------
# FMT不明時の動作
		$$retstr	=	$hexstr;
	}
```

