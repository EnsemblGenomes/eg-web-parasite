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

package EnsEMBL::Web::Document::Element::Meta;

sub init {
  my $self = shift;
  $self->add('description', 'WormBase ParaSite is an open access resource providing genome sequences, genome browsers, semi-automatic annotation and comparative genomics analysis for nematode and platyhelminth parasites.');
  $self->add('keywords', 'WormBase, WormBase ParaSite, parasitic worms, parasitic nematodes, platyhelminthes, platyhelminth, comparative genomics, parasite genomics, parasite biology, parasite genome sequences, genome, genome browser, variation, SNPs, EST, mRNA, rna-Seq, orthologs, paralogs, synteny, assembly, genes, transcripts, translations, proteins, worms, brugia, onchocerca, pristionchus, ascaris, trichinella, wolbachia, invertebrate');
  $self->add('google-site-verification', '11sSQcxg_gkbzE1Sdwn5XimeSC3lXZDbLUQBn3T_Opc');

  ## ParaSite: Create a Twitter card
  my $hub = $self->hub;
  my $g = $hub->param('g');
  my $title = $g ? "Gene $g" : "WormBase ParaSite";
  my $description = $g ? "Get more information about $g at WormBase ParaSite" : "Browse helminth genomes at WormBase ParaSite";
  $self->add('twitter:card', 'summary');
  $self->add('twitter:site', '@WBParaSite');
  $self->add('twitter:title', $title);
  $self->add('twitter:description', $description);
  $self->add('twitter:image', 'http://parasite.wormbase.org/apple-touch-icon.png');
  ## ParaSite
}

1;
