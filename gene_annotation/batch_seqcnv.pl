#!/usr/bin/env perl

##NB: This was written to work with the PAGIT pipeline, which involves
##    going between formats to transfer annotations.

use 5.010;
use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

my $usage = "perl $0 -i dir -o out\n";
my $indir;
my $outfile;

GetOptions(
           'i|indir=s'   => \$indir,
           'o|outfile=s' => \$outfile,
          );

die $usage if !$indir;

$indir =~ s/\/$// if $indir =~ /\/$/;
my @embl_files = glob("$indir/*.embl");
if (scalar @embl_files < 1) {
    say "\nERROR: Could not find any embl files in $indir. Must end with \".embl\". Exiting.";
    exit(1);
}

for my $file (@embl_files) {
    my $out = $file;
    $out =~ s/\.embl$//;
    $out .= ".gb";
    my $seqio  = Bio::SeqIO->new(-file => $file,   -format => 'EMBL');
    my $seqout = Bio::SeqIO->new(-file => ">$out", -format => 'genbank');
    while (my $seq = $seqio->next_seq) {
	$seqout->write_seq($seq);
    }
}
