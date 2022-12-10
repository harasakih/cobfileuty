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
項目情報はreqオプションで指定するファイルに記述する。reqオプション省略時は、```hexfmt_sub.pl```がデフォルト。

```sh
hexfmtM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] [--req=sub.pl] [--iferr=hex|null]
hexfmtM.pl --recfm=V --inf=INFILE [--otf=OTFILE] [--req=sub.pl] [--iferr=hex|null]
```
- iferr=hex : 分解した項目が形式不正の場合、&H+１６進文字列で出力する。
- iferr=null : 分解した項目が形式不正の場合、空文字となり何も出力しない。
	- デフォルトは```null```

### ファイル編集
レコードを項目分解し、編集する。
項目情報はreqオプションで指定するファイルに記述する。reqオプション省略時は、```hexedit_sub.pl```がデフォルト。

```sh
hexeditM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex|null]
hexeditM.pl --recfm=V --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex|null]
```
- iferr=hex : 分解した項目が形式不正の場合、&H+１６進文字列で出力する。
- iferr=null :　分解した項目が形式不正の場合、空文字となり何も出力しない。
	- デフォルトは```null```

## 項目情報
``hexfmtM.pl, hexeditM.pl``で使用する項目情報は、このファイルを参考とし、``#### 変更START ▼▼▼▼▼▼`` から ``#### 変更END   ▲▲▲▲▲▲`` で囲まれた箇所を修正する。
Perlのコードを書くため、Perl文法に従い記述する。

### hexfmt_sub.pl

#### 項目情報の定義
````pl
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
my	%hash_for_array_fmts = (
	FMT1 => \@array_fmt1, FMT2 => \@array_fmt2
);
````

- ```FMT1 => \@array_fmt1``` フォーマット名を定義する。右辺は、```my @array_fmt1```で項目の定義をした配列へのリファレンス。
- ```[0,4,'ZD','item11']``` の形式で、開始位置（ゼロ基準）、項目長（バイト）、COBOL項目属性、項目見出し、を指定する

#### フォーマット名の判定:getfmtid()
変数```$fmdid```にフォーマット名を設定する。

```pl
# getfmtid()
	my	@wk_hantei = (0, 4, 'XX', '');
	my	$hantei	=	&cobfile::getitem($refin, \$myerrmsg, $hexstr, @wk_hantei, $decenc);
	my	$fmtid = '';
	if   ($hantei eq 'F0F1F2F3') {	$fmtid	=	"FMT1";	} 
	elsif($hantei eq 'F3F5F6F7') {	$fmtid	=	"FMT1";	} 
	elsif($hantei eq 'F1F2F3F4') {	$fmtid	=	"FMT2";	} 
#	elsif($hantei eq 'F1F6F7F8') {	$fmtid	=	"FMT2";	} 
	else { ; }
```

- 変数```$fmtid```に対して、```$fmtid = "FMT1"```のように、フォーマット名を設定する。
	- 右辺は、```%hash_for_array_fmts```のKEYのどれかであること。(ex:FMT1,FMT2)
- フォーマット名を判定する項目は、```&cobfile::getitem```を用いて取得する。
	- 上記の項目は、```my @wk_hantei = (0, 4, 'XX', '')```のように、開始位置、項目長、COBOL項目即成、項目見出し(空文字列''で可)、で指定する。
	- 複数項目の組み合わせで判定する場合は、```my @wk_hantei =```から```my $hantei	=```の行を変数名を変えて、同じように増殖する。
	- ```$hantei```は、```@wk_hantei```のCOBOL属性にあわせて判定条件を記述する。(ex:XXは１６進文字列)。

### hexedit_sub.pl

#### 項目情報の定義(--edit=edit用)
```pl 
## レコードフォーマット＃１
my	%hash_fmt1	=	(
	ITEM1 => [0,4,'ZD','item11'], 
	ITEM2 => [4,4,'PD','item12'], 
	ITEM3 => [8,4,'CH','item13']
);
my	%hash_fmt2	=	(
	ITEM1 => [0,4,'ZD','item21'], 
	ITEM2 => [4,4,'PD','item22'], 
	ITEM3 => [8,4,'CH','item23'], 
	ITEM4 => [12,4,'XX','item24'],
	ITEM5 => [16,12,'CH','item25']
);
## レコードフォーマットへのリファレンス
my	%hash_for_hash_fmts = (
	FMT1 => \%hash_fmt1, FMT2 => \%hash_fmt2
);
```

- ```FMT1 => \%hash_fmt1``` フォーマット名を定義する。右辺は、```my %hash_fmt1```で項目の定義をしたハッシュへのリファレンス。
- ```ITEM1 => [0,4,'ZD','item11']``` の形式で、「項目名」と「開始位置（ゼロ基準）、項目長（バイト）、COBOL項目属性、項目見出し」、を指定する

#### 項目情報の定義(--edit=fmtpr用)
```pl
my	@array_fmt1	=	(
	[0,4,'ZD','item11'], 
);
my	@array_fmt2	=	(
	[0,4,'ZD','item21'], 
);
## レコードフォーマットへのリファレンス
my	%hash_for_array_fmts = (
	FMT1 => \@array_fmt1, FMT2 => \@array_fmt2
);
```
```hexfmt_sub.pl```を参照。
```edit=fmtpr```時に、この箇所で指定した順に出力するため指定する。ハッシュを使って出力すると、キーソート順での出力しかできず、記載順の出力ができないため、重複記述となるがやむなし。

#### フォーマット名の判定:getfmtid()

```pl
# getfmtid()
	my	@wk_hantei = (0, 4, 'XX', '');
	my	$hantei	=	&cobfile::getitem($refin, \$myerrmsg, $hexstr, @wk_hantei, $decenc);
	my	$fmtid = '';
	if   ($hantei eq 'F0F1F2F3') {	$fmtid	=	"FMT1";	} 
```

```hexfmt_sub.pl```を参照。

#### 項目編集（フォーマット毎の分岐）:editrec()
次の箇所で、フォーマット名の処理ロジックを記述する
- 入力は ```$hexstr``` 、出力は ```$$retstr`` で固定。
- 出力は、 ```$$``` と、＄が二重であることに注意。

```pl
# editrec()
	my	$refto_hash_fmtN	= $hash_for_hash_fmts{ $whichfmt };
....
	if($whichfmt eq "FMT1") {
		フォーマット名が FMT1 の時の編集処理を書く書く。 。
		下記は 入力をそのまま 出力する例。 
# -------------------------------------------------------------------
		$$retstr	=	$hexstr;
	} elsif($whichfmt eq "FMT2") {
		フォーマット名が FMT2 の時の編集処理を書く書く。
		入力レコードを変更する時は、 $buf に転送後に編集し、$buf を $$retstr　に設定する。
		my	$item3	=	&cobfile::getitem($refin, \$errmsg, $hexstr, (@{$$refto_hash_fmtN{ 'ITEM3' }}), $enc) ; 
# -------------------------------------------------------------------
		my	$buf	=	$hexstr;
		($st,$len,$type,$tag)	= @{$$refto_hash_fmtN{ 'ITEM3' }};
		&cobfile::hexedit_rep(\$buf, $st, $len, &cobfile::char2xx_tosjishex(\$errmsg, 'あい', 4));
		$$retstr	=	$buf;
	}
```

#### 項目編集（分岐後の項目の変更）:editrec()
下記は、フォーマット名 ```FMT2``` の項目名 ```ITEM3``` を変更する例

```pl
# editrec()
A	my	$refto_hash_fmtN	= $hash_for_hash_fmts{ $whichfmt };
.....
	} elsif($whichfmt eq "FMT2") {
B		my	$item3	=	&cobfile::getitem($refin, \$errmsg, $hexstr, (@{$$refto_hash_fmtN{ 'ITEM3' }}), $enc) ; 
# -------------------------------------------------------------------
C		my	$buf	=	$hexstr;
D-1		($st,$len,$type,$tag)	= @{$$refto_hash_fmtN{ 'ITEM3' }};
D-2		($st,$len,$type,$tag)	= @{$hash_fmt2{'ITEM3'}};
E		&cobfile::hexedit_rep(\$buf, $st, $len, &cobfile::char2xx_tosjishex(\$errmsg, 'あい', 4));
	}
```
- 行A : ```$whichfmt```に設定されているフォーマット名から、項目属性のハッシュ）を参照するための```$refto_hash_fmtN```を設定する。
- 行B : ```$item3``` に ```FMT2のITEM3```の内容を１６進文字列で取得する。上記例では未使用。
- 行C : ```$buf```は変更用のワーク。
- 行D-1 : ```@{$$refto_hash_fmtN{ 'ITEM3' }}```で、FMT2のITEM3の項目属性情報を取得する。(ref 行A)
- 行D-2 : FMT2の項目情報```$hask_fmt2```を直接指定することも可。
- 行E : ```&cobfile::hexedit_rep()```で、```$buf```の内容を変更する。
	- １番目の引数、```\$buf``` : call by refferenceにして、bufの内容を変更する。
	- ２、３番目の引数、```$st, $len``` : bufの中で変更する箇所の、開始位置、項目長（バイト）。
	- ４番目の引数は変更値を１６進文字列で渡す。上記例では、’あい'のSJIS文字コードを１６進文字列で渡している。
		- ```&cobfile::char2xx_tosjishex()```は、Perlソースに書かれた文字のSJISの文字コードを返す関数。




