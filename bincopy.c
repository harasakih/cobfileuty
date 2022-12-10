/*
 ***********************************************************************
 *	Revision 1.2  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 *	
 ***********************************************************************
 *
 *	バイナリファイルをコピーする
 *  <0>     <1>   <2>    <3>      <4>   <5>    <6>
 *	bincopy v     cp    infile outfile (-snnn -cmmm)		for VB-File
 *	bincopy fxxx  cp    infile outfile (-snnn -cmmm)		for FB-File lrecl=xxx
 *  bincopy v|fxx dp	infile (-snnn -cmmm)
 *		-s skip  nnn records
 *		-c count mmm records
 */

/* 修正履歴
	2005/10/18	freadx のあとのfeofが冗長なので、freadxの戻り値で判定
	2006/03/09	freadFのとき、ＥＯＦ判定がもれていた
				ファイルサイズを求めて表示する
	2006/03/23	終了判定は、ファイルサイズでする。
				ファイルサイズ判定のバグ対応。読込、書込みは長さを返却する。
				ホスト可変長、NetCOBOL可変長に対応。
	2006/04/01	ＥＯＦでの終了判定をコメント化
	2006/04/01	終了判定は次とする。
				①読んだレコードのＥＯＦ
				②読込済サイズ　＞　ファイルサイズ
				×固定長で、最終レコードの途中にＥＯＦがある場合のバグを解決するため、
				　固定長は読込済サイズを、ＬＲＥＣＬ（≠ＦＲＥＡＤＦの返却）をする。
*/

#include	"cobfile.h"
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<ctype.h>

#define		MAX_BUF		32768

int		usage(void)
{
	fprintf(stderr, "bincopy : Binary file copy & dmp, Host type variable length \n");
	fprintf(stderr, "\n");
	fprintf(stderr, "bincopy vx     cp    infile outfile (-snnn -cmmm)  for Variable-length \n");
	fprintf(stderr, "        vh           vbfile for HOST-TYPE \n");
	fprintf(stderr, "        vn           vbfile for NetCOBOL-IA64-TYPE \n");
	fprintf(stderr, "bincopy fxxx   cp    infile outfile (-snnn -cmmm)  for Fiexed-length lrecl=xxx \n");
	fprintf(stderr, "bincopy vx|fxx dp    infile (-snnn -cmmm) \n");
	fprintf(stderr, "        -s skip  nnn records \n");
	fprintf(stderr, "        -c count mmm records \n");
	return 0;
}

int	printok(unsigned char c)
{

	if( isalnum( c ) )
	{
		return -1;
	} else {
		return 0;
	}

}

int		fdmp(unsigned char *buf, int ll, char mode)
{
	int				i,j,k,l;
	char			dmpchar[33];
	char			hexdmp[128];
	char			*p;
	char			c;
	int				z;
	
	if(mode == 'V'){
		z	=	0;
	} else {
		z	=	0;
	}

	printf("%04X > ", 0 + z);
	p	=	dmpchar;
	
	
	for(i = 0; i < ll; i++) {
											/*
											 * 32バイトをＨＥＸダンプした時
											 */
		if((i != 0) && (i % 32) == 0) {
			printf(" |");
			for(j = 0, p = dmpchar; j < 32; j++, p++) { putchar( *p ); }
			printf("|");
			p = dmpchar;
			printf("\n%04X : ", i + z);
		}
											/*
											 * １６バイト区切り
											 */
		if((i % 32) != 0 && (i % 16) == 0) { putchar(' '); putchar('-'); putchar(' '); }
											/*
											 * ４バイト区切り
											 */
		if((i % 32) != 0 && (i % 16) != 0 && (i %  4) == 0) { putchar(' ');	}

		printf("%02X", buf[i]);
		c = (char)buf[i];
		
		if( printok( c ) )
		{
			*p = c;
		} else {
			*p = '.';
		}
		p++;
	}
	
	/* のこりを' '出力し */
	l = (i % 32);
	if(l != 0)
	{
		for(i = l; i < 32; i++) {
												/*
												 * １６バイト区切り
												 */
			if((i % 32) != 0 && (i % 16) == 0) { putchar(' '); putchar('-'); putchar(' '); }
												/*
												 * ４バイト区切り
												 */
			if((i % 32) != 0 && (i % 16) != 0 && (i %  4) == 0) { putchar(' ');	}

			printf("  ");
			*p = ' ';
			p++;
		}
	} else {
		;
	}

	printf(" |");
	for(j = 0, p = dmpchar; j < 32; j++, p++) { putchar( *p ); }
	printf("|");

	putchar('\n');
	return 0;
}

int	main(int argc, char *argv[])
{
	unsigned char	buf[MAX_BUF];
	char	*in_fname;
	char	*ot_fname;
	char	mode;
	int		vbmode;
	int		lrecl, ll;		/* lrecl:データ長、ll:fread/fwriteした長さ */
	int		i,j,k,l;
	int		skip;
	int		count;
	FILE	*fpin;
	FILE	*fpot;
	int		dmp;
	long	size;			/* いままでに読んだサイズ		*/
	long	cpsize;			/* 処理サイズ					*/
	long	fsize;			/* ファイルサイズ				*/
	
	if(argc < 2) {
		usage();
		exit(-1);
	}
	
	switch (*argv[1]) {
	case 'f':
	case 'F':
		lrecl	= atoi( argv[1]+1 );
		mode	= 'F';
		break;
	case 'v':
	case 'V':
		lrecl	= 0;
		mode	= 'V';
		switch( *(argv[1] + 1) )
		{
		case 'h':
			vbmode	=	VB_HOST_BIG;
			break;
		case 'n':
			vbmode	=	VB_NETC_LTL;
			break;
		default :
			fprintf(stderr, "vbmode is incorrect\n");
			exit(-1);
		}
		break;
	default:
		usage();
		exit(-1);
	}

	skip	=	0;
	count	=	0;
	if( strcmp(argv[2] , "cp")  == 0)
	{
		in_fname	=	argv[3];
		ot_fname	=	argv[4];
		dmp			=	0;

		for(i = 5; i < argc; i++)
		{
			switch ( *(argv[i]+1) ) {
			case 's':
			case 'S':
				skip	=	atoi( argv[i]+2 );
				break;
			case 'c':
			case 'C':
				count	=	atoi( argv[i]+2 );
			}
		}

		fsize	=	fileSize( in_fname );			/* ファイルサイズをもとめる、ＯＰＥＮ＆ＣＬＯＳＥ */
		if( (fpin = fopen(in_fname, "rb")) == NULL){
			fprintf(stderr, "Cannot open file[%s]\n", in_fname);
			usage();
			exit(-1);
		}
		if( (fpot = fopen(ot_fname, "wb")) == NULL){
			fprintf(stderr, "Cannot open file[%s]\n", ot_fname);
			usage();
			exit(-1);
		}

	}
	else if( strcmp(argv[2], "dp") == 0)
	{
		in_fname	=	argv[3];
		dmp			=	1;
		
		for(i = 4; i < argc; i++)
		{
			switch ( *(argv[i]+1) ) {
			case 's':
			case 'S':
				skip	=	atoi( argv[i]+2 );
				break;
			case 'c':
			case 'C':
				count	=	atoi( argv[i]+2 );
			}
		}

		fsize	=	fileSize( in_fname );			/* ファイルサイズをもとめる、ＯＰＥＮ＆ＣＬＯＳＥ */
		if( (fpin = fopen(in_fname, "rb")) == NULL){
			fprintf(stderr, "Cannot open file[%s]\n", in_fname);
			usage();
			exit(-1);
		}
	} else {
		usage();
		exit(-1);
	}

	/* SKIP */
	size	=	0;
	if( skip > 0) {
		if(mode == 'V') {
			for(i = 0; i < skip; i++) { 
				ll = freadV(buf, &lrecl, fpin, vbmode);
				if(size >= fsize || ll == FREAD_EOF)
				{
					fclose( fpin );
					if(dmp == 0) { fclose( fpot ); }
					exit(-1);
				}
				size	+=	ll;
			}
		} else {
			for(i = 0; i < skip; i++) {
				ll = freadF(buf, &lrecl, fpin);
				if(size >= fsize)	/* 最終レコードの途中のＥＯＦ判定バグを避けるため、freadFの返却値で判定しない	*/
				{
					fclose( fpin );
					if(dmp == 0) { fclose( fpot ); }
					exit(-1);
				}
				size	+=	lrecl;
			}
		}
	}

	cpsize	=	0;
	for(i = 1; 1; i++)
	{
		if((count > 0) && (i > count)) { break; }

		if(mode == 'V') {
			ll = freadV (buf, &lrecl, fpin, vbmode);
			if(size >= fsize || ll == FREAD_EOF) { break; }
			if( dmp == 1) {
				printf("\n>>>> bincopy-fdmpV : RecNo=%d(%08X/%08X): file=%s <<<<\n", i + skip, size, fsize, in_fname);
				printf("LL=%04X(%d)\n", lrecl, lrecl);
				fdmp(buf, lrecl, mode);
			} else {
				fwritV(buf, &lrecl, fpot, vbmode);
			}
			size	+=	ll;
			cpsize	+=	ll;
		} else {
			ll = freadF (buf, &lrecl, fpin);
			if(size >= fsize) { break; }	/* 最終レコードの途中のＥＯＦ判定バグを避けるため、freadFの返却値で判定しない	*/
			if( dmp == 1) {
				printf("\n>>>> bincopy-fdmpF : RecNo=%d(%08X/%08X): file=%s <<<<\n", i + skip, size, fsize, in_fname);
				fdmp(buf, lrecl, mode);
			} else {
				fwritF(buf, &lrecl, fpot);
			}
			size	+=	lrecl;
			cpsize	+=	lrecl;
		}
	}
	
	fclose( fpin );
	if(dmp == 0) { fclose( fpot ); }
	printf("bincopy : %s\n", argv[2]);
	printf("infile  : %s\n", in_fname);
	if( strcmp(argv[2], "cp") == 0) { printf("otfile  : %s\n", ot_fname); }
	printf("Byte's  : %d(%06X)\n", cpsize, cpsize);
	printf("records : %d\n", i - 1);
	
	return 0;
}



