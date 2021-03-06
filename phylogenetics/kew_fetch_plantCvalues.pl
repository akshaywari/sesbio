#!/usr/bin/env perl

=head1 NAME 
                                                                       
kew_fetch_plantCvalues.pl - Fetch C-values for a plant family  

=head1 SYNOPSIS    
 
kew_fetch_plantCvalues.pl -f familyname -e email -o resultsfile

=head1 DESCRIPTION
                                                                   
This is a  web client to fetch C-values for a plant family from the Kew Royal Botanic 
Gardens database (http://data.kew.org/cvalues/) that returns a file sorted by ascending 
genome size for each species in the database as in the example shown below. The data in 
each column are family, subfamily, tribe, genus, species, chromosome number, ploidy level, 
and genome size (listed as 1C (Mbp) estimates). 

Note that some species have no ploidy level or chromosome number estimate as in the first 
two species in the example below. This is because these values are not listed in the Kew database. 
Also note that the subfamily and tribe for some species is not listed, as with the third and fourth 
species below, because these species are not in the NCBI Entrez Taxonomy database. Please note that 
neither of these features are because of an error with this script, but rather a reflection of what 
information is present in each database. In addition,the subfamily and tribe may actually be incorrect 
because these values are missing from NCBI so the taxonomic rank that is expected to be subfamily and 
tribe is printed.

ASTERACEAE      Cichorioideae   Hypochaeridinae Leontodon       longirostris                    391
ASTERACEAE      Asteroideae     Senecioninae    Pericallis      appendiculata   60      6       533
ASTERACEAE                                      Taraxacum       linearisquameum 16      2       866
ASTERACEAE                                      Centaurea       cuneifolia      18      2       870


(...)

=head1 DEPENDENCIES

This client uses URI to format data for a request, and HTTP::Tiny
to perform a request. libxml2-devel is required (used by XML::LibXML)
for parsing XML.

=head1 LICENSE

MIT License. See project website for details: https://github.com/sestaton/sesbio

=head1 AUTHOR 

S. Evan Staton                                                

=head1 CONTACT
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -d, --db

The database to search. Can be one of Angiosperm, Gymnosperm,
Pteridophyte, Bryophyte, Algae. Case is not important but the 
database MUST be spelled correctly.

=item -f, --family

The name of the plant family to search for.

=item -e, --email

An email must be used to fill out the query form online.

=back

=head1 OPTIONS

=over 2

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=cut      

##TODO: get return type (2C Mbp, 1C Mbp, etc...) Currently, 1C Mbp is returned 
##      add method for donating or supporting Kew gardens, at least in the documentation
##
##      make returning full lineage an option rather than default

use 5.010;
use strict;
use warnings;
use File::Basename;
use HTTP::Tiny;
use XML::LibXML;
use URI;
use Pod::Usage;
use Time::HiRes qw(gettimeofday);
use Getopt::Long;

my $family;
my $email;
my $outfile;
my $help;
my $man;
my $db;
my $kew_response = "Kew_Royal_Botanic_Gardens_Plant-Cvalues_Database.html"; # XHTML

#
# Set Opts
#
GetOptions(
	   'f|family=s'     => \$family,
	   'e|email=s'      => \$email,
	   'o|outfile=s'    => \$outfile,
	   'd|db:s'         => \$db,
	   'h|help'         => \$help,
	   'm|man'          => \$man,
	  );

pod2usage( -verbose => 1 ) if $help;
pod2usage( -verbose => 2 ) if $man;

#
# Check @ARGV
#
if (!$family || !$email || !$outfile) {
   say "\nERROR: Command line not parsed correctly. Exiting.";
   usage();
   exit(0);
}

#
# Set the Kew database to search
#
if ($db) {
    if ($db =~ /angiosperm/i) {      $db = "Angiosperm"; }
    elsif ($db =~ /gymnosperm/i) {   $db = "gymnosperm"; }
    elsif ($db =~ /pteridophyte/i) { $db = "pteridophyte"; }
    elsif ($db =~ /bryophyte/i) {    $db = "bryophyte"; }
    elsif ($db =~ /algae/i) {        $db = "algae"; }
    else { die "Invalid name for option db."; }
}

# Counters
my $t0 = gettimeofday();
my $records = 0;

# Make the request
my $url = geturlfordb($db,$email,$family);
my $response = fetch_file($url, $kew_response);

# Open and parse the results
open my $xhtml, '<', $kew_response or die "\nERROR: Could not open file: $kew_response";
open my $kew_results, '>', $outfile or die "\nERROR: Could not open file: $outfile";

while (my $cvalues = <$xhtml>) {
    chomp $cvalues;
    my $FAM = uc($family);
    while ($cvalues =~ m/($FAM)<.*?><.*?>(\w+)<.*?><.*?>(\w+.*?)<.*?><.*?>(\d+|)<.*?><.*?>(\d+|)<.*?><.*?>(\d+)/g) {
	$records++;
	my ($kewfam, $genus, $species, $chrnum, $ploidy, $cval) = ($1, $2, $3, $4, $5, $6);
	$species =~ s/\(.*//;
	my $entrezid = search_by_name($genus, $species);
	my $lineage = get_lineage_for_id($entrezid);
	$lineage = $kewfam unless $lineage;
	say $kew_results join "\t", $lineage, $genus, $species, $chrnum, $ploidy, $cval;
    }
}

close $xhtml;
close $kew_results;
unlink $kew_response;

my $t1 = gettimeofday();
my $elapsed = $t1 - $t0;
my $time = sprintf("%.2f",$elapsed/60);

say "Fetched $records records in $time m:s.";

exit;
#
# Methods
#
sub usage {
    my $script = basename( $0, () );
    print STDERR <<END

$script --db Angiosperm --family Asteraceae --email name\@domain.com -o myresults.txt

Required Arguments:
  -d|db            :       The database to query. Type $script --man for more details.
  -f|family        :       Name of the plant family to search.
  -e|email         :       Valid email to attach to the request.
  -o|outfile       :       File to place the results.

Options:
  -h|help          :       Print a help statement.
  -m|man           :       Print the full manual. 

END

}

sub search_by_name {
    my ($genus, $species) = @_;

    $genus   = lcfirst($genus);
    $species = lc($species);
    my $id   = fetch_id_for_name($genus, $species);

    return $id;
}

sub get_lineage_for_id {
    my ($id) = @_;
    my $esumm = "esumm_$id.xml"; 
 
    my $urlbase  = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=taxonomy&id=$id";
    my $response = fetch_file($urlbase, $esumm);

    my $parser = XML::LibXML->new;
    my $doc    = $parser->parse_file($esumm);

    my ($lineage, $family);
    for my $node ( $doc->findnodes('//TaxaSet/Taxon') ) {
	($lineage) = $node->findvalue('Lineage/text()');
	($family)  = map  { s/\;$//; $_; }
	             grep { /(\w+aceae)/ } 
                     map  { split /\s+/  } $lineage;
	#say "Family: $family";
	#say "Full taxonomic lineage: $lineage";
    }
    unlink $esumm;
    if ($lineage) {
	$lineage =~ s/;/\t/g;
	return $lineage;
    }
    else {
	return undef;
    }
}

sub fetch_id_for_name {
    my ($genus, $species) = @_;

    my $esearch = "esearch_$genus"."_"."$species.xml";
    my $urlbase = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?";
    $urlbase    .= "db=taxonomy&term=$genus%20$species";
    my $reponse = fetch_file($urlbase, $esearch);

    my $id;
    my $parser = XML::LibXML->new;
    my $doc    = $parser->parse_file($esearch);
    
    for my $node ( $doc->findnodes('//eSearchResult/IdList') ) {
	($id) = $node->findvalue('Id/text()');
    }
    
    unlink $esearch;
    
    return $id;
}

sub fetch_file {
    my ($url, $file) = @_;

    my $response = HTTP::Tiny->new->get($url);

    unless ($response->{success}) {
        die "Can't get url $url -- Status: ", $response->{status}, " -- Reason: ", $response->{reason};
    }

    open my $out, '>', $file or die "\nERROR: Could not open file: $!\n";
    say $out $response->{content};
    close $out;

    return $response;
}

sub geturlfordb {
    my ($database, $em, $fam) = @_;
    my $url = URI->new('http://data.kew.org/cvalues/CvalServlet');
    
    if ($database =~ m/angiosperm/i) {
	$url->query_form(
			 'generatedby'         => $database,  
			 'querytype'           => "-1",    
			 'txtEmail'            => $em,       # uri_escape() from URI::Escape is called automatically. Nice!
			 'chkFamily'           => "on",
			 'selectfamilytype'    => "phyloFam",
			 'chkGenus'            => "on",
			 'chkSpecies'          => "on",
			 'chkChromosome'       => "on",
			 'chkPloidyLevel'      => "on",
			 'cmbFourcSelect'      => "1",   # this is the return type, currently 1C Mbp
			 'chkOrigReference'    => "on",
			 'cmbPrimeOrAllData'   => "0",
			 'txtFamily'           => $fam,
			 'qryfamilytype'       => "phyloFam",
			 'txtGenus'            => "",
			 'txtSpecies'          => "",
			 'txtAuthority'        => "",
			 'txtFromFourc'        => "",
			 'txtToFourc'          => "",
			 'txtFromChromosome'   => "",
			 'txtToChromosome'     => "",
			 'cmbEstimationMethod' => "0",
			 'txtFromPloidy'       => "",
			 'txtToPloidy'         => "",
			 'rdoVoucher'          => "2",
			 'cmbLifeCycle'        => "0",    # different for algae
			 'rdoAngioGroup'       => "3",
			 'cmbSort'             => "0",
			);
	return $url;
    }
    if ($database =~ m/gymnosperm/i) {
	$url->query_form(
			 'generatedby'         => $database,
			 'querytype'           => "-1",
			 'txtEmail'            => $em,
			 'chkFamily'           => "on",
			 'selectfamilytype'    => "pubFam",
			 'chkGenus'            => "on",
			 'chkSpecies'          => "on",
			 'chkChromosome'       => "on",
			 'chkPloidyLevel'      => "on",
			 'cmbFourcSelect'      => "1",
			 'chkOrigReference'    => "on",
			 'cmbPrimeOrAllData'   => "0",
			 'txtFamily'           => $fam,
			 'qryfamilytype'       => "pubFam",
			 'txtGenus'            => "",
			 'txtSpecies'          => "",
			 'txtAuthority'        => "",
			 'txtFromFourc'        => "",
			 'txtToFourc'          => "",
			 'txtFromChromosome'   => "",
			 'txtToChromosome'     => "",
			 'cmbEstimationMethod' => "0",
			 'txtFromPloidy'       => "",
			 'txtToPloidy'         => "",
			 'rdoVoucher'          => "2",
			 'cmdGymnoGroup'       => "0",
			 'cmbFlagellaNumber'   => "0",
			 'cmbSort'             => "0",
			);
	return $url;
    }
    if ($database =~ m/pteridophyte/i) {
	$url->query_form(
			 'generatedby'         => $database,
			 'querytype'           => "-1",
			 'txtEmail'            => $em,
			 'chkFamily'           => "on",
			 'selectfamilytype'    => "pubFam",
			 'chkGenus'            => "on",
			 'chkSpecies'          => "on",
			 'chkChromosome'       => "on",
			 'chkPloidyLevel'      => "on",
			 'cmbFourcSelect'      => "1",
			 'chkOrigReference'    => "on",
			 'cmbPrimeOrAllData'   => "0",
			 'txtFamily'           => $fam, #+Ophioglossaceae
			 'qryfamilytype'       => 'pubFam',
			 'txtGenus'            => "",
			 'txtSpecies'          => "",
			 'txtAuthority'        => "",
			 'txtFromFourc'        => "",
			 'txtToFourc'          => "",
			 'txtFromChromosome'   => "",
			 'txtToChromosome'     => "",
			 'cmbEstimationMethod' => "0",
			 'txtFromPloidy'       => "",
			 'txtToPloidy'         => "",
			 'rdoVoucher'          => "2",
			 'cmbSporeType'        => "0",
			 'cmbPteridoGroup'     => "0",
			 'cmbSporangium'       => "0",
			 'cmbSpermType'        => "0",
			 'cmbSort'             => "0",
			 );
	return $url;
    }
    if ($database =~ m/bryophyte/i) {
	$url->query_form(
			 'generatedby'         => $database,
			 'querytype'           => "-1",
			 'txtEmail'            => $em,
			 'chkFamily'           => "on",
			 'selectfamilytype'    => "pubFam",
			 'chkGenus'            => "on",
			 'chkSpecies'          => "on",
			 'chkChromosome'       => "on",
			 'chkPloidyLevel'      => "on",
			 'cmbFourcSelect'      => "1",
			 'chkOrigReference'    => "on",
			 'cmbPrimeOrAllData'   => "0",
			 'txtFamily'           => $fam,
			 'qryfamilytype'       => "pubFam",
			 'txtGenus'            => "",
			 'txtSpecies'          => "",
			 'txtAuthority'        => "",
			 'txtFromFourc'        => "",
			 'txtToFourc'          => "",
			 'txtFromChromosome'   => "",
			 'txtToChromosome'     => "",
			 'cmbEstimationMethod' => "0",
			 'txtFromPloidy'       => "",
			 'txtToPloidy'         => "",
			 'rdoVoucher'          => "2",
			 'cmbBryoGroup'        => "0",
			 'cmbSort'             => "0",
			 );
	return $url;
    }
    if ($database =~ m/algae/i) {
	$url->query_form(
			 'generatedby'         => $database,
			 'querytype'           => "-1",
			 'txtEmail'            => $em,
			 'chkFamily'           => "on",
			 'selectfamilytype'    => "pubFam",
			 'chkGenus'            => "on",
			 'chkSpecies'          => "on",
			 'chkChromosome'       => "on",
			 'chkPloidyLevel'      => "on",
			 'cmbFourcSelect'      => "1",
			 'chkOrigReference'    => "on",
			 'cmbPrimeOrAllData'   => "0",
			 'txtFamily'           => $fam,
			 'qryfamilytype'       => "pubFam",
			 'txtGenus'            => "",
			 'txtSpecies'          => "",
			 'txtAuthority'        => "",
			 'txtFromFourc'        => "",
			 'txtToFourc'          => "",
			 'txtFromChromosome'   => "",
			 'txtToChromosome'     => "",
			 'cmbEstimationMethod' => "0",
			 'txtFromPloidy'       => "",
			 'txtToPloidy'         => "",
			 'rdoVoucher'          => "2",
			 'cmdAlgaeGroup'       => "0",
			 'txtAlgaeOrder'       => "",
			 'cmbSort'             => "0",
			 );
	return $url;
    }
}
