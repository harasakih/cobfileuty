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
BINEDIT=$(BINBASE).edit
BINLST1=$(BINBASE).1.lst
BINLST2=$(BINBASE).2.lst
BINBIN=$(BINBASE).bin

HEXBASE=hexstr
INFHEX=$(HEXBASE).txt		# INPUT
HEXBIN=$(HEXBASE).bin
HEXLST=$(HEXBASE).lst

SJISBASE=sjis
INFSJIS=$(SJISBASE).txt		# INPUT
SJISEDIT=$(SJISBASE).edit
SJISBIN=$(SJISBASE).bin
SJISLST=$(SJISBASE).lst


CLEAN=$(BINEDIT) $(BINLST1) $(BINLST2) $(BINBIN) \
  $(HEXBIN) $(HEXLST) \
  $(SJISEDIT) $(SJISBIN) $(SJISLST)

dummy: 
	$(ECHO) ###########################################################
	$(ECHO) ## confile test-script
	$(ECHO) ###########################################################

all: edit dpput
edit: sjisedit hexedit_edit hexedit_iferr hexfmt_iferr
dpput: hexdp hexdpput hexput

hexdp:
	@echo "### hexdp $(INFSJIS) ###"
	-@rm $(SJISLST)
	./hexdpM.pl  --recfm=F --lrecl=6 --inf=$(INFSJIS) --dmp=hexstr
	./hexdpM.pl  --recfm=F --lrecl=6 --inf=$(INFSJIS) --dmp=lst

hexdpput:
	@echo "### hexdpput $(INFBIN) ###"
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=V --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=V --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### bincmp(no-diff) ###"
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=F --lrecl=8 --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=F --lrecl=8 --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### bincmp(no-diff) ###"
	-@rm $(BINLST1)
	-@rm $(BINBIN)
	./hexdpM.pl  --recfm=F --lrecl=9 --inf=$(INFBIN) --otf=$(BINLST1) --dmp=hexstr
	./hexputM.pl --recfm=F --lrecl=9 --inf=$(BINLST1) --otf=$(BINBIN)
	bin/bincmp vn $(INFBIN) $(BINBIN)
	@echo "### bincmp(no-diff) ###"

hexput:
	@echo "### hexput $(INFHEX) ###"
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=V --inf=$(INFHEX) --otf=$(HEXBIN)
	./hexdpM.pl  --recfm=V --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	diff $(INFHEX) $(HEXLST)
	@echo "### diff(no-diff) 1 ###"
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=F --lrecl=10 --inf=$(INFHEX) --otf=$(HEXBIN)
	./hexdpM.pl  --recfm=F --lrecl=10 --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	-diff $(INFHEX) $(HEXLST)
	@echo "### diff(diff) 2 ###"
	./inqYN.sh
	-@rm $(HEXBIN)
	-@rm $(HEXLST)
	./hexputM.pl --recfm=F --lrecl=04 --inf=$(INFHEX) --otf=$(HEXBIN) --pad=ff --logl=INF
	./hexdpM.pl  --recfm=F --lrecl=04 --inf=$(HEXBIN) --otf=$(HEXLST) --dmp=hexstr
	-diff $(INFHEX) $(HEXLST)
	@echo "### diff(diff) 3 ###"
	./inqYN.sh

sjisedit:
	@echo "### hexedit $(INFSJIS) ###"
	-@rm $(SJISEDIT)
	./hexeditM.pl --recfm=F --lrecl=6 --inf=$(INFSJIS) --otf=$(SJISEDIT) --req=./hexedit_sjis.pl --edit=edit --logl=$(LOGL)
	-bin/bincmp f6 $(INFSJIS) $(SJISEDIT)
	@echo "### bincmp(diff) ###"
	./inqYN.sh

hexedit_edit:
	@echo "### hexeditM(edit) $(INFBIN) ###"
	-@rm $(BINEDIT)
	./hexeditM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINEDIT) --edit=edit --logl=$(LOGL)
	./hexdpM.pl --recfm=V --inf=$(INFBIN)
	./hexdpM.pl --recfm=V --inf=$(BINEDIT)
	-bin/bincmp vn $(INFBIN) $(BINEDIT)
	@echo "### bincmp(diff) ###"
	./inqYN.sh

hexedit_iferr:
	@echo "### hexeditM(fmtpr) $(INFBIN) ###"
	-@rm $(BINLST1)
	-@rm $(BINLST2)
	./hexeditM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST1) --edit=fmtpr --logl=$(LOGL)
	./hexeditM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST2) --edit=fmtpr --logl=$(LOGL) --iferr=hex
	-diff $(BINLST1) $(BINLST2)
	@echo "### diff(diff) ###"
	./inqYN.sh

hexfmt_iferr:
	@echo "### hexfmtM $(INFBIN) ###"
	-@rm $(BINLST1)
	-@rm $(BINLST2)
	./hexfmtM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST1) --logl=$(LOGL)
	./hexfmtM.pl --recfm=V --inf=$(INFBIN) --otf=$(BINLST2) --logl=$(LOGL) --iferr=hex
	-diff $(BINLST1) $(BINLST2)
	@echo "### diff(diff) ###"
	./inqYN.sh

clean:
	-rm $(CLEAN)