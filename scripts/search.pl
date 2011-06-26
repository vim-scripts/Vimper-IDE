#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  search.pl
#
#        USAGE:  ./search.pl  --dir <root> --type <project_type> --pattern <regex> --output <outputfile>
#
#  DESCRIPTION:  Search the directory for the sepcified regex
#
#      OPTIONS:   --dir     : directory to search under
#                 --filerex : regex pattern to match the filenames with
#                 --pattern : pattern to search for in the selected files
#                 --output  : output file to dump the matches to
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  ghoshs
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  8/31/2009 1:53:06 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use English;
use Getopt::Long;
use File::Basename;

my $dir_vimper_scripts = $ENV{'VIMPER_HOME'} . "/scripts";

my $s_dir_project_root = "";
my $s_project_type = "";
my $s_regex_search = "";
my $s_output_filename = "";
my $cygroot = `cygpath -m /`;

my %_FINDREX = ( 
	"cpp" => "(^\\.c.*|^\\.h)", 
	"java" => "^\\.java", 
	"vim" => "^\\.vim" 
);

# Get the command line options
GetOptions( 'dir=s' => \$s_dir_project_root,
'type=s' => \$s_project_type,
	    'pattern=s' => \$s_regex_search,
    'output=s' => \$s_output_filename 
	  );

	  if (!$s_dir_project_root) {
		  print_usage("--dir");
	  }
	  if (!$s_project_type) {
		  print_usage("--type");
	  }
	  if (!$s_regex_search) {
		  print_usage("--pattern");
	  }
	  if (!$s_output_filename) {
		  print_usage("--output");
	  }

	  my $filext = "";

	  $filext = $_FINDREX{$s_project_type};
	  if (!$filext){
		  print "Cannot find search extensions for project type [". $s_project_type . "].\n";
		  print %_FINDREX;
		  exit 3;
	  }
	  print "Searching in files " . $filext . "...\n";

	  open my $OUTPUT, '>' . $s_output_filename or die qq{Cannot create output file $s_output_filename. $!};

	  search_dir($s_dir_project_root);

	  close $OUTPUT;

	  sub search_dir {
		  my $dirname = $_[0];
		  if (!$dirname) {
			  return;
		  }
		  if ( -d $dirname ) {
			  my @dirs = `ls $dirname`;
			  foreach my $dirs(@dirs){
				  my $tdir = $dirname . '/' . $dirs;
				  chomp($tdir);
				  if ( -f $tdir ) {
					  my(undef, undef, $ftype) = fileparse($tdir, qr{\..*});
					  if ($ftype =~ m/$filext/) {
						  search_file($tdir);
					  }
				  }
				  elsif ( -d $tdir ){
					  search_dir($tdir);
				  }
			  }
		  }
	  }
	  sub search_file {
		  my $filename = $_[0];
		  if (!$filename) {
			  return;
		  }
		  if ( -f $filename ){
			  print "Searching file " . $filename . "\n";
			  open my $INPUT, '<' . $filename or return;

			  my $lineno = 1;
			  while( <$INPUT> ){
				  if ($_ =~ m/$s_regex_search/){
					  my $wfile = $filename;
					  $wfile =~ s#/cygdrive/(.)#\u\1:#  ;
					  my $wtext = $_;
					  $wtext =~ s/\n//g;
					  print $OUTPUT sprintf("%s:%d:%s\n", $wfile, $lineno, $wtext)
				  }
				  $lineno++;
			  }
			  close $INPUT;
		  }
	  }
	  sub print_usage {
		  print "search.pl  --dir <root> --type <project_type> --pattern <regex> --output <outputfile>";
		  print "Missing option : ".$_[0]."\n";
		  exit 2;
	  }
