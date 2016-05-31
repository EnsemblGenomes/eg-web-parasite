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

package EnsEMBL::Web::Component::Tools::Blast::AlignmentProtein;

use strict;

use parent qw(EnsEMBL::Web::Component::Tools::Blast::Alignment);

sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $job         = $self->job;
  my $hit         = $self->hit;
  my $source_type = $job->job_data->{'source'};
  my $sequence    = [];
  my (@markup, $object);
  
  $config->{'length'}        = $hit->{'len'}; 
  $config->{'Subject_start'} = $hit->{'tstart'};
  $config->{'Subject_end'}   = $hit->{'tend'};
  $config->{'Subject_ori'}   = $hit->{'tori'}; 
  $config->{'Query_start'}   = $hit->{'qstart'};
  $config->{'Query_end'}     = $hit->{'qend'};
  
  if ($self->blast_method eq 'TBLASTN') {
    $config->{'Subject_start'} = $hit->{'gori'} == 1 ? $hit->{'gstart'} : $hit->{'gend'};
    $config->{'Subject_end'}   = $hit->{'gori'} == 1 ? $hit->{'gend'}   : $hit->{'gstart'};
    $config->{'Subject_ori'}   = $hit->{'gori'};
  }
  
  if ($source_type !~ /latestgp/i) { # Can't markup based on protein sequence as we only have a translated DNA region
## ParaSite: use the hit species, instead of the job species
    my $adaptor    = $self->hub->get_adaptor(sprintf('get_%sAdaptor', $source_type =~ /abinitio/i ? 'PredictionTranscript' : 'Translation'), 'core', $hit->{'species'});
##
    my $transcript = $adaptor->fetch_by_stable_id($hit->{'tid'});
       $transcript = $transcript->transcript unless $transcript->isa('Bio::EnsEMBL::Transcript');
       $object     = $self->new_object('Transcript', $transcript, $self->object->__data);
  }
  
  foreach my $slice (@$slices) {
    my $seq = uc($slice->{'seq'} || $slice->{'slice'}->seq(1));
    my $mk  = {};
    
    $self->set_sequence($config, $sequence, $mk, $seq, $slice->{'name'});
    
    unless ($slice->{'no_markup'} || $source_type =~ /latestgp/i) {
      $self->set_exons($config, $slice, $mk, $object, $seq)      if $config->{'exon_display'};
      $self->set_variations($config, $slice, $mk, $object, $seq) if $config->{'snp_display'};
    }
    
    push @markup, $mk;
  }

  return ($sequence, \@markup);
}

1;
