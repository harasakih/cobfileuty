#	マクロ定義
#		$@	ターゲット（サフィックスあり）
#		$*	ターゲット（サフィックスなし）
#		$<	依存ファイル
#
#	@ : no-ECHO
#	- : ignore ERROR
# 新たに追加するサフィックス(.c .o .h .a)以外
MY_OS   = linux
.SUFFIXES: $(SUF_OBJ) $(SUF_EXE)
#	コマンドの定義
RM		= rm
ECHO	= echo
#	デフォルト生成規則
#
LOGL=ERR

## base
BINBASE=vbconv
INFBIN=$(BINBASE).netl		# INPUPT
BINLST1=$(BINBASE).1.lst
BINLST2=$(BINBASE).2.lst
BINBIN=$(BINBASE).bin

HEXBASE=hexstr
INFHEX=$(HEXBASE).txt		# INPUT
HEXBIN=$(HEXBASE).bin
HEXLST=$(HEXBASE).lst

HEXBASE2=hexstr2
INFHEX2=$(HEXBASE2).txt		# INPUT
HEXBIN2=$(HEXBASE2).bin
HEXEDT2=$(HEXBASE2).edit
HEXLST2B=$(HEXBASE2).B.lst
HEXLST2A=$(HEXBASE2).A.lst

SJISBASE=sjis
INFSJIS=$(SJISBASE).txt		# INPUT
SJISLST=$(SJISBASE).lst

MAPLST=COPY01.copy.lst


CLEAN=$(BINLST1) $(BINLST2) $(BINBIN) \
  $(HEXBIN) $(HEXLST) \
  $(HEXBIN2) $(HEXEDT2) $(HEXLST2B) $(HEXLST2A)

dummy: 
	$(ECHO) ###########################################################
	$(ECHO) ## confile test-script
	$(ECHO) ###########################################################

all: dpput edit 
edit: hexedit_edit hexedit_iferr
dpput: hexdp hexdpput hexput

hexdp:
	@echo "### hexdp $(INFSJIS) ###"
	-@rm $(SJISLST)
	./hexdpM.pl  --recfm=F --lrecl=6 --inf=$(INFSJIS) --dmp=hexstr
	./hexdpM.pl  --recfm=F --lrecl=6 --inf=$(INFSJIS) --dmp=lst
	@echo "### hexdp[hexstr vs lst] $(INFSJIS) SUCCESS ###"
	./inqYN.sh

hexdpput:
	@echo "### hexdpput $(INFBIN) ###"
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=V --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=V --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### hexdpM to hexputM,recfm=V : bincmp(no-diff) ###"
	./inqYN.sh
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=F --lrecl=8 --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=F --lrecl=8 --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### hexdpM to hexputM,recfm=F : bincmp(no-diff) ###"
	./inqYN.sh
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=F --lrecl=9 --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=F --lrecl=9 --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### hexdpM to hexputM,recfm=F : bincmp(no-diff) ###"
	@echo "### hexdpput $(INFBIN) SUCCESS ###"
	./inqYN.sh

hexput:
	@echo "### hexput $(INFHEX) ###"
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=V --inf=$(INFHEX) --otf=$(HEXBIN)
	./hexdpM.pl  --recfm=V --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	diff $(INFHEX) $(HEXLST)
	@echo "### hexputM to hexdpM,recfm=V : diff(no-diff) 1 ###"
	./inqYN.sh
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=F --lrecl=10 --inf=$(INFHEX) --otf=$(HEXBIN)
	./hexdpM.pl  --recfm=F --lrecl=10 --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	-diff $(INFHEX) $(HEXLST)
	@echo "### hexputM to hexdpM,recfm=F,no-paddng : diff(diff) 2 ###"
	./inqYN.sh
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=F --lrecl=04 --inf=$(INFHEX) --otf=$(HEXBIN) --pad=ff --logl=INF
	./hexdpM.pl  --recfm=F --lrecl=04 --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	-diff $(INFHEX) $(HEXLST)
	@echo "### hexputM to hexdpM,recfm=F,padding : diff(diff) 3 ###"
	./inqYN.sh
	@echo "### hexput $(INFHEX) SUCCESS ###"

hexedit_edit:
	@echo "### hexeditM $(INFHEX2) ###"
	-@rm $(HEXBIN2) $(HEXEDT2) $(HEXLST2B) $(HEXLST2A)
	./hexputM.pl --inf=$(INFHEX2) --recfm=V --otf=$(HEXBIN2)
	./hexeditM.pl --inf=$(HEXBIN2) --recfm=V  --edit=edit --otf=$(HEXEDT2) --logl=WRN
	./hexeditM.pl --inf=$(HEXBIN2) --recfm=V  --req=./hexedit_sub.pl --edit=fmtpr --otf=$(HEXLST2B) --iferr=hex
	./hexeditM.pl --inf=$(HEXEDT2) --recfm=V  --req=./hexedit_sub.pl --edit=fmtpr --otf=$(HEXLST2A) --iferr=hex
	-diff $(HEXLST2B) $(HEXLST2A)
	@echo "### hexeditM(edit) PD,CH,BB,BL : diff(diff) ###"
	./inqYN.sh
	@echo "### hexeditM $(INFHEX2) SUCCESS ###"

hexedit_iferr:
	@echo "### hexeditM(fmtpr) $(INFBIN) ###"
	-@rm $(BINLST1)
	-@rm $(BINLST2)
	./hexeditM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST1) --req=./hexedit_sub2.pl --edit=fmtpr --logl=$(LOGL)
	./hexeditM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST2) --req=./hexedit_sub2.pl --edit=fmtpr --logl=$(LOGL) --iferr=hex
	-diff $(BINLST1) $(BINLST2)
	@echo "### hexeditM(fmtpr),iferr : diff(diff) ###"
	./inqYN.sh
	@echo "### hexeditM(fmtpr) $(INFBIN) SUCCESS ###"

copymap:
	@echo "### copymap ###"
	./copymap.pl --inf=$(MAPLST)

clean:
	-rm $(CLEAN)
