#!/usr/bin/perl
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Convert Cygwin pathames to plain Windows pathnames.
#               Defined as a filter to use on make's result.
#		Meant to be use by Vim.
# Created:	05/29/04 01:12:19
# Last Update:	16th Jun 2004
# ======================================================================

# cygroot
my $cygroot = `cygpath -m /`;
chomp($cygroot);

# Hash table for the paths already translated with ``realname''
my %paths = () ;

# Proxy function: returns the realname of the path
# This function looks for converted paths into the hastable, if nothing is
# found in the table, the result is built and add into the table
sub WindowsPath 
{
    my ($path) = @_ ;
    if ( exists( $h{$path} ) ) {
	return $h{$path} ;
    } else {
	$wpath = `realpath "$path"`;
	chomp ($wpath);
	$wpath =~ s#/cygdrive/(.)#\u\1:#  ;
	$wpath =~ s#^/#$cygroot/#  ;
	$h{$path} = $wpath ;
	return $wpath ;
    }
}

# Main loop: convert Cygwin paths into MsWindows paths
while (<>) 
{
    chop;
    if ( m#^( */.*?)(\:\d*\:?.*$)# ) {
	printf WindowsPath($1)."$2\n";
    } else {
	print "$_\n";
    }
}
