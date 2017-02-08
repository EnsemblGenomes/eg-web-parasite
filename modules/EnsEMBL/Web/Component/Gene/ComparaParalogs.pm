=head1 LICENSE

Copyright [2014-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::ComparaParalogs;

use strict;

sub content {
  my $self           = shift;
  my $hub            = $self->hub;
  my $availability   = $self->object->availability;
  my $cdb            = shift || $hub->param('cdb') || 'compara';
  my %paralogue_list = %{$self->object->get_homology_matches('ENSEMBL_PARALOGUES', 'paralog|gene_split', 'possible_ortholog', $cdb)};
  
  return '<p>No paralogues have been identified for this gene</p>' unless keys %paralogue_list;
  
  my %paralogue_map = qw(SEED BRH PIP RHS);
  my $alignview     = 0;
  
  my $columns = [
    { key => 'Type',                align => 'left', width => '10%', sort => 'html'          },
    { key => 'Ancestral taxonomy',  align => 'left', width => '10%', sort => 'html'          },
    { key => 'identifier',          align => 'left', width => '15%', sort => 'html', title => $self->html_format ? 'Stable ID &amp; gene name' : 'Stable ID'},    
    { key => 'Compare',             align => 'left', width => '10%', sort => 'none'          },
    { key => 'Location',            align => 'left', width => '20%', sort => 'position_html' },
    { key => 'Target %id',          align => 'left', width => '5%',  sort => 'numeric'       },
    { key => 'Query %id',           align => 'left', width => '5%',  sort => 'numeric'       },
  ];
  
  my @rows;
  
  foreach my $species (sort keys %paralogue_list) {
    foreach my $stable_id (sort {$paralogue_list{$species}{$a}{'order'} <=> $paralogue_list{$species}{$b}{'order'}} keys %{$paralogue_list{$species}}) {
      my $paralogue = $paralogue_list{$species}{$stable_id};
      
      my $description = encode_entities($paralogue->{'description'});
         $description = 'No description' if $description eq 'NULL';
      
      if ($description =~ s/\[\w+:([-\w\/]+)\;\w+:(\w+)\]//g) {
        my ($edb, $acc) = ($1, $2);
        $description .= '[' . $hub->get_ExtURL_link("Source: $edb ($acc)", $edb, $acc). ']' if $acc;
      }
      
      my @external = (qq{<span class="small">$description</span>});
      if ($paralogue->{'display_id'}) {
        if ($paralogue->{'display_id'} eq 'Novel Ensembl prediction' && $description eq 'No description') {
          @external = ('<span class="small"></span>');
        } elsif ($paralogue->{'display_id'} ne 'Novel Ensembl prediction') {
          unshift @external, $paralogue->{'display_id'};
        }
      }
      my $paralogue_desc              = $paralogue_map{$paralogue->{'homology_desc'}} || $paralogue->{'homology_desc'};
      my $paralogue_subtype           = $paralogue->{'homology_subtype'}              || '&nbsp;';
      my $paralogue_dnds_ratio        = $paralogue->{'homology_dnds_ratio'}           || '&nbsp;';
      (my $spp = $paralogue->{'spp'}) =~ tr/ /_/;
      
      my $link_url = $hub->url({
        action => 'Summary',
        g => $stable_id,
        r => undef
      });
      
      my $location_link = $hub->url({
        type   => 'Location',
        action => 'View',
        r      => $paralogue->{'location'},
        g      => $stable_id
      });

      ## PARASITE
      my $domain = $hub->species_defs->ENSEMBL_SPECIES_SITE($species);
      (my $jbrowse_region = $paralogue->{'location'}) =~ s/-/../;
      my $jbrowse_url = $hub->get_ExtURL_link('<br /><span class="wb-compara-out">[View region in JBrowse]</span>', 'PARASITE_JBROWSE', {'SPECIES'=>lc($species), 'REGION'=>$jbrowse_region, 'HIGHLIGHT'=>''});
      my $wb_gene_url = $domain =~ /^wormbase$/i ? $hub->get_ExtURL_link('<br /><span class="wb-compara-out">[View gene at WormBase Central]</span>', uc "$domain\_gene", {'SPECIES'=>$species, 'ID'=>$stable_id}) : '';
      my $wb_location_url = defined($hub->species_defs->ENSEMBL_EXTERNAL_URLS->{uc("$spp\_jbrowse")}) ? $hub->get_ExtURL_link('<br /><span class="wb-compara-out">[View region in WormBase JBrowse]</span>', uc "$spp\_jbrowse", {'SPECIES'=>$species, 'REGION'=>$jbrowse_region, 'HIGHLIGHT'=>''}) : '';
      ##
      
      my $id_info = qq{<p class="space-below"><a href="$link_url">$stable_id</a>$wb_gene_url</p>} . join '<br />', @external;

      my $links = ($availability->{'has_pairwise_alignments'}) ?
        sprintf (
        '<ul class="compact"><li class="first"><a href="%s" class="notext">Region Comparison</a></li>',
        $hub->url({
          type   => 'Location',
          action => 'Multi',
          g1     => $stable_id,
          s1     => $spp,
          r      => undef,
          config => 'opt_join_genes_bottom=on',
        })
      ) : '';
      
      my ($target, $query);

      if ($paralogue_desc ne 'DWGA' && $paralogue_desc ne 'other paralogue (within species)') {          
        my $align_url = $hub->url({
            action   => 'Compara_Paralog', 
            function => "Alignment". ($cdb=~/pan/ ? '_pan_compara' : ''),, 
            g1       => $stable_id
        });
        $links .= sprintf '<li><a href="%s" class="notext">Alignment (protein)</a></li>', $align_url;
        $align_url .= ';seq=cDNA';
        $links .= sprintf '<li><a href="%s" class="notext">Alignment (cDNA)</a></li>', $align_url;
        
        ($target, $query) = ($paralogue->{'target_perc_id'}, $paralogue->{'query_perc_id'});
        $alignview = 1;
      }

      $links .= '</ul>';
      
      
      push @rows, {
        'Type'                => ucfirst $paralogue_desc,
        'Ancestral taxonomy'  => $paralogue_subtype,
        'identifier' => $self->html_format ? $id_info : $stable_id,
        'Compare'             => $self->html_format ? qq{<span class="small">$links</span>} : '',
        'Location'            => qq{<a href="$location_link">$paralogue->{'location'}</a>$jbrowse_url$wb_location_url},
        'Target %id'          => $target,
        'Query %id'           => $query,
      };
    }
  }
  
  my $table = $self->new_table($columns, \@rows, { data_table => 1 });
  my $html;
  
  if ($alignview && keys %paralogue_list) {
    $html .= sprintf(
## EG - wording change
      '<p><a href="%s">View protein alignments of all paralogues</a></p>', 
##     
      $hub->url({ action => 'Compara_Paralog', function => 'Alignment' })
    );
  }
 
  $html .= $table->render;
 
  return $html;
}

1;

