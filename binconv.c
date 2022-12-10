/*
 ***********************************************************************
 *	Revision 1.2  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 *
 ***********************************************************************
 *
 *	可変長ファイルの形式を変換する。
 *  <0>     <1>      <2>    <3>
 *	binconv  convtype infile outfile
 *	         host2netl  HOST(BigEndian) -> NetCOBOL(LittleEndian)
 *
 */

/* 修正履歴
    2006/03/20	とりあえず、作成
    2008/06/22	fcloseもれ追加
 */


#include    "cobfile.h"
#include    <stdio.h>
#include    <stdlib.h>
#include    <string.h>
#include    <ctype.h>

#define     MAX_BUF         32768

int     usage(void)
{
        fprintf(stderr, "binconv  : VB file convert. Host to NetCOBOL etc \n");
        fprintf(stderr, "\n");
        fprintf(stderr, "binconv  type   infile outfile\n");
        fprintf(stderr, "         host2netl   Host to NetCOBOL(LittleEndian)\n");
        return 0;
}




int main(int argc, char *argv[])
{
        unsigned char buf[MAX_BUF];
        char    *in_fname;
        char    *ot_fname;
        int in_vbmode;
        int ot_vbmode;
        int lrecl, ll;          /* lrecl:データ長、ll:fread/fwriteした長さ */
        int i,j,k,l;
        FILE    *fpin;
        FILE    *fpot;

        if(argc < 4) {
                usage();
                exit(-1);
        }

        if( strcmp(argv[1], "host2netl") == 0 )
        {
                in_vbmode   =   VB_HOST_BIG;
                ot_vbmode   =   VB_NETC_LTL;
        }
        else
        {
                fprintf(stderr, "### ERR !! conv-type error###\n");
                usage();
                exit(-1);
        }

        in_fname    =   argv[2];
        ot_fname    =   argv[3];

        if( (fpin = fopen(in_fname, "rb")) == NULL) {
                fprintf(stderr, "Cannot open file[%s]\n", in_fname);
                usage();
                exit(-1);
        }
        if( (fpot = fopen(ot_fname, "wb")) == NULL) {
                fprintf(stderr, "Cannot open file[%s]\n", ot_fname);
                usage();
                exit(-1);
        }

        while( freadV(buf, &lrecl, fpin, in_vbmode) != FREAD_EOF )
        {
                fwritV(buf, &lrecl, fpot, ot_vbmode);
        }

/* 20080622:fclose追加 */
        fclose(fpin);
        fclose(fpot);

        return 0;
}
