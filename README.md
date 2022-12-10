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
| ファイルのコンペア | bincmp.c | o | bincmp.txt |
| 可変長フィルの形式変換 | binconv.c | o | binconv.txt | 
| ファイルのコピー、ダンプ（AMSもどき） | bincopy.c | o | bincopy.txt |
| ファイルのHEXダンプ（ファイル単位） | hexdp.c | x | hexdp.txt |

*1 : Perlの処理概要で説明

## Perlの処理概要
### スクリプトに共通なオプション
recfm=F : 入力ファイルが固定長ファイルであることを示す。lreclバイトでレコートを区切る。
recfm=V : 入力ファイルが可変長ファイルであることを示す。データ部の前後にレコード長情報部が付加された構造。レコード長情報部でレコードを区切る。
- レコード = レコード長情報部 + データ部 + レコード長情報部
- レコード長情報部 = 長さ情報 + 0x0000（２バイト）の４バイト
- 長さ情報 = リトルエンディアンの２進数２バイト 

inf : 入力ファイルのファイル名。
otf : 出力ファイルのファイル名。指定を省略、または```otf=STDOUT```を指定すると、標準出力へ出力する。
logl : DBG情報の出力レベル。

- DBG情報は、標準エラー出力へ出力する、
- ```CRI|ERR|WRN|INF|DBG|FNC```
- デフォルトは```ERR```

### ファイルのHEXダンプ
recfm,lreclに従い入力ファイルを読み込み、HEXダンプする

```sh
./hexdpM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] 
./hexdpM.pl --recfm=V --inf=INFILE [--otf=OTFILE]
```

dmp=lst : HEXダンプをリスト形式で出力
dmp=hexstr : HEXダンプをタイトルや区切りなし、レコード単位で改行して出力、hexputM.plの入力取得での利用を想定。

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
hexfmtM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] [--req=sub.pl] [--iferr=hex]
hexfmtM.pl --recfm=V --inf=INFILE [--otf=OTFILE] [--req=sub.pl] [--iferr=hex]
```
- iferr指定あり（引数なし） : 分解した項目が形式不正の場合、&H+１６進文字列で出力する。
- iferr指定なし :　分解した項目が形式不正の場合、空文字となりなにも出力されない。

### ファイル編集
レコードを項目分解し、編集する。
項目情報はreqオプションで指定するファイルに記述する。reqオプション省略時は、```hexedit_sub.pl```がデフォルト。

```sh
hexeditM.pl --recfm=F --lrecl=LRECL --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex]
hexeditM.pl --recfm=V --inf=INFILE [--otf=OTFILE] --edit=edit [--req=sub.pl] [--iferr=hex]
```
- iferr指定あり（引数なし） : 分解した項目が形式不正の場合、&H+１６進文字列で出力する。
- iferr指定なし :　分解した項目が形式不正の場合、空文字となりなにも出力されない。


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

#### フォーマット名の判定
変数```$fmdid```にフォーマット名を設定する。

```pl
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

