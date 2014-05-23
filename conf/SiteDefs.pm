=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EG::Web::ParaSite::SiteDefs;
use strict;

sub update_conf {
    $SiteDefs::ENSEMBL_PORT           = 9101;

    $SiteDefs::ENSEMBL_SERVERNAME     = 'gunpowder.ebi.ac.uk';

    $SiteDefs::SITE_RELEASE_VERSION = '1';
    $SiteDefs::SITE_RELEASE_DATE = 'June 2014';

    $SiteDefs::EBEYE_SEARCH_UNITS = [qw(parasite)];
    $SiteDefs::EBEYE_SITE_NAMES = {
      ena      => 'ENA',
      ensembl  => 'Ensembl',
      parasite => 'WormBase ParaSite',
    };

    map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;

    $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Onchocerca_volvulus_prjeb513'; ## Default species
    $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Haemonchus_contortus_prjeb506'; ## Default species
    
	# ParaSite Specific Species

	# Release 0.1
	$SiteDefs::__species_aliases{'Ancylostoma_ceylanicum_prjna231479'} = [qw(ancylostoma_ceylanicum_prjna231479, Ancylostoma_ceylanicum_prjna231479)];
	$SiteDefs::__species_aliases{'Ascaris_suum_prjna62057'} = [qw(ascaris_suum_prjna62057, Ascaris_suum_prjna62057)];
	$SiteDefs::__species_aliases{'Ascaris_suum_prjna80881'} = [qw(ascaris_suum_prjna80881, Ascaris_suum_prjna80881)];
	$SiteDefs::__species_aliases{'Brugia_malayi_prjna10729'} = [qw(brugia_malayi_prjna10729, Brugia_malayi_prjna10729)];
	$SiteDefs::__species_aliases{'Bursaphelenchus_xylophilus_prjea64437'} = [qw(bursaphelenchus_xylophilus_prjea64437, Bursaphelenchus_xylophilus_prjea64437)];
	$SiteDefs::__species_aliases{'Dirofilaria_immitis_prjeb1797'} = [qw(dirofilaria_immitis_prjeb1797, Dirofilaria_immitis_prjeb1797)];
	$SiteDefs::__species_aliases{'Haemonchus_contortus_prjeb506'} = [qw(haemonchus_contortus_prjeb506, Haemonchus_contortus_prjeb506)];
	$SiteDefs::__species_aliases{'Haemonchus_contortus_prjna205202'} = [qw(haemonchus_contortus_prjna205202, Haemonchus_contortus_prjna205202)];
	$SiteDefs::__species_aliases{'Heterorhabditis_bacteriophora_prjna13977'} = [qw(heterorhabditis_bacteriophora_prjna13977, Heterorhabditis_bacteriophora_prjna13977)];
	$SiteDefs::__species_aliases{'Loa_loa_prjna60051'} = [qw(loa_loa_prjna60051, Loa_loa_prjna60051)];
	$SiteDefs::__species_aliases{'Meloidogyne_hapla_prjna29083'} = [qw(meloidogyne_hapla_prjna29083, Meloidogyne_hapla_prjna29083)];
	$SiteDefs::__species_aliases{'Meloidogyne_incognita_prjea28837'} = [qw(meloidogyne_incognita_prjea28837, Meloidogyne_incognita_prjea28837)];
	$SiteDefs::__species_aliases{'Necator_americanus_prjna72135'} = [qw(necator_americanus_prjna72135, Necator_americanus_prjna72135)];
	$SiteDefs::__species_aliases{'Onchocerca_volvulus_prjeb513'} = [qw(onchocerca_volvulus_prjeb513, Onchocerca_volvulus_prjeb513)];
	$SiteDefs::__species_aliases{'Trichinella_spiralis_prjna12603'} = [qw(trichinella_spiralis_prjna12603, Trichinella_spiralis_prjna12603)];
	$SiteDefs::__species_aliases{'Trichuris_suis_prjna208415'} = [qw(trichuris_suis_prjna208415, Trichuris_suis_prjna208415)];
	$SiteDefs::__species_aliases{'Trichuris_suis_prjna208416'} = [qw(trichuris_suis_prjna208416, Trichuris_suis_prjna208416)];

	@SiteDefs::ENSEMBL_PERL_DIRS    = (
										   $SiteDefs::ENSEMBL_WEBROOT.'/perl',
										   $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
										   $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/perl',
					   );

	$SiteDefs::SITE_NAME = 'WormBase ParaSite';
	$SiteDefs::ENSEMBL_SITETYPE = 'WormBase ParaSite';
	$SiteDefs::SITE_FTP= 'ftp://ftp.ensemblgenomes.org/pub/metazoa';

	$SiteDefs::DOCSEARCH_INDEX_DIR = $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/data/docsearch';

	$SiteDefs::ENA_COLLECTION_ID = 223;

	$SiteDefs::ENA_SAMPLE_SEQ = "MSLKPKIVEFVDVWPRLRCIAESVITLTKVERSVWNTSFSDVYTLCVAQPEPMADRLYGETKHFLEQHVQEMLAKKVLIEGECSHSNGGPDLLQRYYITWMEYSQGIKYLHQLYIYLNQQHIKKQKITDTESFYGNLSSDAAEQMEIGELGLDIWRLYMIEYLSSELVRHILEGIAADRASNGTLDHHRVQIINGVIHSFVEVQDYKKTGSLKLYQELFEGPMLEASGAYYTDEANKLLHRCSVSEYMQEVIRILEYESRRAQKFLHVSSLPKLRKECEEKFINDRLGFIYSECREMVSEERRQDLRNMYVVLKPIPDNLKSELITTFLDHIKSEGLQTVSALKGENIHIAFVENMLKVHHKYQELIADVFENDSLFLSALDKACASVINRRPTERQPCRSAEYVAKYCDTLLKKSKTCEAEIDQKLTNNITIFKYIEDKDVYQKFYSRLLAKRLIHEQSQSMDAEEGMINRLKQACGYEFTNKLHRMFTDISVSVDLNNKFNTHLKDSNVDLGINLAIKVLQAGAWPLGSTQVIPFAVPQEFEKSIKMFEDYYHKLFSGRKLTWLHHMCHGELKLSHLKKSYIVTMQTYQMAIILLFETCDSLSCREIQNTLQLNDETFQKHMQPIIESKLLNASSENLAGETRIELNLDYTNKRTKFK";

}

1;
