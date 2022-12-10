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

sub	usage {
	my	($msg)	=	@_;

	my $basename	= File::Basename::basename $0;
	print STDOUT "\n";
	if(defined($msg)) { print STDOUT "$msg\n"; }
	print STDOUT "Additional HELPS\n" ;
	print STDOUT "when --recfm=V, write LL + DATA-REC + LL.\n" ;
	print STDOUT "when --recfm=F, write DATA only.\n";
	print STDOUT "     if length(DATA) shorter than lrecl, not padding but read Next RECORD. \n"
}

# -------------------------------------
package	main;
# -------------------------------------
	my	$myname	= File::Basename::basename $0;
## OPTION CHECK
	my	$optck_return = &cobfile::optck("HEXSTR to BinaryFile"); 
	if( $optck_return == $cobfile::TRUE ) 		{ ; }
	elsif( $optck_return == $cobfile::FALSE)	{ usage($myname); exit 0;}
	else 										{ exit 1;}

## INPUT
	my	$Infile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	&cobfile::setDCB($Infile, 			# ref to Fctrl
		$cobfile::gOpt_inf,				# fname
		'T',							# recfm
		'',								# lrecl
		'utf8'							# encode
	);

## OUTPUT
	my	$Otfile = Fctrl->new();			# $Infileはリファレンス型として定義されている
	if(! defined($cobfile::gOpt_otf))		{	$Otfile->fname( '' ); }
	elsif( $cobfile::gOpt_otf eq 'STDOUT')	{	$Otfile->fname( '' ); } 
	else { ; }

	&cobfile::setDCB($Otfile, 
		$cobfile::gOpt_otf,				# fname
		$cobfile::gOpt_recfm,			# recfm
		$cobfile::gOpt_lrecl,			# lrecl
		''								# encode
	);

	&cobfile::hexputFile( $Infile, $Otfile ); 
## hexputFile内で、次の関数を呼び出す
##	readBread, 
##	writeBrec
# ---------------------------------------------------
#	EXIT-Perl
# ---------------------------------------------------
1

