#
# makefile for cygwin & linux
#
#	マクロ定義
#		$@	ターゲット（サフィックスあり）
#		$*	ターゲット（サフィックスなし）
#		$<	依存ファイル
#
# 新たに追加するサフィックス(.c .o .h .a)以外
ifeq (Windows_NT,$(filter Windows_NT, $(OS)))
  MY_OS   = Windows
  SUF_C   = .c
  SUF_OBJ = .o
  SUF_EXE = .exe
#  C_FLGS  = /Wall ; vc++
  C_FLGS = -Wall --input-charset=CP932 --exec-charset=CP932 -mno-cygwin # cygwin
  LD_FLGS = -mno-cygwin
#  C_FLGS = -Wall --input-charset=CP932 --exec-charset=CP932 # cygwin
else
  MY_OS   = linux
  SUF_C   = .c
  SUF_OBJ = .o
  SUF_EXE =
  C_FLGS  = -Wall
  LD_FLGS = 
endif

.SUFFIXES: $(SUF_OBJ) $(SUF_EXE)

#	コマンドの定義
CC		= clang
RM		= rm
ECHO	= echo

#	コンパイルオプション
LIBS	= cobfile$(SUF_OBJ)

#	デフォルト生成規則
#
$(SUF_C)$(SUF_OBJ):
	$(ECHO) ### implicit rules .c -> .o for ###
	$(CC) -c $(C_FLGS) $<

$(SUF_OBJ)$(SUF_EXE):
	$(ECHO) #### implicit rules for .o to a.out for ###
	$(CC) $(LD_FLGS) -o $@ $< $(LIBS)

$(SUF_C)$(SUF_EXE):
	$(CC) $(C_FLGS) $(LD_FLGS) -o $@ $< $(LIBS)


#	このファイルのターゲット＆ソース
ALL_EXE	=	bincmp$(SUF_EXE) binconv$(SUF_EXE) bincopy$(SUF_EXE) hexdp$(SUF_EXE)
ALL_OBJ	=	bincmp$(SUF_OBJ) binconv$(SUF_OBJ) bincopy$(SUF_OBJ) hexdp$(SUF_OBJ) cobfile$(SUF_OBJ)


dummy: 
	$(ECHO) ###########################################################
	$(ECHO) ##                                                       ##
	$(ECHO) ##     makefile for cobol binary modules $(MY_OS) version ##
	$(ECHO) ##                                                       ##
	$(ECHO) ###########################################################

all: allobj allexe 

allexe: $(ALL_EXE)

allobj: $(ALL_OBJ)

deploy:
	mv $(ALL_EXE) bin
	rm $(ALL_OBJ)

clean: 
	$(RM) $(ALL_OBJ)
	$(RM) $(ALL_EXE)


