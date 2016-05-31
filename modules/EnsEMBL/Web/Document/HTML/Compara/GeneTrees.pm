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

package EnsEMBL::Web::Document::HTML::Compara::GeneTrees;

sub get_html_for_gene_tree_coverage {
  my ($self, $name, $species, $method, $counter_raphael_holders) = @_;

  $name =~ s/ /_/g;
  my $table = EnsEMBL::Web::Document::Table->new([
      { key => 'species',                         width => '18%', align => 'left',   sort => 'string',  title => 'Species', },
      { key => 'nb_genes',                        width => '6%',  align => 'center', sort => 'numeric', style => 'color: #ca4', title => '# Genes', },
      { key => 'nb_seq',                          width => '9%',  align => 'center', sort => 'numeric', title => '# Sequences', },
      { key => 'nb_genes_in_tree',                width => '10%', align => 'center', sort => 'numeric', title => '# Genes in a tree', },
      { key => 'nb_orphan_genes',                 width => '9%',  align => 'center', sort => 'numeric', style => 'color: #a22', title => '# Orphaned genes', },
      { key => 'nb_genes_in_tree_single_species', width => '10%', align => 'center', sort => 'numeric', style => 'color: #25a', title => "# Genes in a single-species tree", },
      { key => 'nb_genes_in_tree_multi_species',  width => '10%', align => 'center', sort => 'numeric', style => 'color: #8a2', title => '# Genes in a multi-species tree', },
      { key => 'piechart_cov',                    width => '4%',  align => 'center', sort => 'none',    title => 'Coverage', },
      { key => 'nb_dup_nodes',                    width => '10%', align => 'center', sort => 'numeric', style => 'color:#909', title => '# species-specific duplications', },
    ], [], {data_table => 1, id => sprintf('gene_tree_coverage_%s', $name), sorting => ['species asc']});
  $table->add_columns(
    { key => 'nb_gene_splits',                  width => '9%', align => 'center', sort => 'numeric', style => 'color:#69f', title => '# Gene splits', },
  ) if $method eq 'PROTEIN_TREES';
  $table->add_columns(
    { key => 'piechart_dup',                      width => '5%',  align => 'center', sort => 'none',    title => 'Gene events', },
  );

  my $common_names = $self->hub->species_defs->multi_hash->{'DATABASE_COMPARA'}{'TAXON_NAME'};

  foreach my $sp (@$species) {
## ParaSite: add BioProject
    next unless defined $sp;
    my $sp_name = $sp->genome_db->name;
    my $bioproject = $self->hub->species_defs->get_config(ucfirst $sp_name, 'SPECIES_BIOPROJECT');
##
    my $piecharts = $self->get_piecharts_for_species($sp, $counter_raphael_holders);
    $table->add_row({
## ParaSite: add BioProject
        'species' => $bioproject ? sprintf('<i>%s</i> (%s)', $sp->node_name, $bioproject) : $sp->node_name,
##
        'piechart_cov' => $piecharts->[1],
        'piechart_dup' => $sp->get_value_for_tag('nb_genes_in_tree') ? $piecharts->[0] : '',
        map {($_ => $sp->get_value_for_tag($_) || 0)} (qw(nb_genes nb_seq nb_orphan_genes nb_genes_in_tree nb_genes_in_tree_single_species nb_genes_in_tree_multi_species nb_gene_splits nb_dup_nodes)),
      });
  }
  return $table->render;
}

sub draw_tree {
  my ($self, $matrix, $node, $next_y, $counter_raphael_holders) = @_;
  my $nchildren = scalar(@{$node->children});

  my $common_names  = $self->hub->species_defs->multi_hash->{'DATABASE_COMPARA'}{'TAXON_NAME'};

## ParaSite: add the BioProject
  if($node->genome_db) {
    my $sp_name = $node->genome_db->name;
    my $bioproject = $self->hub->species_defs->get_config(ucfirst $sp_name, 'SPECIES_BIOPROJECT');
    $node->node_name(sprintf('%s (%s)', $node->node_name, $bioproject)) if $bioproject;
  }
##

  my $horiz_branch  = q{<img style="width: 28px; height: 28px;" alt="---" src="ct_hor.png" />};
  my $vert_branch   = q{<img style="width: 28px; height: 28px;" alt="---" src="ct_ver.png" />};
  my $top_branch    = q{<img style="width: 28px; height: 28px;" alt="---" src="ct_top.png" />};
  my $bottom_branch = q{<img style="width: 28px; height: 28px;" alt="---" src="ct_bot.png" />};
  my $middle_branch = q{<img style="width: 28px; height: 28px;" alt="---" src="ct_mid.png" />};
  my $half_horiz_branch  = q{<img style="width: 14px; height: 28px;" alt="-" src="ct_half_hor.png" />};

  if ($nchildren) {
    my @subtrees = map {$self->draw_tree($matrix, $_, $next_y, $counter_raphael_holders)} @{$node->sorted_children};
    my $anchor_x_pos = min(map {$_->[0]} @subtrees)-1;
    my $min_y = min(map {$_->[1]} @subtrees);
    my $max_y = max(map {$_->[1]} @subtrees);
    my $anchor_y_pos = int(($min_y+$max_y)/2);
    foreach my $coord (@subtrees) {
      $matrix->[$coord->[1]]->[$_] = ($_ % 2 ? $horiz_branch : $half_horiz_branch) for ($anchor_x_pos+1)..($coord->[0]-1);
    }
    my $piecharts = $self->get_piecharts_for_internal_node($node, $counter_raphael_holders);
    $matrix->[$_]->[$anchor_x_pos] = $vert_branch for ($min_y+1)..($max_y-1);
    $matrix->[$_->[1]]->[$anchor_x_pos] = $middle_branch for @subtrees;
    $matrix->[$min_y]->[$anchor_x_pos] = $top_branch;
    $matrix->[$max_y]->[$anchor_x_pos] = $bottom_branch;
    $matrix->[$anchor_y_pos]->[$anchor_x_pos] = $piecharts->[0];
    $matrix->[$anchor_y_pos]->[$anchor_x_pos-1] = $half_horiz_branch;

    return [$anchor_x_pos-1, $anchor_y_pos];

  } else {
    my $y = $$next_y;
    $$next_y++;
    my $width = scalar(@{$matrix->[$y]});
    my $piecharts = $self->get_piecharts_for_species($node, $counter_raphael_holders);
    $matrix->[$y]->[$width-1] = $common_names->{$node->taxon_id} || $node->node_name;
    $matrix->[$y]->[$width-1] = $common_names->{$node->taxon_id} || $node->node_name;
    $matrix->[$y]->[$width-2] = $piecharts->[1];
    $matrix->[$y]->[$width-3] = $piecharts->[0];
    $matrix->[$y]->[$width-4] = $half_horiz_branch;
    return [$width-4, $y];
  }

}

1;

