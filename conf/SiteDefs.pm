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

    $SiteDefs::SITE_RELEASE_VERSION = '2';
    $SiteDefs::SITE_RELEASE_DATE = 'September 2014';
    $SiteDefs::ENSEMBL_USERDB_NAME = 'ensembl_accounts_pt';
    $SiteDefs::GENOMIC_UNIT = 'parasite';
    $SiteDefs::EBEYE_SEARCH_UNITS = [qw(parasite)];
    $SiteDefs::EBEYE_SITE_NAMES = {
      ena      => 'ENA',
      ensembl  => 'Ensembl',
      parasite => 'WormBase ParaSite',
    };
    $SiteDefs::ENSEMBL_ENASEARCH_ENABLED = 0;

    map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;

    $SiteDefs::ENSEMBL_PRIMARY_SPECIES  = 'Onchocerca_volvulus_prjeb513'; ## Default species
    $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Haemonchus_contortus_prjeb506'; ## Default species
    
	# ParaSite Specific Species

	# Release 1
	$SiteDefs::__species_aliases{'Acanthocheilonema_viteae_prjeb4306'} = [qw(acanthocheilonema_viteae_prjeb4306, Acanthocheilonema_viteae_prjeb4306)];
	$SiteDefs::__species_aliases{'Ancylostoma_caninum_prjna72585'} = [qw(ancylostoma_caninum_prjna72585, Ancylostoma_caninum_prjna72585)];
	$SiteDefs::__species_aliases{'Ancylostoma_ceylanicum_prjna231479'} = [qw(ancylostoma_ceylanicum_prjna231479, Ancylostoma_ceylanicum_prjna231479)];
	$SiteDefs::__species_aliases{'Ancylostoma_ceylanicum_prjna72583'} = [qw(ancylostoma_ceylanicum_prjna72583, Ancylostoma_ceylanicum_prjna72583)];
	$SiteDefs::__species_aliases{'Ancylostoma_duodenale_prjna72581'} = [qw(ancylostoma_duodenale_prjna72581, Ancylostoma_duodenale_prjna72581)];
	$SiteDefs::__species_aliases{'Angiostrongylus_cantonensis_prjeb493'} = [qw(angiostrongylus_cantonensis_prjeb493, Angiostrongylus_cantonensis_prjeb493)];
	$SiteDefs::__species_aliases{'Angiostrongylus_costaricensis_prjeb494'} = [qw(angiostrongylus_costaricensis_prjeb494, Angiostrongylus_costaricensis_prjeb494)];
	$SiteDefs::__species_aliases{'Anisakis_simplex_prjeb496'} = [qw(anisakis_simplex_prjeb496, Anisakis_simplex_prjeb496)];
	$SiteDefs::__species_aliases{'Ascaris_lumbricoides_prjeb495'} = [qw(ascaris_lumbricoides_prjeb495, Ascaris_lumbricoides_prjeb495)];
	$SiteDefs::__species_aliases{'Ascaris_suum_prjna62057'} = [qw(ascaris_suum_prjna62057, Ascaris_suum_prjna62057)];
	$SiteDefs::__species_aliases{'Ascaris_suum_prjna80881'} = [qw(ascaris_suum_prjna80881, Ascaris_suum_prjna80881)];
	$SiteDefs::__species_aliases{'Brugia_malayi_prjna10729'} = [qw(brugia_malayi_prjna10729, Brugia_malayi_prjna10729)];
	$SiteDefs::__species_aliases{'Brugia_pahangi_prjeb497'} = [qw(brugia_pahangi_prjeb497, Brugia_pahangi_prjeb497)];
	$SiteDefs::__species_aliases{'Brugia_timori_prjeb4663'} = [qw(brugia_timori_prjeb4663, Brugia_timori_prjeb4663)];
	$SiteDefs::__species_aliases{'Bursaphelenchus_xylophilus_prjea64437'} = [qw(bursaphelenchus_xylophilus_prjea64437, Bursaphelenchus_xylophilus_prjea64437)];
	$SiteDefs::__species_aliases{'Clonorchis_sinensis_prjda72781'} = [qw(clonorchis_sinensis_prjda72781, Clonorchis_sinensis_prjda72781)];
	$SiteDefs::__species_aliases{'Cylicostephanus_goldi_prjeb498'} = [qw(cylicostephanus_goldi_prjeb498, Cylicostephanus_goldi_prjeb498)];
	$SiteDefs::__species_aliases{'Dictyocaulus_viviparus_prjeb5116'} = [qw(dictyocaulus_viviparus_prjeb5116, Dictyocaulus_viviparus_prjeb5116)];
	$SiteDefs::__species_aliases{'Dictyocaulus_viviparus_prjna72587'} = [qw(dictyocaulus_viviparus_prjna72587, Dictyocaulus_viviparus_prjna72587)];
	$SiteDefs::__species_aliases{'Diphyllobothrium_latum_prjeb1206'} = [qw(diphyllobothrium_latum_prjeb1206, Diphyllobothrium_latum_prjeb1206)];
	$SiteDefs::__species_aliases{'Dirofilaria_immitis_prjeb1797'} = [qw(dirofilaria_immitis_prjeb1797, Dirofilaria_immitis_prjeb1797)];
	$SiteDefs::__species_aliases{'Dracunculus_medinensis_prjeb500'} = [qw(dracunculus_medinensis_prjeb500, Dracunculus_medinensis_prjeb500)];
	$SiteDefs::__species_aliases{'Echinococcus_granulosus_prjeb121'} = [qw(echinococcus_granulosus_prjeb121, Echinococcus_granulosus_prjeb121)];
	$SiteDefs::__species_aliases{'Echinococcus_multilocularis_prjeb122'} = [qw(echinococcus_multilocularis_prjeb122, Echinococcus_multilocularis_prjeb122)];
	$SiteDefs::__species_aliases{'Echinostoma_caproni_prjeb1207'} = [qw(echinostoma_caproni_prjeb1207, Echinostoma_caproni_prjeb1207)];
	$SiteDefs::__species_aliases{'Elaeophora_elaphi_prjeb502'} = [qw(elaeophora_elaphi_prjeb502, Elaeophora_elaphi_prjeb502)];
	$SiteDefs::__species_aliases{'Enterobius_vermicularis_prjeb503'} = [qw(enterobius_vermicularis_prjeb503, Enterobius_vermicularis_prjeb503)];
	$SiteDefs::__species_aliases{'Fasciola_hepatica_prjna179522'} = [qw(fasciola_hepatica_prjna179522, Fasciola_hepatica_prjna179522)];
	$SiteDefs::__species_aliases{'Globodera_pallida_prjeb123'} = [qw(globodera_pallida_prjeb123, Globodera_pallida_prjeb123)];
	$SiteDefs::__species_aliases{'Gongylonema_pulchrum_prjeb505'} = [qw(gongylonema_pulchrum_prjeb505, Gongylonema_pulchrum_prjeb505)];
	$SiteDefs::__species_aliases{'Haemonchus_contortus_prjeb506'} = [qw(haemonchus_contortus_prjeb506, Haemonchus_contortus_prjeb506)];
	$SiteDefs::__species_aliases{'Haemonchus_contortus_prjna205202'} = [qw(haemonchus_contortus_prjna205202, Haemonchus_contortus_prjna205202)];
	$SiteDefs::__species_aliases{'Haemonchus_contortus_prjna205202'} = [qw(haemonchus_contortus_prjna205202, Haemonchus_contortus_prjna205202)];
	$SiteDefs::__species_aliases{'Haemonchus_placei_prjeb509'} = [qw(haemonchus_placei_prjeb509, Haemonchus_placei_prjeb509)];
	$SiteDefs::__species_aliases{'Heligmosomoides_bakeri_prjeb1203'} = [qw(heligmosomoides_bakeri_prjeb1203, Heligmosomoides_bakeri_prjeb1203)];
	$SiteDefs::__species_aliases{'Heterorhabditis_bacteriophora_prjna13977'} = [qw(heterorhabditis_bacteriophora_prjna13977, Heterorhabditis_bacteriophora_prjna13977)];
	$SiteDefs::__species_aliases{'Hydatigera_taeniaeformis_prjeb534'} = [qw(hydatigera_taeniaeformis_prjeb534, Hydatigera_taeniaeformis_prjeb534)];
	$SiteDefs::__species_aliases{'Hymenolepis_diminuta_prjeb507'} = [qw(hymenolepis_diminuta_prjeb507, Hymenolepis_diminuta_prjeb507)];
	$SiteDefs::__species_aliases{'Hymenolepis_microstoma_prjeb124'} = [qw(hymenolepis_microstoma_prjeb124, Hymenolepis_microstoma_prjeb124)];
	$SiteDefs::__species_aliases{'Hymenolepis_nana_prjeb508'} = [qw(hymenolepis_nana_prjeb508, Hymenolepis_nana_prjeb508)];
	$SiteDefs::__species_aliases{'Litomosoides_sigmodontis_prjeb3075'} = [qw(litomosoides_sigmodontis_prjeb3075, Litomosoides_sigmodontis_prjeb3075)];
	$SiteDefs::__species_aliases{'Loa_loa_prjna60051'} = [qw(loa_loa_prjna60051, Loa_loa_prjna60051)];
	$SiteDefs::__species_aliases{'Meloidogyne_floridensis_prjeb6016'} = [qw(meloidogyne_floridensis_prjeb6016, Meloidogyne_floridensis_prjeb6016)];
	$SiteDefs::__species_aliases{'Meloidogyne_hapla_prjna29083'} = [qw(meloidogyne_hapla_prjna29083, Meloidogyne_hapla_prjna29083)];
	$SiteDefs::__species_aliases{'Meloidogyne_incognita_prjea28837'} = [qw(meloidogyne_incognita_prjea28837, Meloidogyne_incognita_prjea28837)];
	$SiteDefs::__species_aliases{'Mesocestoides_corti_prjeb510'} = [qw(mesocestoides_corti_prjeb510, Mesocestoides_corti_prjeb510)];
	$SiteDefs::__species_aliases{'Necator_americanus_prjna72135'} = [qw(necator_americanus_prjna72135, Necator_americanus_prjna72135)];
	$SiteDefs::__species_aliases{'Nippostrongylus_brasiliensis_prjeb511'} = [qw(nippostrongylus_brasiliensis_prjeb511, Nippostrongylus_brasiliensis_prjeb511)];
	$SiteDefs::__species_aliases{'Oesophagostomum_dentatum_prjna72579'} = [qw(oesophagostomum_dentatum_prjna72579, Oesophagostomum_dentatum_prjna72579)];
	$SiteDefs::__species_aliases{'Onchocerca_flexuosa_prjeb512'} = [qw(onchocerca_flexuosa_prjeb512, Onchocerca_flexuosa_prjeb512)];
	$SiteDefs::__species_aliases{'Onchocerca_ochengi_prjeb1204'} = [qw(onchocerca_ochengi_prjeb1204, Onchocerca_ochengi_prjeb1204)];
	$SiteDefs::__species_aliases{'Onchocerca_ochengi_prjeb1809'} = [qw(onchocerca_ochengi_prjeb1809, Onchocerca_ochengi_prjeb1809)];
	$SiteDefs::__species_aliases{'Onchocerca_volvulus_prjeb513'} = [qw(onchocerca_volvulus_prjeb513, Onchocerca_volvulus_prjeb513)];
	$SiteDefs::__species_aliases{'Parascaris_equorum_prjeb514'} = [qw(parascaris_equorum_prjeb514, Parascaris_equorum_prjeb514)];
	$SiteDefs::__species_aliases{'Parastrongyloides_trichosuri_prjeb515'} = [qw(parastrongyloides_trichosuri_prjeb515, Parastrongyloides_trichosuri_prjeb515)];
	$SiteDefs::__species_aliases{'Pristionchus_pacificus_prjna12644'} = [qw(pristionchus_pacificus_prjna12644, Pristionchus_pacificus_prjna12644)];
	$SiteDefs::__species_aliases{'Protopolystoma_xenopodis_prjeb1201'} = [qw(protopolystoma_xenopodis_prjeb1201, Protopolystoma_xenopodis_prjeb1201)];
	$SiteDefs::__species_aliases{'Rhabditophanes_kr3021_prjeb1297'} = [qw(rhabditophanes_kr3021_prjeb1297, Rhabditophanes_kr3021_prjeb1297)];
	$SiteDefs::__species_aliases{'Romanomermis_culicivorax_prjeb1358'} = [qw(romanomermis_culicivorax_prjeb1358, Romanomermis_culicivorax_prjeb1358)];
	$SiteDefs::__species_aliases{'Schistocephalus_solidus_prjeb527'} = [qw(schistocephalus_solidus_prjeb527, Schistocephalus_solidus_prjeb527)];
	$SiteDefs::__species_aliases{'Schistosoma_curassoni_prjeb519'} = [qw(schistosoma_curassoni_prjeb519, Schistosoma_curassoni_prjeb519)];
	$SiteDefs::__species_aliases{'Schistosoma_haematobium_prjna78265'} = [qw(schistosoma_haematobium_prjna78265, Schistosoma_haematobium_prjna78265)];
	$SiteDefs::__species_aliases{'Schistosoma_japonicum_prjea34885'} = [qw(schistosoma_japonicum_prjea34885, Schistosoma_japonicum_prjea34885)];
	$SiteDefs::__species_aliases{'Schistosoma_mansoni_prjea36577'} = [qw(schistosoma_mansoni_prjea36577, Schistosoma_mansoni_prjea36577)];
	$SiteDefs::__species_aliases{'Schistosoma_margrebowiei_prjeb522'} = [qw(schistosoma_margrebowiei_prjeb522, Schistosoma_margrebowiei_prjeb522)];
	$SiteDefs::__species_aliases{'Schistosoma_mattheei_prjeb523'} = [qw(schistosoma_mattheei_prjeb523, Schistosoma_mattheei_prjeb523)];
	$SiteDefs::__species_aliases{'Schistosoma_rodhaini_prjeb526'} = [qw(schistosoma_rodhaini_prjeb526, Schistosoma_rodhaini_prjeb526)];
	$SiteDefs::__species_aliases{'Schmidtea_mediterranea_prjna12585'} = [qw(schmidtea_mediterranea_prjna12585, Schmidtea_mediterranea_prjna12585)];
	$SiteDefs::__species_aliases{'Soboliphyme_baturini_prjeb516'} = [qw(soboliphyme_baturini_prjeb516, Soboliphyme_baturini_prjeb516)];
	$SiteDefs::__species_aliases{'Spirometra_erinaceieuropaei_prjeb1202'} = [qw(spirometra_erinaceieuropaei_prjeb1202, Spirometra_erinaceieuropaei_prjeb1202)];
	$SiteDefs::__species_aliases{'Strongyloides_papillosus_prjeb525'} = [qw(strongyloides_papillosus_prjeb525, Strongyloides_papillosus_prjeb525)];
	$SiteDefs::__species_aliases{'Strongyloides_ratti_prjeb125'} = [qw(strongyloides_ratti_prjeb125, Strongyloides_ratti_prjeb125)];
	$SiteDefs::__species_aliases{'Strongyloides_stercoralis_prjeb528'} = [qw(strongyloides_stercoralis_prjeb528, Strongyloides_stercoralis_prjeb528)];
	$SiteDefs::__species_aliases{'Strongyloides_venezuelensis_prjeb530'} = [qw(strongyloides_venezuelensis_prjeb530, Strongyloides_venezuelensis_prjeb530)];
	$SiteDefs::__species_aliases{'Strongylus_vulgaris_prjeb531'} = [qw(strongylus_vulgaris_prjeb531, Strongylus_vulgaris_prjeb531)];
	$SiteDefs::__species_aliases{'Syphacia_muris_prjeb524'} = [qw(syphacia_muris_prjeb524, Syphacia_muris_prjeb524)];
	$SiteDefs::__species_aliases{'Taenia_asiatica_prjeb532'} = [qw(taenia_asiatica_prjeb532, Taenia_asiatica_prjeb532)];
	$SiteDefs::__species_aliases{'Taenia_solium_prjna170813'} = [qw(taenia_solium_prjna170813, Taenia_solium_prjna170813)];
	$SiteDefs::__species_aliases{'Teladorsagia_circumcincta_prjna72569'} = [qw(teladorsagia_circumcincta_prjna72569, Teladorsagia_circumcincta_prjna72569)];
	$SiteDefs::__species_aliases{'Thelazia_callipaeda_prjeb1205'} = [qw(thelazia_callipaeda_prjeb1205, Thelazia_callipaeda_prjeb1205)];
	$SiteDefs::__species_aliases{'Toxocara_canis_prjeb533'} = [qw(toxocara_canis_prjeb533, Toxocara_canis_prjeb533)];
	$SiteDefs::__species_aliases{'Trichinella_nativa_prjna179527'} = [qw(trichinella_nativa_prjna179527, Trichinella_nativa_prjna179527)];
	$SiteDefs::__species_aliases{'Trichinella_spiralis_prjna12603'} = [qw(trichinella_spiralis_prjna12603, Trichinella_spiralis_prjna12603)];
	$SiteDefs::__species_aliases{'Trichobilharzia_regenti_prjeb4662'} = [qw(trichobilharzia_regenti_prjeb4662, Trichobilharzia_regenti_prjeb4662)];
	$SiteDefs::__species_aliases{'Trichuris_muris_prjeb126'} = [qw(trichuris_muris_prjeb126, Trichuris_muris_prjeb126)];
	$SiteDefs::__species_aliases{'Trichuris_suis_prjna179528'} = [qw(trichuris_suis_prjna179528, Trichuris_suis_prjna179528)];
	$SiteDefs::__species_aliases{'Trichuris_suis_prjna208415'} = [qw(trichuris_suis_prjna208415, Trichuris_suis_prjna208415, Trichuris_suis_prjna208415_-_male)];
	$SiteDefs::__species_aliases{'Trichuris_suis_prjna208416'} = [qw(trichuris_suis_prjna208416, Trichuris_suis_prjna208416, Trichuris_suis_prjna208416_-_female)];
	$SiteDefs::__species_aliases{'Trichuris_trichiura_prjeb535'} = [qw(trichuris_trichiura_prjeb535, Trichuris_trichiura_prjeb535)];
	$SiteDefs::__species_aliases{'Wuchereria_bancrofti_prjeb536'} = [qw(wuchereria_bancrofti_prjeb536, Wuchereria_bancrofti_prjeb536)];

	@SiteDefs::ENSEMBL_PERL_DIRS    = (
										   $SiteDefs::ENSEMBL_WEBROOT.'/perl',
										   $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
										   $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/perl',
					   );

	$SiteDefs::SITE_NAME = 'WormBase ParaSite';
	$SiteDefs::ENSEMBL_SITETYPE = 'WormBase ParaSite';
	$SiteDefs::SITE_FTP= 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite';

	$SiteDefs::DOCSEARCH_INDEX_DIR = $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/data/docsearch';

}

1;
