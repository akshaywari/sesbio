#!/usr/bin/env perl

=head1 NAME 
                                                                       
 hmm2go.pl - Map PFAM IDs from HMMscan search to GO terms 

=head1 SYNOPSIS    

 hmm2go.pl -i seqs_hmmscan.tblout -p pfam2go -o seqs_hmmscan_goterms.tsv --map 

=head1 DESCRIPTION
                                                                   
 This script takes the table output of HMMscan and maps go terms to your
 significant hits using the GO->PFAM mappings provided by the Gene Ontology
 (geneontology.org).

=head1 LICENSE
 
   The MIT License

   Copyright (c) 2013, S. Evan Staton.

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
 
=head1 TESTED WITH:

=over

=item *
Perl 5.14.1 (Red Hat Enterprise Linux Server release 5.7 (Tikanga))

=head1 AUTHOR
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The HMMscan output in table format (generated with "--tblout" option from HMMscan).

=item -p, --pfam2go

The PFAMID->GO mapping file provided by the Gene Ontology. 
Direct link: http://www.geneontology.org/external2go/pfam2go

=item -o, --outfile

The file to hold the GO term/description mapping results. The format is tab-delimited
and contains: QueryID, PFAM_ID, PFAM_Name, PFAM_Description, GO_Term, GO_Description. An example
from grape is below: 

GSVIVT01018890001	PF00004	AAA	GO:ATP binding	GO:0005524	ATPase
GSVIVT01000580001	PF00005	ABC_tran	GO:ATP binding	GO:0005524	ABC
GSVIVT01000580001	PF00005	ABC_tran	GO:ATPase activity	GO:0016887	ABC

=back

=head1 OPTIONS

=over 2

=item --map

Produce of tab-delimted file of query sequence IDs and GO terms. An example is below:

sunf|NODE_1172150_length_184_cov_4_472826_5	GO:0004553,GO:0005975
GSVIVT01027800001	GO:0016787
sunf|NODE_1444993_length_180_cov_3_405555_4	GO:0004672,GO:0005524,GO:0006468
saff|NODE_490685_length_227_cov_36_000000_9	GO:0005525,GO:0005634,GO:0005737

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=cut 

## Includes
use 5.010;
use strict; 
use warnings;
use warnings FATAL => "utf8";
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use utf8;
use charnames qw(:full :short);

## Vars
my $infile;
my $pfam2go; 
my $outfile;
my $mapping;
my $mapfile;
my $map_fh;
my $help;
my $man;

GetOptions(
	   'i|infile=s'  => \$infile,
	   'p|pfam2go=s' => \$pfam2go,
	   'o|outfile=s' => \$outfile,
	   'map'         => \$mapping,
           'h|help'      => \$help,
           'm|man'       => \$man,
	   );

## Check input
pod2usage( -verbose => 2) if $man;
usage() and exit(0) if $help;

if (!$infile || !$pfam2go || !$outfile) {
    say "\nERROR: Input not parsed correctly.\n";
    usage() and exit(1);
}

## create filehandles, if possible
open my $in, '<', $infile or die "\nERROR: Could not open file: $infile\n";
open my $pfams, '<', $pfam2go or die "\nERROR: Could not open file: $pfam2go\n";
open my $out, '>', $outfile or die "\nERROR: Could not open file: $outfile\n";

if ($mapping) {
    $mapfile = $outfile;
    $mapfile =~ s/\..*//g;
    $mapfile .= "_GOterm_mapping.tsv";
    open $map_fh, '>', $mapfile or die "\nERROR: Could not open file: $mapfile\n";
}

my %pfamids;
while(<$in>) {
    chomp;
    next if /^\#/;
    my ($target_name, $accession, $query_name, $accession_q, $E_value_full, 
	$score_full, $bias_full, $E_value_best, $score_best, $bias_best, 
	$exp, $reg, $clu, $ov, $env, $dom, $rev, $inc, $description_of_target) = split;
    my $query_eval = mk_key($query_name, $E_value_full, $description_of_target);
    $accession =~ s/\..*//;
    $pfamids{$query_eval} = $accession;
}
close $in;

my %goterms;
my $go_ct = 0;
my $map_ct = 0;

while(my $mapping = <$pfams>) {
    chomp $mapping;
    next if $mapping =~ /^!/;
    if ($mapping =~ /Pfam:(\S+) (\S+ \> )(GO\:\S+.*\;) (GO\:\d+)/) {
	my $pf = $1;
	my $pf_name = $2;
	my $pf_desc = $3;
	my $go_term = $4;
	$pf_name =~ s/\s.*//;
	$pf_desc =~ s/\s\;//;
	for my $key (keys %pfamids) { 
	    my ($query, $e_val, $desc) = mk_vec($key);
	    if ($pfamids{$key} eq $pf) {
		say $out join "\t", $query, $pf, $pf_name, $pf_desc, $go_term, $desc;
		if ($mapping) {
		    if (exists $goterms{$query}) {
			$go_ct++ if defined($go_term);
			$goterms{$query} .= ",".$go_term;
		    } else {
			$goterms{$query} = $go_term;
		    }
		}
		last;
	    }
	}
    }
}
close $pfams;
close $out;

if ($mapping) {
    while (my ($key, $value) = each %goterms) {
	$map_ct++;
	say $map_fh join "\t", $key, $value;
    }
    say "\n$map_ct query sequences with $go_ct GO terms mapped in file $mapfile.\n";
}

## Subs
sub mk_key { join "\N{INVISIBLE SEPARATOR}", @_ }

sub mk_vec { split "\N{INVISIBLE SEPARATOR}", shift }

sub usage {
  my $script = basename($0);
  print STDERR <<END
USAGE: $script -i hmmscan.tblout -p pfam2go -o hmmscan_goterms.tsv [--map] 

Required:
    -i|infile    :    The output of HMMscan (specifically, the --tblout option).
    -p|pfam2go   :    PFAM ID to GO term mapping file.
    -o|outfile   :    File to place the mapped GO terms.
    
Options:
    --map        :    Produce a simple, 2-column file of only the query IDs and mapped GO terms.
    -h|help      :    Print usage statement.
    -m|man       :    Print full documentation.

END
}
