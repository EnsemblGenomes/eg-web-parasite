=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

    ### Release Configuration - to be updated for each release
    $SiteDefs::SITE_RELEASE_VERSION = '10';
    $SiteDefs::WORMBASE_RELEASE_VERSION = '260';
    $SiteDefs::SITE_RELEASE_DATE = 'August 2017';
    
    ### Website Configuration
    $SiteDefs::SITE_NAME = 'WormBase ParaSite';
    $SiteDefs::ENSEMBL_SITETYPE = 'WormBase ParaSite';
    $SiteDefs::EG_DIVISION = 'parasite';
    $SiteDefs::GENOMIC_UNIT = 'parasite';
    $SiteDefs::ENSEMBL_PORT = 8032;
    $SiteDefs::ENSEMBL_SERVERNAME = 'parasite.wormbase.org';
    $SiteDefs::SITE_FTP= 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite';
    
    ### Database Configuration
    $SiteDefs::ENSEMBL_USERDB_NAME = 'ensembl_accounts_wbps';
    
    ### Search Configuration
    $SiteDefs::EBEYE_SEARCH_UNITS = [qw(parasite wormbase)];
    $SiteDefs::EBEYE_SITE_NAMES = {
      parasite => 'WormBase ParaSite',
      wormbase => 'WormBase',
    };
    $SiteDefs::EBEYE_SEARCH_DOMAIN = 'wormbaseParasite';

    ### Tools Configuration
    $SiteDefs::ENSEMBL_BLAST_ENABLED     = 1;
    $SiteDefs::ENSEMBL_VEP_ENABLED       = 1;
    $SiteDefs::ENSEMBL_MART_ENABLED      = 0; # This is switched off to prevent automatic BioMart startup
    $SiteDefs::ENSEMBL_AC_ENABLED        = 0;
    $SiteDefs::ENSEMBL_IDM_ENABLED       = 0;
    $SiteDefs::ENSEMBL_ENASEARCH_ENABLED = 0;
    $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER->{Blast} = 'NcbiBlast';
    $SiteDefs::EBI_BLAST_DB_PREFIX = 'wormbase-parasite';
    $SiteDefs::ENSEMBL_VEP_PLUGIN_CONFIG_FILES  = [
                  $SiteDefs::ENSEMBL_SERVERROOT.'/VEP_plugins/plugin_config.txt', # VEP_plugins is cloned from github.com/ensembl-variation/VEP_plugins
                  $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/conf/vep_plugins_web_config.txt'
                ];
    
    ### GXA widget config
    $SiteDefs::GXA = 0;  # Enable this in each species ini file if GXA widget is required for that species
    
    ### URLs for external services
    $SiteDefs::NCBIBLAST_REST_ENDPOINT = 'http://www.ebi.ac.uk/Tools/services/rest/ncbiblast';
    $SiteDefs::EBEYE_REST_ENDPOINT     = 'http://www.ebi.ac.uk/ebisearch/ws/rest';
    $SiteDefs::GXA_REST_URL            = 'http://www.ebi.ac.uk/gxa/json/expressionData?geneId=';
    $SiteDefs::GXA_EBI_URL             = 'http://www.ebi.ac.uk/gxa/resources';
    $SiteDefs::EVA_URL                 = 'http://www.ebi.ac.uk/eva';

    ### Species Configuration
    map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;
    $SiteDefs::PRODUCTION_NAMES = [sort qw(
      Acanthocheilonema_viteae_prjeb4306
      Ancylostoma_caninum_prjna72585
      Ancylostoma_ceylanicum_prjna231479
      Ancylostoma_ceylanicum_prjna72583
      Ancylostoma_duodenale_prjna72581
      Angiostrongylus_cantonensis_prjeb493
      Angiostrongylus_costaricensis_prjeb494
      Anisakis_simplex_prjeb496
      Ascaris_lumbricoides_prjeb4950
      Ascaris_suum_prjna62057
      Ascaris_suum_prjna80881
      Brugia_malayi_prjna10729
      Brugia_pahangi_prjeb497
      Brugia_timori_prjeb4663
      Bursaphelenchus_xylophilus_prjea64437
      Caenorhabditis_angaria_prjna51225
      Caenorhabditis_brenneri_prjna20035
      Caenorhabditis_briggsae_prjna10731
      Caenorhabditis_elegans_prjna13758
      Caenorhabditis_japonica_prjna12591
      Caenorhabditis_remanei_prjna53967
      Caenorhabditis_sinica_prjna194557
      Caenorhabditis_tropicalis_prjna53597
      Clonorchis_sinensis_prjda72781
      Cylicostephanus_goldi_prjeb498
      Dictyocaulus_viviparus_prjeb5116
      Dictyocaulus_viviparus_prjna72587
      Diphyllobothrium_latum_prjeb1206
      Dirofilaria_immitis_prjeb1797
      Ditylenchus_destructor_prjna312427
      Dracunculus_medinensis_prjeb500
      Echinococcus_canadensis_prjeb8992
      Echinococcus_granulosus_prjeb121
      Echinococcus_granulosus_prjna182977
      Echinococcus_multilocularis_prjeb122
      Echinostoma_caproni_prjeb1207
      Elaeophora_elaphi_prjeb502
      Enterobius_vermicularis_prjeb503
      Fasciola_hepatica_prjeb6687
      Fasciola_hepatica_prjna179522
      Globodera_pallida_prjeb123
      Globodera_rostochiensis_prjeb13504
      Gongylonema_pulchrum_prjeb505
      Gyrodactylus_salaris_prjna244375
      Haemonchus_contortus_prjeb506
      Haemonchus_contortus_prjna205202
      Haemonchus_placei_prjeb509
      Heligmosomoides_polygyrus_prjeb1203
      Heligmosomoides_polygyrus_prjeb15396
      Heterorhabditis_bacteriophora_prjna13977
      Hydatigera_taeniaeformis_prjeb534
      Hymenolepis_diminuta_prjeb507
      Hymenolepis_microstoma_prjeb124
      Hymenolepis_nana_prjeb508
      Litomosoides_sigmodontis_prjeb3075
      Loa_loa_prjna246086
      Loa_loa_prjna60051
      Macrostomum_lignano_prjna284736
      Meloidogyne_floridensis_prjeb6016
      Meloidogyne_hapla_prjna29083
      Meloidogyne_incognita_prjea28837
      Mesocestoides_corti_prjeb510
      Necator_americanus_prjna72135
      Nippostrongylus_brasiliensis_prjeb511
      Oesophagostomum_dentatum_prjna72579
      Onchocerca_flexuosa_prjeb512
      Onchocerca_ochengi_prjeb1204
      Onchocerca_ochengi_prjeb1809
      Onchocerca_volvulus_prjeb513
      Opisthorchis_viverrini_prjna222628
      Panagrellus_redivivus_prjna186477
      Parascaris_equorum_prjeb514
      Parastrongyloides_trichosuri_prjeb515
      Pristionchus_exspectatus_prjeb6009
      Pristionchus_pacificus_prjna12644
      Protopolystoma_xenopodis_prjeb1201
      Rhabditophanes_kr3021_prjeb1297
      Romanomermis_culicivorax_prjeb1358
      Schistocephalus_solidus_prjeb527
      Schistosoma_curassoni_prjeb519
      Schistosoma_haematobium_prjna78265
      Schistosoma_japonicum_prjea34885
      Schistosoma_mansoni_prjea36577
      Schistosoma_margrebowiei_prjeb522
      Schistosoma_mattheei_prjeb523
      Schistosoma_rodhaini_prjeb526
      Schmidtea_mediterranea_prjna12585
      Soboliphyme_baturini_prjeb516
      Spirometra_erinaceieuropaei_prjeb1202
      Steinernema_carpocapsae_prjna202318
      Steinernema_feltiae_prjna204661
      Steinernema_glaseri_prjna204943
      Steinernema_monticolum_prjna205067
      Steinernema_scapterisci_prjna204942
      Strongyloides_papillosus_prjeb525
      Strongyloides_ratti_prjeb125
      Strongyloides_stercoralis_prjeb528
      Strongyloides_venezuelensis_prjeb530
      Strongylus_vulgaris_prjeb531
      Syphacia_muris_prjeb524
      Taenia_asiatica_prjeb532
      Taenia_asiatica_prjna299871
      Taenia_saginata_prjna71493
      Taenia_solium_prjna170813
      Teladorsagia_circumcincta_prjna72569
      Thelazia_callipaeda_prjeb1205
      Toxocara_canis_prjeb533
      Toxocara_canis_prjna248777
      Trichinella_britovi_prjna257433
      Trichinella_murrelli_prjna257433
      Trichinella_nativa_prjna179527
      Trichinella_nativa_prjna257433
      Trichinella_nelsoni_prjna257433
      Trichinella_papuae_prjna257433
      Trichinella_patagoniensis_prjna257433
      Trichinella_pseudospiralis_iss13prjna257433
      Trichinella_pseudospiralis_iss141prjna257433
      Trichinella_pseudospiralis_iss176prjna257433
      Trichinella_pseudospiralis_iss470prjna257433
      Trichinella_pseudospiralis_iss588prjna257433
      Trichinella_spiralis_prjna12603
      Trichinella_spiralis_prjna257433
      Trichinella_t6_prjna257433
      Trichinella_t8_prjna257433
      Trichinella_t9_prjna257433
      Trichinella_zimbabwensis_prjna257433
      Trichobilharzia_regenti_prjeb4662
      Trichuris_muris_prjeb126
      Trichuris_suis_prjna179528
      Trichuris_suis_prjna208415
      Trichuris_suis_prjna208416
      Trichuris_trichiura_prjeb535
      Wuchereria_bancrofti_prjeb536  
      Wuchereria_bancrofti_prjna275548
    )];

    ### Perl Configuration    
    @SiteDefs::ENSEMBL_PERL_DIRS    = (
      $SiteDefs::ENSEMBL_WEBROOT.'/perl',
      $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
      $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/perl',
    );
    
    
}

1;
