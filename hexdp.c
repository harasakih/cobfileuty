/*
 ***********************************************************************
 *	Revision 1.2  2006/06/25 16:04:39  hiroshi
 *	ダンプは英大文字で
 *
 ***********************************************************************
 *
 */

#include    <stdio.h>
#include    <string.h>
#include    <stdlib.h>

#define     MAX_FNAME   128
#define     FOPN_ERROR  NULL




int main(int argc, char *argv[])
{
        FILE    *infp;
        long skip, count;
        char in_fname[MAX_FNAME];
        unsigned char data;
        unsigned char hex[2];
        long add;

        if(argc == 1) {
                fprintf(stderr, "hexdp : infile skip count\n");
                fprintf(stderr, "  output is stdout\n");
                return 0;
        }

        skip    =   count   =   0;
        if(argc >= 2 ) { strcpy(in_fname, argv[1]); }
        if(argc >= 3 ) { skip   =   atoi( argv[2] ); }
        if(argc >= 4 ) { count  =   atoi( argv[3] ); }

        if( (infp = fopen(in_fname, "rb")) == FOPN_ERROR ) {
                fprintf(stderr, "infile open error\n");
                return -1;
        }

        if( count == 0 ) {
                fseek(infp,0,SEEK_END);
                count   =   ftell(infp);
                count   -=  skip;
                fseek(infp, 0L, SEEK_SET);
        }

        fprintf(stderr, "infile : %s\n", in_fname);
        fprintf(stderr, "skip   : %08lX(%ld)\n", skip, skip);
        fprintf(stderr, "count  : %08lX(%ld)\n", count, count);

        fseek(infp, skip, SEEK_SET);

        add     =   0;
        fread(&data, 1, 1, infp);

        while( add < count) {

                /* ３２バイト区切り */
                if((add % 32) == 0)                                         { printf("\n%06lX: ", add); }
                /* １６バイト区切り */
                if((add % 32) != 0 && (add % 16) == 0)                      { putchar('-'); }
                /* ４バイト区切り */
                if((add % 32) != 0 && (add % 16) != 0 && (add %  4) == 0)   { putchar(' '); }

                printf("%02X", data);
                add++;

                fread(&data, 1, 1, infp);
        }

        printf("\n");
        fclose(infp);

        return 0;
}
