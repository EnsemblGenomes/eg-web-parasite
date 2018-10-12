package EnsEMBL::Web::Component::Gene::HistoryReport;

use strict;
use warnings;

sub content {

  my $self    = shift; 
  my $protein = shift; 
  my $hub     = $self->hub;
  my $object  = $self->object;   
  my $archive_object;
  
  if ($protein == 1) {
    my $transcript = $object->transcript;
    my $translation_object;
    
    if ($transcript->isa('Bio::EnsEMBL::ArchiveStableId') || $transcript->isa('EnsEMBL::Web::Fake') ){ 
       my $p = $hub->param('p') || $hub->param('protein');
       
       if (!$p) {                                                                 
         my $p_archive = shift @{$transcript->get_all_translation_archive_ids};
         $p = $p_archive->stable_id;
       }
       my $db          = $hub->param('db') || 'core';
       my $db_adaptor  = $hub->database($db);
       my $a           = $db_adaptor->get_ArchiveStableIdAdaptor;
       $archive_object = $a->fetch_by_stable_id($p);
    } else { 
       $translation_object = $object->translation_object;
       $archive_object     = $translation_object->get_archive_object;
    }
  } else {  # retrieve archive object 
    $archive_object = $object->get_archive_object; 
  }
  
  return unless $archive_object;
  
  my $latest        = $archive_object->get_latest_incarnation;
  my $id            = $latest->stable_id;
  my $version_html  = [];
  my $status;

  my $release_info = 'Release: ' . $latest->release . ($archive_object->is_current ? ' (current)' : '');
  
  if ($archive_object->is_current) {
    $status = 'Current'; # this *is* the current version of this stable ID
  } elsif ($archive_object->current_version) {
    $status = 'Old version'; # there is a current version of this stable ID
  } else {
    $status = 'Retired (see below for possible successors)'; # this stable ID no longer exists
    my ($spe,$cies,$bp, $__, $parasite_version) = split "_", $archive_object->db_name;
    $bp = uc($bp);
    my $archive_link = join "/", $SiteDefs::SITE_FTP, 'releases', "WBPS$parasite_version", "species", "${spe}_${cies}" , $bp;
    $release_info .= sprintf(' (<a href="%s">FTP Link</a>)', $archive_link);
  }

  push @$version_html, $release_info, 'Assembly: ' . $latest->assembly, 'Database: ' . $latest->db_name;
  return $self->new_twocol(['Stable ID', $id], ['Status', $status], ['Latest Version', join('', map sprintf('<p>%s</p>', $_), @$version_html)])->render;
  
}

1;
