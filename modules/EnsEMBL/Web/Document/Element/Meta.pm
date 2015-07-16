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
  $self->add('description', 'WormBase ParaSite is a genome-centric sub-portal of WormBase for nematode and platyhelminth species of scientific interest');
  $self->add('keywords', 'WormBase, WormBase ParaSite, parasitic worms, parasitic nematodes, platyhelminthes, platyhelminth, comparative genomics, parasite genomics, parasite biology, parasite genome sequences, genome, genome browser, variation, SNPs, EST, mRNA, rna-Seq, orthologs, paralogs, synteny, assembly, genes, transcripts, translations, proteins, worms, brugia, onchocerca, pristionchus, ascaris, trichinella, wolbachia, invertebrate');
  $self->add('google-site-verification', '11sSQcxg_gkbzE1Sdwn5XimeSC3lXZDbLUQBn3T_Opc');
}

1;
