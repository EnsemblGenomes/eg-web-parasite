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
    $SiteDefs::SITE_RELEASE_VERSION = '16';
    $SiteDefs::WORMBASE_RELEASE_VERSION = '279';
    $SiteDefs::SITE_RELEASE_DATE = 'October 2021';
    $SiteDefs::EG_RELEASE_VERSION = 48;
 
    ### Website Configuration
    $SiteDefs::SITE_NAME = 'WormBase ParaSite';
    $SiteDefs::ENSEMBL_SITETYPE = 'WormBase ParaSite';
    $SiteDefs::EG_DIVISION = 'parasite';
    $SiteDefs::DIVISION = 'parasite';
    $SiteDefs::GENOMIC_UNIT = 'parasite';
    $SiteDefs::ENSEMBL_PORT = 8032;
    $SiteDefs::ENSEMBL_SERVERNAME = 'parasite.wormbase.org';
    $SiteDefs::SITE_FTP= 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/parasite';
    
    $SiteDefs::ENSEMBL_PRIMARY_SPECIES = 'Romanomermis_culicivorax_prjeb1358';

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
    $SiteDefs::ENSEMBL_MART_ENABLED      = 1;
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
    $SiteDefs::GXA_REST_URL            = 'https://www.ebi.ac.uk/gxa/json/expressionData?geneId=';
    $SiteDefs::GXA_EBI_URL             = 'https://www.ebi.ac.uk/gxa/resources';
    $SiteDefs::EVA_URL                 = 'https://www.ebi.ac.uk/eva';
    $SiteDefs::ENA_URL                 = 'https://www.ebi.ac.uk/ena';
      
    ## GDPR config
    $SiteDefs::GDPR_VERSION            = '2.0.0';
    $SiteDefs::GDPR_COOKIE_NAME        = 'wbps-policy';
    $SiteDefs::GDPR_POLICY_URL         = 'https://www.ebi.ac.uk/data-protection/privacy-notice/wbparasite-website-browsing';
    $SiteDefs::GDPR_ACCOUNT_URL        = 'https://www.ebi.ac.uk/data-protection/privacy-notice/wbparasite-website-accounts';


    # Comment config
    $SiteDefs::COMMENT_ADMIN_GROUP            = '1';
    $SiteDefs::PARASITE_COMMENT_ENABLED       = 1;

    #Number of seconds that data should be fetched again.
    $SiteDefs::BLOG_REFRESH_RATE = 10800;
    $SiteDefs::SPECIESPAGE_REFRESH_RATE = 86400000;

    ### Species Configuration
    $SiteDefs::PRODUCTION_NAMES = [sort qw(
         acanthocheilonema_viteae_prjeb1697
         acrobeloides_nanus_prjeb26554
         ancylostoma_caninum_prjna72585
         ancylostoma_ceylanicum_prjna231479
         ancylostoma_ceylanicum_prjna72583
         ancylostoma_duodenale_prjna72581
         angiostrongylus_cantonensis_prjeb493
         angiostrongylus_cantonensis_prjna350391
         angiostrongylus_costaricensis_prjeb494
         anisakis_simplex_prjeb496
         ascaris_lumbricoides_prjeb4950
         ascaris_suum_prjna62057
         ascaris_suum_prjna80881
         atriophallophorus_winterbourni_prjna636673
         brugia_malayi_prjna10729
         brugia_pahangi_prjeb497
         brugia_timori_prjeb4663
         bursaphelenchus_okinawaensis_prjeb40023
         bursaphelenchus_xylophilus_prjea64437
         bursaphelenchus_xylophilus_prjeb40022
         caenorhabditis_angaria_prjna51225
         caenorhabditis_becei_prjeb28243
         caenorhabditis_bovis_prjeb34497
         caenorhabditis_brenneri_prjna20035
         caenorhabditis_briggsae_prjna10731
         caenorhabditis_elegans_prjna13758
         caenorhabditis_inopinata_prjdb5687
         caenorhabditis_japonica_prjna12591
         caenorhabditis_latens_prjna248912
         caenorhabditis_nigoni_prjna384657
         caenorhabditis_panamensis_prjeb28259
         caenorhabditis_parvicauda_prjeb12595
         caenorhabditis_quiockensis_prjeb11354
         caenorhabditis_remanei_prjna248909
         caenorhabditis_remanei_prjna248911
         caenorhabditis_remanei_prjna53967
         caenorhabditis_remanei_prjna577507
         caenorhabditis_sinica_prjna194557
         caenorhabditis_sulstoni_prjeb12601
         caenorhabditis_tribulationis_prjeb12608
         caenorhabditis_tropicalis_prjna53597
         caenorhabditis_uteleia_prjeb12600
         caenorhabditis_waitukubuli_prjeb12602
         caenorhabditis_zanzibari_prjeb12596
         clonorchis_sinensis_prjda72781
         clonorchis_sinensis_prjna386618
         cylicostephanus_goldi_prjeb498
         dibothriocephalus_latus_prjeb1206
         dictyocaulus_viviparus_prjeb5116
         dictyocaulus_viviparus_prjna72587
         diploscapter_coronatus_prjdb3143
         diploscapter_pachys_prjna280107
         dirofilaria_immitis_prjeb1797
         ditylenchus_destructor_prjna312427
         ditylenchus_dipsaci_prjna498219
         dracunculus_medinensis_prjeb500
         echinococcus_canadensis_prjeb8992
         echinococcus_granulosus_prjeb121
         echinococcus_granulosus_prjna182977
         echinococcus_multilocularis_prjeb122
         echinococcus_oligarthrus_prjeb31222
         echinostoma_caproni_prjeb1207
         elaeophora_elaphi_prjeb502
         enterobius_vermicularis_prjeb503
         fasciola_gigantica_prjna230515
         fasciola_hepatica_prjeb25283
         fasciola_hepatica_prjna179522
         globodera_pallida_prjeb123
         globodera_rostochiensis_prjeb13504
         gongylonema_pulchrum_prjeb505
         gyrodactylus_salaris_prjna244375
         haemonchus_contortus_prjeb506
         haemonchus_contortus_prjna205202
         haemonchus_placei_prjeb509
         halicephalobus_mephisto_prjna528747
         heligmosomoides_polygyrus_prjeb1203
         heligmosomoides_polygyrus_prjeb15396
         heterodera_glycines_prjna381081
         heterorhabditis_bacteriophora_prjna13977
         hydatigera_taeniaeformis_prjeb534
         hymenolepis_diminuta_prjeb30942
         hymenolepis_diminuta_prjeb507
         hymenolepis_microstoma_prjeb124
         hymenolepis_nana_prjeb508
         litomosoides_sigmodontis_prjeb3075
         loa_loa_prjna246086
         loa_loa_prjna37757
         macrostomum_lignano_prjna284736
         macrostomum_lignano_prjna371498
         meloidogyne_arenaria_prjeb8714
         meloidogyne_arenaria_prjna340324
         meloidogyne_arenaria_prjna438575
         meloidogyne_enterolobii_prjna340324
         meloidogyne_floridensis_prjeb6016
         meloidogyne_floridensis_prjna340324
         meloidogyne_graminicola_prjna411966
         meloidogyne_hapla_prjna29083
         meloidogyne_incognita_prjeb8714
         meloidogyne_incognita_prjna340324
         meloidogyne_javanica_prjeb8714
         meloidogyne_javanica_prjna340324
         mesocestoides_corti_prjeb510
         mesorhabditis_belari_prjeb30104
         micoletzkya_japonica_prjeb27334
         necator_americanus_prjna72135
         nippostrongylus_brasiliensis_prjeb511
         oesophagostomum_dentatum_prjna72579
         onchocerca_flexuosa_prjeb512
         onchocerca_flexuosa_prjna230512
         onchocerca_ochengi_prjeb1204
         onchocerca_ochengi_prjeb1465
         onchocerca_volvulus_prjeb513
         opisthorchis_felineus_prjna413383
         opisthorchis_viverrini_prjna222628
         oscheius_tipulae_prjeb15512
         oscheius_tipulae_prjna644888
         panagrellus_redivivus_prjna186477
         panagrolaimus_davidi_prjeb32708
         panagrolaimus_es5_prjeb32708
         panagrolaimus_ps1159_prjeb32708
         panagrolaimus_superbus_prjeb32708
         paragonimus_westermani_prjna454344
         parapristionchus_giblindavisi_prjeb27334
         parascaris_equorum_prjeb514
         parascaris_univalens_prjna386823
         parastrongyloides_trichosuri_prjeb515
         plectus_sambesii_prjna390260
         pristionchus_arcanus_prjeb27334
         pristionchus_entomophagus_prjeb27334
         pristionchus_exspectatus_prjeb24288
         pristionchus_fissidentatus_prjeb27334
         pristionchus_japonicus_prjeb27334
         pristionchus_maxplancki_prjeb27334
         pristionchus_mayeri_prjeb27334
         pristionchus_pacificus_prjna12644
         propanagrolaimus_ju765_prjeb32708
         protopolystoma_xenopodis_prjeb1201
         rhabditophanes_kr3021_prjeb1297
         romanomermis_culicivorax_prjeb1358
         schistocephalus_solidus_prjeb527
         schistosoma_bovis_prjna451066
         schistosoma_curassoni_prjeb519
         schistosoma_haematobium_prjna78265
         schistosoma_japonicum_prjea34885
         schistosoma_japonicum_prjna520774
         schistosoma_mansoni_prjea36577
         schistosoma_margrebowiei_prjeb522
         schistosoma_mattheei_prjeb523
         schistosoma_rodhaini_prjeb526
         schmidtea_mediterranea_prjna12585
         schmidtea_mediterranea_prjna379262
         setaria_digitata_prjna479729
         soboliphyme_baturini_prjeb516
         spirometra_erinaceieuropaei_prjeb1202
         steinernema_carpocapsae_prjna202318
         steinernema_carpocapsae_v1prjna202318
         steinernema_feltiae_prjna204661
         steinernema_feltiae_prjna353610
         steinernema_glaseri_prjna204943
         steinernema_monticolum_prjna205067
         steinernema_scapterisci_prjna204942
         strongyloides_papillosus_prjeb525
         strongyloides_ratti_prjeb125
         strongyloides_stercoralis_prjeb528
         strongyloides_venezuelensis_prjeb530
         strongylus_vulgaris_prjeb531
         syphacia_muris_prjeb524
         taenia_asiatica_prjeb532
         taenia_asiatica_prjna299871
         taenia_multiceps_prjna307624
         taenia_saginata_prjna71493
         taenia_solium_prjna170813
         teladorsagia_circumcincta_prjna72569
         thelazia_callipaeda_prjeb1205
         toxocara_canis_prjeb533
         toxocara_canis_prjna248777
         trichinella_britovi_prjna257433
         trichinella_murrelli_prjna257433
         trichinella_nativa_prjna179527
         trichinella_nativa_prjna257433
         trichinella_nelsoni_prjna257433
         trichinella_papuae_prjna257433
         trichinella_patagoniensis_prjna257433
         trichinella_pseudospiralis_iss13prjna257433
         trichinella_pseudospiralis_iss141prjna257433
         trichinella_pseudospiralis_iss176prjna257433
         trichinella_pseudospiralis_iss470prjna257433
         trichinella_pseudospiralis_iss588prjna257433
         trichinella_spiralis_prjna12603
         trichinella_spiralis_prjna257433
         trichinella_t6_prjna257433
         trichinella_t8_prjna257433
         trichinella_t9_prjna257433
         trichinella_zimbabwensis_prjna257433
         trichobilharzia_regenti_prjeb4662
         trichuris_muris_prjeb126
         trichuris_suis_prjna179528
         trichuris_suis_prjna208415
         trichuris_suis_prjna208416
         trichuris_trichiura_prjeb535
         wuchereria_bancrofti_prjeb536
         wuchereria_bancrofti_prjna275548
    )];


    ### Perl Configuration    
    @SiteDefs::ENSEMBL_PERL_DIRS    = (
      $SiteDefs::ENSEMBL_WEBROOT.'/perl',
      $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
      $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-parasite/perl',
    );
    
}

1;
