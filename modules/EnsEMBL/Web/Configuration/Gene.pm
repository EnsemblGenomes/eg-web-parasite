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

package EnsEMBL::Web::Configuration::Gene;

use previous qw(modify_tree);
use ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta;
use utf8;
use Data::Dumper;

sub modify_tree {
  my $self = shift;
  $self->PREV::modify_tree(@_);
  my $species_defs = $self->hub->species_defs;

  my $compara_menu = $self->get_node('Compara');
  $compara_menu->set('caption', "Comparative genomics");
  $compara_menu->set('availability', 0);
  $compara_menu->set('components', []);

  $self->delete_node('Family');
  $self->delete_node('Gene_families');
  $self->delete_node('PanCompara');
  $self->delete_node('Alleles');
  $self->delete_node('Evidence');
  $self->delete_node('SecondaryStructure');
  $self->delete_node('Regulation');
  $self->delete_node('Expression');
  $self->delete_node('Compara_Alignments');
  $self->delete_node('SpeciesTree');
  $self->delete_node('Variation');
  $self->delete_node('StructuralVariation_Gene');
  $self->delete_node('ExternalData');
  $self->delete_node('UserAnnotation');
  $self->delete_node('ExpressionAtlas');
  $self->delete_node('Pathway');

  # if($self->hub->species_defs->GXA) {
  #   my $transcriptomic_menu = $self->create_node('ExpressionAtlas', 'Expression', 
  #     [qw( atlas EnsEMBL::Web::Component::Gene::ExpressionAtlas )],
  #     { 'availability'  => 'gene has_gxa', 'hide_if_unavailable' => 1 }
  #   );
  # }

  ## ParaSite: update the Phenotype node with a customized concise
  my $gene_id = $self->hub->param('g');
  my $phenotype = $self->get_node('Phenotype');
  $phenotype->set('concise',  'Phenotypes associated with this gene ' . $gene_id);
  ##

  my $comparison = $self->get_node('TranscriptComparison');
  $comparison->set('hide_if_unavailable', 1);
 
  if($self->hub->species_defs->EVA_TRACKS) {
    my $variation = $self->create_node('EVA', 'Variation', [],
      { availability => 0 }
    );
    $variation->append(
      $self->create_node('EVA_Table', 'Variation Table',
        [qw(eva_table EnsEMBL::Web::Component::Gene::EVA_Table)]
      )
    );
    $variation->append(
      $self->create_node('EVA_Image', 'Variation Image',
        [qw(eva_image EnsEMBL::Web::Component::Gene::EVA_Image)]
      )
    );
  }

  my $summary = $self->get_node('Summary');
  $summary->set('concise', 'Genomic Context');
  $summary->set('components',
    [qw(
      gene_summary  EnsEMBL::Web::Component::Gene::GeneSummary
      wormbase      EnsEMBL::Web::Component::WormBaseLink
      navbar        EnsEMBL::Web::Component::ViewNav
      transcripts   EnsEMBL::Web::Component::Gene::TranscriptsImage
    )]
  );

  if ($SiteDefs::PARASITE_COMMENT_ENABLED) {
    my $comment_count = ORM::EnsEMBL::DB::Accounts::Manager::CommentMeta->get_comment_count_by_geneid($self->hub->param('g'));
    my $comment_txt  = sprintf ("User Comments (%s)", $comment_count);
    my $comment_section = $self->create_node('Comment', $comment_txt, 
        [qw(gene_comment EnsEMBL::Web::Component::Gene::Comment )],
        { 'availability'  => 1}
      );
    $summary->append($comment_section);
  }

  ## Parasite: Adding WBPS Gene Expression Menu. Default means Other
  my $expression_menu =  $self->create_node('WBPSExpression', 'Expression', 
        [qw(exp_menu EnsEMBL::Web::Component::Gene::WBPSExpression )],
        { 'availability' => 0 }
      );

  if ($species_defs->GENE_EXPRESSION) {
    my @exp_catgories  = @{$species_defs->GENE_EXPRESSION->{'EXP_CATEGORIES'} || []};

    #If there is data only in one category and category is "Other" (common special case for species with not so good data)
    if (scalar(@exp_catgories) == 1 and $exp_catgories[0] eq 'Other') {
        $self->delete_node('WBPSExpression');
        $self->create_node('WBPSExpressionOther', 'Expression', 
          [qw(exp_menu EnsEMBL::Web::Component::Gene::WBPSExpression )],
          { 'availability' => 1, 'concise' => 'Gene Expression: Other' }
        );
    } elsif (scalar(@exp_catgories) >= 1) {
        foreach my $cat (@exp_catgories) {
          my $cat_name = $cat =~ s/_/ /gr;
          $expression_menu->append(
          $self->create_node('WBPSExpression'.$cat, $cat_name, 
            [qw(exp_menu EnsEMBL::Web::Component::Gene::WBPSExpression )],
            { 'availability' => 1, 'concise' => "Gene Expression: $cat_name" }
          )
        );
      }
    }
  }
  ##
 
  my $ontology_menu = $self->get_node('Ontologies');
  $ontology_menu->set('caption', "Gene Ontology");
  $ontology_menu->set('components', undef);

## ParaSite: code from ensembl-webcode to create ontology sub-menus; modified to remove prefix
  my %olist   = map {$_ => 1} @{$species_defs->SPECIES_ONTOLOGIES || []};
  if (%olist) {
    my %clusters = $species_defs->multiX('ONTOLOGIES');
    my @clist = grep {$olist{$clusters{$_}->{db}}} sort {$clusters{$a}->{db} cmp $clusters{$b}->{db}} keys %clusters;    # Find if this ontology has been loaded into ontology db
    foreach my $oid (@clist) {
      my $cluster = $clusters{$oid};
      (my $desc2 = ucfirst($cluster->{description})) =~ s/_/ /g;
      $ontology_menu->append($self->create_node('Ontologies/'. $cluster->{description}, $desc2, [qw( go EnsEMBL::Web::Component::Gene::Go )], {'availability' => "gene has_go_$oid", 'concise' => $desc2 }));
    }
  }
##
 
}

1;
