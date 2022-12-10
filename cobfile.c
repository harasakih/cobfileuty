/*
 ***********************************************************************
 *	Revision 1.2  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 ***********************************************************************
 *
 *	NAME		:	cobfile.c
 *	SYNTAX		:	COBOLファイルを扱うための関数
 *	DESCRIPTION	:
 *	BUGS		:
        2006/04/01	freadFのeofは、ファイル別にもっていないので、複数ファイル入力に対応できない。
                    読んだレコードの途中でＥＯＦは、そのままＥＯＦを返却する。
 *	HISTORY		:
        2006/04/01	Ver.0.0-00	bincopy,vbconvなど今までのファイルをまとめた
 *
 */

#include    "cobfile.h"

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	ファイルサイズを調べる
 *	ARGMENT		:
        fname	i	ファイル名
 *	RETURN		:	ファイルサイズ
 * --------------------------------------------------------------------
 */
long fileSize(char *fname)
{
        long fsize;
        FILE *fp;

        /* ファイルサイズを調査 */
        if((fp = fopen(fname,"rb")) == NULL)
        {
                fprintf(stderr, "### ERR !! %s open error ###\n", fname);
                exit(-1);
        }
        fseek(fp,0,SEEK_END);
        fsize = ftell(fp);
        fclose(fp);

        return fsize;
}

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	固定長の１レコードを読み込む。
 *	ARGMENT		:
        buf		o	読込バッファ
        l		o	読み込んだ長さ（COOBLデータ長）
        fp		i	読込ファイルポインタ
 *	RETURN		:	物理ファイルベースで読込んだ長さ。
 *	HINT		:	読込みしたレコードの途中にＥＯＦがあると、ＥＯＦを返却
 * --------------------------------------------------------------------
 */
int     freadF(unsigned char *buf, int *l, FILE *fp)
{
        fread(buf, *l, 1, fp);

        if( feof(fp) ) {
                return FREAD_EOF;
        } else {
                return *l;
        }

}

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	固定長の１レコードを書き込む
 *	ARGMENT		:
        buf		i	書込みバッファ
        l		i	出力する長さ（COOBLデータ長）
        fp		i	ファイルポインタ
 *	RETURN		:	物理ファイルベースで出力した長さ。
 * --------------------------------------------------------------------
 */
int     fwritF(unsigned char *buf, int *l, FILE *fp)
{
        fwrite(buf, *l, 1, fp);
        return *l;
}

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	COBOL可変長の１レコードを読み込む。
 *	ARGMENT		:
        buf		o	読込バッファ
        l		o	読み込んだ長さ（COOBLデータ長）
        fp		i	読込ファイルポインタ
        vbmode	i	可変長モード
 *	RETURN		:	物理ファイルベースで読込んだ長さ。
 * --------------------------------------------------------------------
 */
int     freadV(unsigned char *buf, int *l, FILE *fp, int vbmode)
{
        unsigned char rdw[RDW_LENGTH];
        union   {
                unsigned char c[2];
                unsigned short x;
        } ll;

        /*	RDW部を読んでレコード長を算出	 */
        switch( vbmode ) {
        case VB_HOST_BIG:
                fread(rdw, RDW_LENGTH, 1, fp);
                ll.c[0] = rdw[1];
                ll.c[1] = rdw[0];

                if( feof(fp) ) { return FREAD_EOF; } /* EOFならすぐ戻る */
                *l = ll.x - RDW_LENGTH;         /* データ長 = ll -4 */
                fread(buf, *l, 1, fp);
                return (*l + RDW_LENGTH);
        case VB_NETC_LTL:
                fread(rdw, RDW_LENGTH, 1, fp);
                ll.c[0] = rdw[0];
                ll.c[1] = rdw[1];

                if( feof(fp) ) { return FREAD_EOF; } /* EOFならすぐ戻る */
                *l = ll.x;                      /* データ長はそのまま */
                fread(buf, *l, 1, fp);

                fread(rdw, RDW_LENGTH, 1, fp);
                ll.c[0] = rdw[0];
                ll.c[1] = rdw[1];
                if(*l != ll.x)
                {
                        fprintf(stderr, "### ERR!! freadV lrecl confrict ###\n");
                        exit(-1);
                }
                return (*l + RDW_LENGTH + RDW_LENGTH);
        default:
                return FREAD_EOF;
        }
}

/* --------------------------------------------------------------------
 *	DESCRIPTION	:	COBOL可変長の１レコードを書き込む
 *	ARGMENT		:
        buf		i	書込みバッファ
        l		i	出力する長さ（COOBLデータ長）
        fp		i	ファイルポインタ
        vbmode	i	可変長モード
 *	RETURN		:	物理ファイルベースで出力した長さ。
 * --------------------------------------------------------------------
 */
int     fwritV(unsigned char *buf, int *l, FILE *fp, int vbmode)
{
        unsigned char rdw[RDW_LENGTH];
        union {
                unsigned char c[2];
                unsigned short x;
        } ll;


        switch( vbmode )
        {
        case VB_HOST_BIG:
                ll.x = RDW_LENGTH + *l;     /* llはデータ長＋４バイト	*/
                rdw[0] = ll.c[1];
                rdw[1] = ll.c[0];
                rdw[2] = 0x00;
                rdw[3] = 0x00;

                fwrite(rdw, RDW_LENGTH, 1, fp); /* ４バイトのRDWを書いて	*/
                fwrite(buf, *l, 1, fp);     /* データを書く				*/
                return (*l + RDW_LENGTH);
        case VB_NETC_LTL:
                ll.x = *l;                  /* llはデータ長				*/
                rdw[0] = ll.c[0];
                rdw[1] = ll.c[1];
                rdw[2] = 0x00;
                rdw[3] = 0x00;

                fwrite(rdw, RDW_LENGTH, 1, fp); /* RDW						*/
                fwrite(buf, *l, 1, fp);     /* データ					*/
                fwrite(rdw, RDW_LENGTH, 1, fp); /* RDW						*/
                return (*l + RDW_LENGTH + RDW_LENGTH);
        default:
                return FREAD_EOF;
        }
}
