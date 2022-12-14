/*
 ***********************************************************************
 *	Revision 1.2  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 *	
 ***********************************************************************
 *
 *	NAME		:	cobfile.h
 *	SYNTAX		:	COBOLファイルを扱うための、ヘッダファイル
 *	DESCRIPTION	:	
 *	BUGS		:
 *	HISTORY		:	
 *		2006/04/01	Ver.0.0-00	bincopy,vbconvなど今までのファイルをまとめた
 *
 */
 

/* ----------------------------------------------------------------------------
	ＩＮＣＬＵＤＥファイル
---------------------------------------------------------------------------- */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>

/* ----------------------------------------------------------------------------
	ＤＥＦＩＮＥ＆ＭＡＣＲＯ
---------------------------------------------------------------------------- */
#ifndef		_INC_COBFILE
#define		_INC_COBFILE

#define		FREAD_EOF		(-1)	/* fread()でのEOFはfeof()で判定する		*/
									/* EOFの時はゼロ以外，notEOFは０		*/

#define		RDW_LENGTH		4		/* 可変長形式のレコード長部の長さ		*/

#define		VB_HOST_BIG		1		/* BigEndian LLはデータ＋ＲＤＷ			*/
#define		VB_NETC_LTL		2		/* NetCOBOLのLittleEndian LLはデータ長、LL+データ+LL	*/


/* ----------------------------------------------------------------------------
	構造体の定義
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
	関数プロトタイプ宣言
---------------------------------------------------------------------------- */
long	fileSize(char *fname);
int		freadV(unsigned char *buf, int *l, FILE *fp, int vbmode);
int		fwritV(unsigned char *buf, int *l, FILE *fp, int vbmode);
int		freadF(unsigned char *buf, int *l, FILE *fp);
int		fwritF(unsigned char *buf, int *l, FILE *fp);


#ifdef  MAIN
/* ----------------------------------------------------------------------------
	外部変数の定義
---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
	関数定義実態
---------------------------------------------------------------------------- */

#else
/* ----------------------------------------------------------------------------
	外部変数(static)の宣言
---------------------------------------------------------------------------- */



#endif		/* ifdef	MAIN */

#endif		/* ifndef	_INC_COBFILE */

