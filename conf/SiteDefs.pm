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
    $SiteDefs::SITE_RELEASE_DATE = '[Insert release date here in eg-web-parasite/conf/SiteDefs.pm]';

    $SiteDefs::SITE_MISSION = 'Blurb about ParaSite here in eg-web-parasite/conf/SiteDefs.pm';

    map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;

    $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Onchocerca_volvulus_PRJEB513'; ## Default species
    $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Ancylostoma_caninum_PRJNA72585'; ## Default species
    
# ParaSite Specific Species

# 50HGP species
$SiteDefs::__species_aliases{'Acanthocheilonema_viteae_PRJEB4306'} = [qw(Acanthocheilonema_viteae_PRJEB4306)];
$SiteDefs::__species_aliases{'Ancylostoma_caninum_PRJNA72585'} = [qw(Ancylostoma_caninum_PRJNA72585)];
$SiteDefs::__species_aliases{'Ancylostoma_ceylanicum_PRJNA72583'} = [qw(Ancylostoma_ceylanicum_PRJNA72583)];
$SiteDefs::__species_aliases{'Ancylostoma_duodenale_PRJNA72581'} = [qw(Ancylostoma_duodenale_PRJNA72581)];
$SiteDefs::__species_aliases{'Angiostrongylus_cantonensis_PRJEB493'} = [qw(Angiostrongylus_cantonensis_PRJEB493)];
$SiteDefs::__species_aliases{'Angiostrongylus_costaricensis_PRJEB494'} = [qw(Angiostrongylus_costaricensis_PRJEB494)];
$SiteDefs::__species_aliases{'Anisakis_simplex_PRJEB496'} = [qw(Anisakis_simplex_PRJEB496)];
$SiteDefs::__species_aliases{'Ascaris_lumbricoides_PRJEB495'} = [qw(Ascaris_lumbricoides_PRJEB495)];
$SiteDefs::__species_aliases{'Ascaris_suum_PRJNA62057'} = [qw(Ascaris_suum_PRJNA62057)];
$SiteDefs::__species_aliases{'Brugia_malayi_PRJNA10729'} = [qw(Brugia_malayi_PRJNA10729)];
$SiteDefs::__species_aliases{'Brugia_pahangi_PRJEB497'} = [qw(Brugia_pahangi_PRJEB497)];
$SiteDefs::__species_aliases{'Brugia_timori_PRJEB4663'} = [qw(Brugia_timori_PRJEB4663)];
$SiteDefs::__species_aliases{'Bursaphelenchus_xylophilus_PRJEA64437'} = [qw(Bursaphelenchus_xylophilus_PRJEA64437)];
$SiteDefs::__species_aliases{'Clonorchis_sinensis_PRJNA33229'} = [qw(Clonorchis_sinensis_PRJNA33229)];
$SiteDefs::__species_aliases{'Cylicostephanus_goldi_PRJEB498'} = [qw(Cylicostephanus_goldi_PRJEB498)];
$SiteDefs::__species_aliases{'Dictyocaulus_viviparus_PRJNA72587'} = [qw(Dictyocaulus_viviparus_PRJNA72587)];
$SiteDefs::__species_aliases{'Diphyllobothrium_latum_PRJEB1206'} = [qw(Diphyllobothrium_latum_PRJEB1206)];
$SiteDefs::__species_aliases{'Dirofilaria_immitis_PRJEB593'} = [qw(Dirofilaria_immitis_PRJEB593)];
$SiteDefs::__species_aliases{'Dracunculus_medinensis_PRJEB500'} = [qw(Dracunculus_medinensis_PRJEB500)];
$SiteDefs::__species_aliases{'Echinococcus_granulosus_PRJEB121'} = [qw(Echinococcus_granulosus_PRJEB121)];
$SiteDefs::__species_aliases{'Echinococcus_multilocularis_PRJEB122'} = [qw(Echinococcus_multilocularis_PRJEB122)];
$SiteDefs::__species_aliases{'Echinostoma_caproni_PRJEB1207'} = [qw(Echinostoma_caproni_PRJEB1207)];
$SiteDefs::__species_aliases{'Elaeophora_elaphi_PRJEB502'} = [qw(Elaeophora_elaphi_PRJEB502)];
$SiteDefs::__species_aliases{'Enterobius_vermicularis_PRJEB503'} = [qw(Enterobius_vermicularis_PRJEB503)];
$SiteDefs::__species_aliases{'Fasciola_hepatica_PRJNA179522'} = [qw(Fasciola_hepatica_PRJNA179522)];
$SiteDefs::__species_aliases{'Globodera_pallida_PRJEB123'} = [qw(Globodera_pallida_PRJEB123)];
$SiteDefs::__species_aliases{'Gongylonema_pulchrum_PRJEB505'} = [qw(Gongylonema_pulchrum_PRJEB505)];
$SiteDefs::__species_aliases{'Haemonchus_contortus_PRJEB506'} = [qw(Haemonchus_contortus_PRJEB506)];
$SiteDefs::__species_aliases{'Haemonchus_placei_PRJEB509'} = [qw(Haemonchus_placei_PRJEB509)];
$SiteDefs::__species_aliases{'Heligmosomoides_polygyrus_bakeri_PRJEB1203'} = [qw(Heligmosomoides_polygyrus_bakeri_PRJEB1203)];
$SiteDefs::__species_aliases{'Hymenolepis_diminuta_PRJEB507'} = [qw(Hymenolepis_diminuta_PRJEB507)];
$SiteDefs::__species_aliases{'Hymenolepis_microstoma_PRJEB124'} = [qw(Hymenolepis_microstoma_PRJEB124)];
$SiteDefs::__species_aliases{'Hymenolepis_nana_PRJEB508'} = [qw(Hymenolepis_nana_PRJEB508)];
$SiteDefs::__species_aliases{'Litomosoides_sigmodontis_PRJEB3075'} = [qw(Litomosoides_sigmodontis_PRJEB3075)];
$SiteDefs::__species_aliases{'Loa_loa_PRJNA60051'} = [qw(Loa_loa_PRJNA60051)];
$SiteDefs::__species_aliases{'Meloidogyne_hapla_PRJNA29083'} = [qw(Meloidogyne_hapla_PRJNA29083)];
$SiteDefs::__species_aliases{'Mesocestoides_corti_PRJEB510'} = [qw(Mesocestoides_corti_PRJEB510)];
$SiteDefs::__species_aliases{'Necator_americanus_PRJNA72135'} = [qw(Necator_americanus_PRJNA72135)];
$SiteDefs::__species_aliases{'Nippostrongylus_brasiliensis_PRJEB511'} = [qw(Nippostrongylus_brasiliensis_PRJEB511)];
$SiteDefs::__species_aliases{'Oesophagostomum_dentatum_PRJNA72579'} = [qw(Oesophagostomum_dentatum_PRJNA72579)];
$SiteDefs::__species_aliases{'Onchocerca_flexuosa_PRJEB512'} = [qw(Onchocerca_flexuosa_PRJEB512)];
$SiteDefs::__species_aliases{'Onchocerca_ochengi_PRJEB1809'} = [qw(Onchocerca_ochengi_PRJEB1809)];
$SiteDefs::__species_aliases{'Onchocerca_volvulus_PRJEB513'} = [qw(Onchocerca_volvulus_PRJEB513)];
$SiteDefs::__species_aliases{'Parascaris_equorum_PRJEB514'} = [qw(Parascaris_equorum_PRJEB514)];
$SiteDefs::__species_aliases{'Parastrongyloides_trichosuri_PRJEB515'} = [qw(Parastrongyloides_trichosuri_PRJEB515)];
$SiteDefs::__species_aliases{'Pristionchus_pacificus_PRJNA12644'} = [qw(Pristionchus_pacificus_PRJNA12644)];
$SiteDefs::__species_aliases{'Protopolystoma_xenopodis_PRJEB1201'} = [qw(Protopolystoma_xenopodis_PRJEB1201)];
$SiteDefs::__species_aliases{'Rhabditophanes_sp_PRJEB1297'} = [qw(Rhabditophane_sp_PRJEB1297)];
$SiteDefs::__species_aliases{'Romanomermis_culicivorax_PRJEB1358'} = [qw(Romanomermis_culicivorax_PRJEB1358)];
$SiteDefs::__species_aliases{'Schistocephalus_solidus_PRJEB527'} = [qw(Schistocephalus_solidus_PRJEB527)];
$SiteDefs::__species_aliases{'Schistosoma_curassoni_PRJEB519'} = [qw(Schistosoma_curassoni_PRJEB519)];
$SiteDefs::__species_aliases{'Schistosoma_haematobium_PRJNA78265'} = [qw(Schistosoma_haematobium_PRJNA78265)];
$SiteDefs::__species_aliases{'Schistosoma_japonicum_PRJEA34885'} = [qw(Schistosoma_japonicum_PRJEA34885)];
$SiteDefs::__species_aliases{'Schistosoma_mansoni_PRJEA36577'} = [qw(Schistosoma_mansoni_PRJEA36577)];
$SiteDefs::__species_aliases{'Schistosoma_margrebowiei_PRJEB522'} = [qw(Schistosoma_margrebowiei_PRJEB522)];
$SiteDefs::__species_aliases{'Schistosoma_mattheei_PRJEB523'} = [qw(Schistosoma_mattheei_PRJEB523)];
$SiteDefs::__species_aliases{'Schistosoma_rodhaini_PRJEB526'} = [qw(Schistosoma_rodhaini_PRJEB526)];
$SiteDefs::__species_aliases{'Schmidtea_mediterranea_PRJNA12585'} = [qw(Schmidtea_mediterranea_PRJNA12585)];
$SiteDefs::__species_aliases{'Soboliphyme_baturini_PRJEB516'} = [qw(Soboliphyme_baturini_PRJEB516)];
$SiteDefs::__species_aliases{'Spirometra_erinaceieuropaei_PRJEB1202'} = [qw(Spirometra_erinaceieuropaei_PRJEB1202)];
$SiteDefs::__species_aliases{'Strongyloides_papillosus_PRJEB525'} = [qw(Strongyloides_papillosus_PRJEB525)];
$SiteDefs::__species_aliases{'Strongyloides_ratti_PRJEB125'} = [qw(Strongyloides_ratti_PRJEB125)];
$SiteDefs::__species_aliases{'Strongyloides_stercoralis_PRJEB528'} = [qw(Strongyloides_stercoralis_PRJEB528)];
$SiteDefs::__species_aliases{'Strongyloides_venezuelensis_PRJEB530'} = [qw(Strongyloides_venezuelensis_PRJEB530)];
$SiteDefs::__species_aliases{'Strongylus_vulgaris_PRJEB531'} = [qw(Strongylus_vulgaris_PRJEB531)];
$SiteDefs::__species_aliases{'Syphacia_muris_PRJEB524'} = [qw(Syphacia_muris_PRJEB524)];
$SiteDefs::__species_aliases{'Taenia_asiatica_PRJEB532'} = [qw(Taenia_asiatica_PRJEB532)];
$SiteDefs::__species_aliases{'Taenia_solium_PRJNA170813'} = [qw(Taenia_solium_PRJNA170813)];
$SiteDefs::__species_aliases{'Taenia_taeniaeformis_PRJEB534'} = [qw(Taenia_taeniaeformis_PRJEB534)];
$SiteDefs::__species_aliases{'Teladorsagia_circumcincta_PRJNA72569'} = [qw(Teladorsagia_circumcincta_PRJNA72569)];
$SiteDefs::__species_aliases{'Thelazia_callipaeda_PRJEB1205'} = [qw(Thelazia_callipaeda_PRJEB1205)];
$SiteDefs::__species_aliases{'Toxocara_canis_PRJEB533'} = [qw(Toxocara_canis_PRJEB533)];
$SiteDefs::__species_aliases{'Trichinella_nativa_PRJNA179527'} = [qw(Trichinella_nativa_PRJNA179527)];
$SiteDefs::__species_aliases{'Trichobilharzia_regenti_PRJEB4662'} = [qw(Trichobilharzia_regenti_PRJEB4662)];
$SiteDefs::__species_aliases{'Trichinella_spiralis_PRJNA12603'} = [qw(Trichinella_spiralis_PRJNA12603)];
$SiteDefs::__species_aliases{'Trichuris_muris_PRJEB126'} = [qw(Trichuris_muris_PRJEB126)];
$SiteDefs::__species_aliases{'Trichuris_suis_PRJNA179528'} = [qw(Trichuris_suis_PRJNA179528)];
$SiteDefs::__species_aliases{'Trichuris_trichiura_PRJEB535'} = [qw(Trichuris_trichiura_PRJEB535)];
$SiteDefs::__species_aliases{'Wuchereria_bancrofti_PRJEB536'} = [qw(Wuchereria_bancrofti_PRJEB536)];

# ParaSite specific species for release 1
$SiteDefs::__species_aliases{'Ancylostoma_ceylanicum_PRJNA231479'} = [qw(Ancylostoma_ceylanicum_PRJNA231479)];
$SiteDefs::__species_aliases{'Ascaris_suum_PRJNA80881'} = [qw(Ascaris_suum_PRJNA80881)];
$SiteDefs::__species_aliases{'Dictyocaulus_viviparus_PRJEB5116'} = [qw(Dictyocaulus_viviparus_PRJEB5116)];
$SiteDefs::__species_aliases{'Haemonchus_contortus_PRJNA205202'} = [qw(Haemonchus_contortus_PRJNA205202)];
$SiteDefs::__species_aliases{'Heterodera_glycines_PRJNA28939'} = [qw(Heterodera_glycines_PRJNA28939)];
$SiteDefs::__species_aliases{'Heterorhabditis_bacteriophora_PRJNA13977'} = [qw(Heterorhabditis_bacteriophora_PRJNA13977)];
$SiteDefs::__species_aliases{'Meloidogyne_floridensis_PRJEB2953'} = [qw(Meloidogyne_floridensis_PRJEB2953)];
$SiteDefs::__species_aliases{'Meloidogyne_incognita_PRJEA28837'} = [qw(Meloidogyne_incognita_PRJEA28837)];
$SiteDefs::__species_aliases{'Trichuris_suis_PRJNA208415'} = [qw(Trichuris_suis_PRJNA208415)];
$SiteDefs::__species_aliases{'Trichuris_suis_PRJNA208416'} = [qw(Trichuris_suis_PRJNA208416)];



    @SiteDefs::ENSEMBL_PERL_DIRS    = (
                                           $SiteDefs::ENSEMBL_WEBROOT.'/perl',
                                           $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
                                           $SiteDefs::ENSEMBL_SERVERROOT.'/ps-web/perl',
				       );

    $SiteDefs::SITE_NAME = 'WormBase-ParaSite';
    $SiteDefs::ENSEMBL_SITETYPE = 'WormBase-ParaSite';
    $SiteDefs::SITE_FTP= 'ftp://ftp.ensemblgenomes.org/pub/metazoa';
    push @SiteDefs::ENSEMBL_HTDOCS_DIRS,  $SiteDefs::ENSEMBL_SERVERROOT.'/../biomarts/parasite/biomart-perl/htdocs';
    
    $SiteDefs::DOCSEARCH_INDEX_DIR = $SiteDefs::ENSEMBL_SERVERROOT.'/ps-web/data/docsearch';

    $SiteDefs::ENA_COLLECTION_ID = 223;

    $SiteDefs::ENA_SAMPLE_SEQ = "MSLKPKIVEFVDVWPRLRCIAESVITLTKVERSVWNTSFSDVYTLCVAQPEPMADRLYGETKHFLEQHVQEMLAKKVLIEGECSHSNGGPDLLQRYYITWMEYSQGIKYLHQLYIYLNQQHIKKQKITDTESFYGNLSSDAAEQMEIGELGLDIWRLYMIEYLSSELVRHILEGIAADRASNGTLDHHRVQIINGVIHSFVEVQDYKKTGSLKLYQELFEGPMLEASGAYYTDEANKLLHRCSVSEYMQEVIRILEYESRRAQKFLHVSSLPKLRKECEEKFINDRLGFIYSECREMVSEERRQDLRNMYVVLKPIPDNLKSELITTFLDHIKSEGLQTVSALKGENIHIAFVENMLKVHHKYQELIADVFENDSLFLSALDKACASVINRRPTERQPCRSAEYVAKYCDTLLKKSKTCEAEIDQKLTNNITIFKYIEDKDVYQKFYSRLLAKRLIHEQSQSMDAEEGMINRLKQACGYEFTNKLHRMFTDISVSVDLNNKFNTHLKDSNVDLGINLAIKVLQAGAWPLGSTQVIPFAVPQEFEKSIKMFEDYYHKLFSGRKLTWLHHMCHGELKLSHLKKSYIVTMQTYQMAIILLFETCDSLSCREIQNTLQLNDETFQKHMQPIIESKLLNASSENLAGETRIELNLDYTNKRTKFK";

}

1;
