/*
 ***********************************************************************
 *	Revision 1.9  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 *
 ***********************************************************************
 *
 *	NAME		:	bincmp.c
 *	SYNTAX		:
 *	DESCRIPTION	:	COBOLファイルのバイナリコンペア
 *	BUGS		:
 *	HISTORY		:
        2006/04/01	Ver.0.0-00	初版作成
        $Idのテスト
 *
 */

/* 修正履歴
 */

#include    "cobfile.h"
#include    <stdio.h>
#include    <stdlib.h>
#include    <string.h>
#include    <ctype.h>

#define     MAX_BUF     32768
#define     MAX_BUF2    65536
#define     LINE_MAX    0x40        /* HEXダンプサイズで指定するので、実データは２分の１	*/

int     usage(void)
{
        fprintf(stderr, "bincmp : Binary file compare\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "bincmp fxxx  infile1 infile2  : for Fiexed-length lrecl=xxx \n");
        fprintf(stderr, "bincmp vx    infile1 infile2  : for Variable-length \n");
        fprintf(stderr, "       vh    vbfile for HOST-TYPE \n");
        fprintf(stderr, "       vn    vbfile for NetCOBOL-IA64-TYPE \n");
        return 0;
}

int     hexdmp(char *xbuf, unsigned char *buf, int ll)
{
        int i;
        int ii;

        for(i = 0; i < ll; i++)
        {
                ii  =   i * 2;
                sprintf(xbuf + ii, "%02X", buf[i]);
        }
        return 0;
}

int     difprt(unsigned char *xbuf1, int lrecl1, unsigned char *xbuf2, int lrecl2, char *in_fname1, char *in_fname2, int lcount)
{
        char prbuf1[MAX_BUF2];
        char prbuf2[MAX_BUF2];
        int i, ii, j;
        int maxl;

        if(lrecl1 < lrecl2)
        {
                for(i = 0; i < lrecl1; i++)
                {
                        prbuf1[i]   =   xbuf1[i];
                        if( xbuf1[i] == xbuf2[i] )  { prbuf2[i] = ' '; }
                        else                        { prbuf2[i] = xbuf2[i]; }
                }
                for(i = lrecl1; i < lrecl2; i++)
                {
                        prbuf1[i]   =   '.';
                        prbuf2[i]   =   xbuf2[i];
                }

        }
        else                            /* lrecl1 >= lrecl2 */
        {
                for(i = 0; i < lrecl2; i++)
                {
                        prbuf1[i]   =   xbuf1[i];
                        if( xbuf1[i] == xbuf2[i] )  { prbuf2[i] = ' ';  }
                        else                        { prbuf2[i] = xbuf2[i]; }
                }
                for(i = lrecl2; i < lrecl1; i++)
                {
                        prbuf1[i]   =   xbuf1[i];
                        prbuf2[i]   =   '.';
                }
        }

/* */
        printf("\n");
        printf("lines : %d\n", lcount);
        printf("     ");
        printf("0 1 2 3 4 5 6 7 8 9 A B C D E F 0 1 2 3 4 5 6 7 8 9 A B C D E F \n");   /* LINE_MAX = 0x40	*/
/*
    printf("0 1 2 3 4 5 6 7 8 9 a b c d e f 0 1 2 3 4 5 6 7 8 9 a b c d e f \n");
 */
        maxl    =   (lrecl1 > lrecl2 ? lrecl1 : lrecl2);
        ii = 0;
        printf("%04X>", ii/2);
        for(i = 0; i < maxl; i++)
        {
                if((i != 0) && (i % LINE_MAX) == 0)         /* ０以外で、Linemaxごとに	*/
                {                                           /* 下段を出力				*/
                        printf("\n");                           /* 上段を改行して		*/
                        printf(".... ");                        /* 下段のアドレス部		*/
                        for(j = ii; j < i; j++)
                        {                                       /* 下段を出力		*/
                                printf("%c", prbuf2[j]);
                        }
                        ii  =   i;
                        printf("\n");                           /* 下段を出力終わって、改行	*/
                        printf("%04X ", ii/2);                  /* アドレス部（上段）		*/
                }
                printf("%c", prbuf1[i]);                    /* 上段を出力		*/
        }
        /* 残った下段を出力			*/
        printf("\n");                                           /* 上段を改行して		*/
        printf("....<", ii / 2);                                /* 下段のアドレス部		*/
        for(j = ii; j < maxl; j++)
        {
                printf("%c", prbuf2[j]);                        /* 下段を出力		*/
        }
        printf("\n");                                           /* 下段を出力終わって、改行	*/

        return 0;
}

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	固定長の１レコードを読み込む。
 *	ARGMENT		:
        buf		o	読込バッファ
        l		o	読み込んだ長さ（COOBLデータ長）
        fp		i	読込ファイルポインタ
 *	RETURN		:	物理ファイルベースで読込んだ長さ。
 *	HINT		:	読込みしたレコードの途中にＥＯＦがあると、ＥＯＦを返却
 *  20221127    :   最終レコードREADでEOFが返却されていたが、
 *                  最終レコードではEOFを返却しない、次のREADで返却するように修正
 * --------------------------------------------------------------------
 */
int     freadFF(unsigned char *buf, int *l, FILE *fp)
{
		if(feof(fp)) {
            return FREAD_EOF;
		} else {
	        fread(buf, *l, 1, fp);
            return *l;
		}
}

int main(int argc, char *argv[])
{
        unsigned char buf1[MAX_BUF];
        unsigned char buf2[MAX_BUF];
        unsigned char xbuf1[MAX_BUF2];
        unsigned char xbuf2[MAX_BUF2];

        int eof1, eof2;
        int lrecl1, lrecl2;
        FILE    *fpin1, *fpin2;
        char    *in_fname1, *in_fname2;

        char recfm;
        int vbmode;
        int i,j,k,l,m;
        long diff;
        long lcount;
		int	rtn;

        if(argc < 2) {
                usage();
                exit(-1);
        }

        switch (*argv[1]) {
        case 'f':
        case 'F':
                lrecl1  = atoi( argv[1]+1 );
                lrecl2  = lrecl1;
                recfm   = 'F';
                break;
        case 'v':
        case 'V':
                lrecl1  = 0;
                lrecl2  = 0;
                recfm   = 'V';
                switch( *(argv[1] + 1) )
                {
                case 'h':
                        vbmode  =   VB_HOST_BIG;
                        break;
                case 'n':
                        vbmode  =   VB_NETC_LTL;
                        break;
                default:
                        fprintf(stderr, "vbmode is incorrect\n");
                        exit(-1);
                }
                break;
        default:
                usage();
                exit(-1);
        }

        in_fname1   =   argv[2];
        in_fname2   =   argv[3];

        if( (fpin1 = fopen(in_fname1, "rb")) == NULL) {
                fprintf(stderr, "Cannot open file[%s]\n", in_fname1);
                usage();
                exit(-1);
        }
        if( (fpin2 = fopen(in_fname2, "rb")) == NULL) {
                fprintf(stderr, "Cannot open file[%s]\n", in_fname2);
                usage();
                exit(-1);
        }


        eof1    =   0;
        eof2    =   0;
        diff    =   0;
        lcount  =   0;

        while( eof1 == 0 || eof2 == 0 )
        {
                if(recfm == 'V') {
                        if( eof1 == 0 && freadV(buf1, &lrecl1, fpin1, vbmode) == FREAD_EOF)
                        {
                                lrecl1 = 0;     eof1 = 1;
                        }

                        if( eof2 == 0 && freadV(buf2, &lrecl2, fpin2, vbmode) == FREAD_EOF)
                        {
                                lrecl2 = 0;     eof2 = 1;
                        }
                } else {
                        if( eof1 == 0 && freadFF(buf1, &lrecl1, fpin1) == FREAD_EOF)
                        {
                                lrecl1 = 0;     eof1 = 1;
                        }

                        if( eof2 == 0 && freadFF(buf2, &lrecl2, fpin2) == FREAD_EOF)
                        {
							    lrecl2 = 0;     eof2 = 1;
                        }
                }
                lcount++;

#ifdef  DBG
                printf("[%c]%d: %d %d %d %d\n", recfm, lcount, eof1, eof2, lrecl1, lrecl2);
#endif

                if(eof1 != 0  && eof2 != 0)
                {
                        lcount--;
                        break;
                }

                if( lrecl1 != lrecl2 )                  /* lrecl相違、またはどちらかがＥＯＦ */
                {
                        diff++;
                        hexdmp(xbuf1, buf1, lrecl1);
                        hexdmp(xbuf2, buf2, lrecl2);
                        difprt(xbuf1, lrecl1 * 2, xbuf2, lrecl2 * 2, in_fname1, in_fname2, lcount);
                }
                else                                    /* lreclが同じ */
                {
                        if(memcmp( buf1, buf2, lrecl1) != 0)        /* 内容相違 */
                        {
                                diff++;
                                hexdmp(xbuf1, buf1, lrecl1);
                                hexdmp(xbuf2, buf2, lrecl2);
                                difprt(xbuf1, lrecl1 * 2, xbuf2, lrecl2 * 2, in_fname1, in_fname2, lcount);
                        }
                }
        }

		if(diff != 0) {
			rtn	=	1;
		}
        printf("bincmp: Binary file compare\n");
        printf("file1 : %s\n", in_fname1);
        printf("file2 : %s\n", in_fname2);
        printf("total : %d records\n", lcount);
        printf("diffs : %d records\n", diff);
        printf("return: %d\n", rtn);

        fclose( fpin1 );
        fclose( fpin2 );

        return rtn;
}

