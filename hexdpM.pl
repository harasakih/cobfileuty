#!/usr/bin/perl
# $ : scalar / @ : array / % : hash
#
use strict;
use utf8;
use File::Basename 'basename', 'dirname';
{
	my $dirname = File::Basename::dirname $0;
	require "$dirname/cobfile.pl" ;
}

sub	usage	{
	;
}
# -------------------------------------
package	main;
# -------------------------------------
	my	$myname	= File::Basename::basename $0;
# OPTION CHECK
	my	$optck_return = &cobfile::optck("HEXDUMP");
	if( $optck_return == $cobfile::TRUE ) 		{ ; }
	elsif( $optck_return == $cobfile::FALSE)	{ usage($myname); exit 0;}
	else 										{ exit 1;}
## INPUT
	my	$Infile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	&cobfile::setDCB($Infile, 			# ref to Fctrl
		$cobfile::gOpt_inf,				# fname
		$cobfile::gOpt_recfm,			# recfm
		$cobfile::gOpt_lrecl,			# lrecl
		''								# encode
	);

## OUTPUT
	my	$Otfile = Fctrl->new();			# $Otfileはリファレンス型として定義されている
	&cobfile::setDCB($Otfile, 			# ref to Fctrl
		$cobfile::gOpt_otf,				# fname
		'T',							# recfm
		'',								# lrecl
		'utf8'							# encode
	);
## --otf省略、STDOUTは、fnameに空白を設定
	if(! defined($cobfile::gOpt_otf))		{	$Otfile->fname( '' ); }
	elsif( $cobfile::gOpt_otf eq 'STDOUT')	{	$Otfile->fname( '' ); } 
	else { ; }

# ---------------------------------------------------
	&cobfile::hexdp($Infile, $Otfile, $cobfile::gOpt_dmp);
# ---------------------------------------------------

# ---------------------------------------------------
#	EXIT-Perl
# ---------------------------------------------------
1

