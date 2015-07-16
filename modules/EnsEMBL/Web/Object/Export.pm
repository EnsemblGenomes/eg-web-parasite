=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Export;

use strict;

sub fasta {
  my ($self, $trans_objects) = @_;

  my $hub             = $self->hub;
  my $object          = $self->get_object;
  my $object_id       = ($hub->function eq 'Gene' || $hub->function eq 'LRG') ? $object->stable_id : '';
  my $slice           = $object->slice('expand');
  $slice              = $self->slice if($slice == 1);
  my $strand          = $hub->param('strand');
  if(($strand ne 1) && ($strand ne -1)) {$strand = $slice->strand;}
  if($strand != $slice->strand){ $slice=$slice->invert; }
  my $params          = $self->params;
  my $genomic         = $hub->param('genomic');
  my $seq_region_name = $object->seq_region_name;
  my $seq_region_type = $object->seq_region_type;
  my $slice_name      = $slice->name;
  my $slice_length    = $slice->length;
  my $fasta;
  if (scalar keys %$params) {
    my $intron_id;
    
    my $output = {
      cdna    => sub { my ($t, $id, $type) = @_; [[ "$id cdna:$type", $t->spliced_seq ]] },
      coding  => sub { my ($t, $id, $type) = @_; [[ "$id cds:$type", $t->translateable_seq ]] },
      peptide => sub { my ($t, $id, $type) = @_; eval { [[ "$id peptide: " . $t->translation->stable_id . " pep:$type", $t->translate->seq ]] }},
      utr3    => sub { my ($t, $id, $type) = @_; eval { [[ "$id utr3:$type", $t->three_prime_utr->seq ]] }},
      utr5    => sub { my ($t, $id, $type) = @_; eval { [[ "$id utr5:$type", $t->five_prime_utr->seq ]] }},
      exon    => sub { my ($t, $id, $type) = @_; eval { [ map {[ "$id " . $_->id . " exon:$type", $_->seq->seq ]} @{$t->get_all_Exons} ] }},
      intron  => sub { my ($t, $id, $type) = @_; eval { [ map {[ "$id intron " . $intron_id++ . ":$type", $_->seq ]} @{$t->get_all_Introns} ] }}
    };
    
    foreach (@$trans_objects) {
      my $transcript = $_->Obj;
      my $id         = ($object_id ? "$object_id:" : '') . $transcript->stable_id;
      my $type       = $transcript->biotype;
      
      $intron_id = 1;
      
      foreach (sort keys %$params) {      
        my $o = $output->{$_}($transcript, $id, $type) if exists $output->{$_};
        
        next unless ref $o eq 'ARRAY';
        
        foreach (@$o) {
          $self->string(">$_->[0]");
          $self->string($fasta) while $fasta = substr $_->[1], 0, 60, '';
        }
      }
      
      $self->string('');
    }
  }

  if (defined $genomic && $genomic ne 'off') {
    my $masking = $genomic eq 'soft_masked' ? 1 : $genomic eq 'hard_masked' ? 0 : undef;
    my ($seq, $start, $end, $flank_slice);

    if ($genomic =~ /flanking/) {      
      for (5, 3) {
        if ($genomic =~ /$_/) {
          if ($strand == $params->{'feature_strand'}) {
            ($start, $end) = $_ == 3 ? ($slice_length - $hub->param('flank3_display') + 1, $slice_length) : (1, $hub->param('flank5_display'));
          } else {
            ($start, $end) = $_ == 5 ? ($slice_length - $hub->param('flank5_display') + 1, $slice_length) : (1, $hub->param('flank3_display'));
          }
          
          $flank_slice = $slice->sub_Slice($start, $end);
          
          if ($flank_slice) {
            $seq  = $flank_slice->seq;
            
            $self->string(">$_' Flanking sequence " . $flank_slice->name);
            $self->string($fasta) while $fasta = substr $seq, 0, 60, '';
          }
        }
      }
    } else {
      $seq = defined $masking ? $slice->get_repeatmasked_seq(undef, $masking)->seq : $slice->seq;
      $self->string(">$seq_region_name dna:$seq_region_type $slice_name");
      $self->string($fasta) while $fasta = substr $seq, 0, 60, '';
    }
  }
}
