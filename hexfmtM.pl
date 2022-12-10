#!/usr/bin/perl
# $ : scalar / @ : array / % : hash
#
# 関数名(PKG名付)			$myname	= (caller 0)[3];
# 呼び元の関数名(PKG名付)	$callername = (caller 1)[3];
use strict;
use utf8;
use File::Basename 'basename', 'dirname';
{	# COBFILE-FWの取り込み
	my $dirname = File::Basename::dirname $0;
	require "$dirname/cobfile.pl" ;
}
sub	usage {
	;
}
# -------------------------------------
package	main;
# -------------------------------------
	my	$myname	= File::Basename::basename $0;
#	my	$myname	= (caller 0)[3];
## OPTION CHECK
	my	$optck_return = &cobfile::optck("HEXFMT"); 
	if( $optck_return == $cobfile::TRUE ) 		{ ; }
	elsif( $optck_return == $cobfile::FALSE) 	{ &usage($myname); exit 0;}
	else 										{ exit 1;}
## gOpt_editは「fmtpr」で固定設定
	$cobfile::gOpt_edit = 'fmtpr';

# -------------------------------------
# FW出口部品の取り込みrequire
# -------------------------------------
{
	if($cobfile::Reqfile eq '') {
		my $dirname = File::Basename::dirname $0;
		my $req = "hexfmt_sub.pl";
		$cobfile::Reqfile	= "$dirname/$req";
	} else { ; }
	require "$cobfile::Reqfile" ;
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, "$myname,require:$cobfile::Reqfile:$!");
}

	my	($fname, $recfm, $lrecl, $decenc);
## INPUT setDCB
	my	$Infile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	&cobfile::setDCB($Infile, 			# ref to Fctrl
		$cobfile::gOpt_inf,				# fname
		$cobfile::gOpt_recfm,			# recfm
		$cobfile::gOpt_lrecl,			# lrecl
		'cp932'							# encode
	);
	($fname, $recfm, $lrecl, $decenc) = &cobfile::getDCB($Infile);
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, ($myname,
		 "DCB-FNAME:$fname",
		 "DCB-RECFM:$recfm",
		 "DCB-LRECL:$lrecl",
		 "DCB-DECENC:$decenc"
		)
	);

## OUTPUT
## if $gOpt_otf not defined
	my	$Otfile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	if(! defined($cobfile::gOpt_otf))		{	$Otfile->fname( '' ); }
	elsif( $cobfile::gOpt_otf eq 'STDOUT')	{	$Otfile->fname( '' ); } 
	else { ; }
## $gOpt_edit
	&cobfile::setDCB($Otfile, 
		$cobfile::gOpt_otf,
		'T',
		'',
		'utf8'
	);
	($fname, $recfm, $lrecl, $decenc) = &cobfile::getDCB($Otfile);
	&cobfile::dbglog($cobfile::Msglevel{'INF'}, ($myname,
		 "DCB-FNAME:$fname",
		 "DCB-RECFM:$recfm",
		 "DCB-LRECL:$lrecl",
		 "DCB-DECENC:$decenc"
		)
	);
	&cobfile::hexedit($Infile, $Otfile);

# ---------------------------------------------------
#	EXIT-Perl
# ---------------------------------------------------
1

