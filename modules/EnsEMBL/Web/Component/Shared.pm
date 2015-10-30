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

package EnsEMBL::Web::Component::Shared;

use strict;
use Bio::EnsEMBL::Gene;

sub transcript_table {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $avail       = $object->availability;
  my $species     = $hub->species;
  my $table       = $self->new_twocol;
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  my $cdb         = $hub->param('cdb') || 'compara';
  my $description = $object->gene_description;
  $description =~ s/\s*\{ECO:.*?\}//g;
     $description = '' if $description eq 'No description';
  my $show        = $hub->get_cookie_value('toggle_transcripts_table') eq 'open';
  my $button      = sprintf('<a rel="transcripts_table" class="button toggle no_img _slide_toggle set_cookie %s" href="#" title="Click to toggle the transcript table">
    <span class="closed">Show transcript table</span><span class="open">Hide transcript table</span>
    </a>',
    $show ? 'open' : 'closed'
  );
  

  if ($description) {

    my ($url, $xref) = $self->get_gene_display_link($object->gene, $description);

    if ($xref) {
      $xref        = $xref->primary_id;
      $description =~ s|$xref|<a href="$url" class="constant">$xref</a>|;
    }
    
    $table->add_row('Description', $description);
  }

  my $location    = $hub->param('r') || sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

  my $site_type         = $hub->species_defs->ENSEMBL_SITETYPE; 
  my @SYNONYM_PATTERNS  = qw(%HGNC% %ZFIN%);
  my (@syn_matches, $syns_html, $counts_summary);
  push @syn_matches,@{$object->get_database_matches($_)} for @SYNONYM_PATTERNS;

  my $gene = $page_type eq 'gene' ? $object->Obj : $object->gene;
  foreach (@{$object->get_similarity_hash(0, $gene)}) {
    next unless $_->{'type'} eq 'PRIMARY_DB_SYNONYM';
    my $id           = $_->display_id;
    my $synonym     = $self->get_synonyms($id, @syn_matches);
    next unless $synonym;
    $syns_html .= "<p>$synonym</p>";
  }

## EG
  if ($syns_html) {
      $table->add_row('Synonyms', $syns_html);
  } else { # check if synonyms are attached  via display xref .. 
      my ($display_name) = $object->display_xref;
      if (my $xref = $object->Obj->display_xref) {
        if (my $sn = $xref->get_all_synonyms) {
            my $syns = join ', ', grep { $_ && ($_ ne $display_name) } @$sn;
            if ($syns) {
              $table->add_row('Synonyms', "$syns",);
            }
        }
      }
  }
##

  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant">%s: %s-%s</a> %s.',
    $hub->url({
      type   => 'Location',
      action => 'View',
      r      => $location, 
    }),
    $self->neat_sr_name($object->seq_region_type, $seq_region_name),
    $self->thousandify($seq_region_start),
    $self->thousandify($seq_region_end),
    $object->seq_region_strand < 0 ? ' reverse strand' : 'forward strand'
  );
 
  # alternative (Vega) coordinates
  if ($object->get_db eq 'vega') {
    my $alt_assemblies  = $hub->species_defs->ALTERNATIVE_ASSEMBLIES || [];
    my ($vega_assembly) = map { $_ =~ /VEGA/; $_ } @$alt_assemblies;
    
    # set dnadb to 'vega' so that the assembly mapping is retrieved from there
    my $reg        = 'Bio::EnsEMBL::Registry';
    my $orig_group = $reg->get_DNAAdaptor($species, 'vega')->group;
    
    $reg->add_DNAAdaptor($species, 'vega', $species, 'vega');

    my $alt_slices = $object->vega_projection($vega_assembly); # project feature slice onto Vega assembly
    
    # link to Vega if there is an ungapped mapping of whole gene
    if (scalar @$alt_slices == 1 && $alt_slices->[0]->length == $object->feature_length) {
      my $l = $alt_slices->[0]->seq_region_name . ':' . $alt_slices->[0]->start . '-' . $alt_slices->[0]->end;
      
      $location_html .= ' [<span class="small">This corresponds to ';
      $location_html .= sprintf(
        '<a href="%s" target="external" class="constant">%s-%s</a>',
        $hub->ExtURL->get_url('VEGA_CONTIGVIEW', $l),
        $self->thousandify($alt_slices->[0]->start),
        $self->thousandify($alt_slices->[0]->end)
      );
      
      $location_html .= " in $vega_assembly coordinates</span>]";
    } else {
      $location_html .= sprintf qq{ [<span class="small">There is no ungapped mapping of this %s onto the $vega_assembly assembly</span>]}, lc $object->type_name;
    }
    
    $reg->add_DNAAdaptor($species, 'vega', $species, $orig_group); # set dnadb back to the original group
  }

  $location_html = "<p>$location_html</p>";

  if ($page_type eq 'gene') {
    # Haplotype/PAR locations
    my $alt_locs = $object->get_alternative_locations;

    if (@$alt_locs) {
      $location_html .= '
        <p> This gene is mapped to the following HAP/PARs:</p>
        <ul>';
      
      foreach my $loc (@$alt_locs) {
        my ($altchr, $altstart, $altend, $altseqregion) = @$loc;
        
        $location_html .= sprintf('
          <li><a href="/%s/Location/View?l=%s:%s-%s" class="constant">%s : %s-%s</a></li>', 
          $species, $altchr, $altstart, $altend, $altchr,
          $self->thousandify($altstart),
          $self->thousandify($altend)
        );
      }
      
      $location_html .= '
        </ul>';
    }
  }

  my $gene = $object->gene;

  #text for tooltips
  my $gencode_desc = "The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).";
  my $trans_5_3_desc = "5' and 3' truncations in transcript evidence prevent annotation of the start and the end of the CDS.";
  my $trans_5_desc = "5' truncation in transcript evidence prevents annotation of the start of the CDS.";
  my $trans_3_desc = "3' truncation in transcript evidence prevents annotation of the end of the CDS.";
  my %glossary     = $hub->species_defs->multiX('ENSEMBL_GLOSSARY');
  my $gene_html    = '';  
  my $transc_table;

  if ($gene) {
    my $transcript  = $page_type eq 'transcript' ? $object->stable_id : $hub->param('t');
    my $transcripts = $gene->get_all_Transcripts;
    my $count       = @$transcripts;
    my $plural      = 'transcripts';
    my $splices     = 'splice variants';
    my $action      = $hub->action;
    my %biotype_rows;

    my $trans_attribs = {};
    my $trans_gencode = {};
    my @appris_codes  = qw(appris_pi1 appris_pi2 appris_pi3 appris_pi4 appris_pi5 appris_alt1 appris_alt2);

    foreach my $trans (@$transcripts) {
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic TSL), @appris_codes) {
        (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
        next unless $attrib;
        if($attrib_type eq 'gencode_basic' && $attrib->value) {
          $trans_gencode->{$trans->stable_id}{$attrib_type} = $attrib->value;
        } elsif ($attrib_type =~ /appris/  && $attrib->value) {
          ## There should only be one APPRIS code per transcript
          (my $code = $attrib->code) =~ s/appris_//;
          $trans_attribs->{$trans->stable_id}{'appris'} = [$code, $attrib->name]; 
          last;
        } else {
          $trans_attribs->{$trans->stable_id}{$attrib_type} = $attrib->value if ($attrib && $attrib->value);
        }
      }
    }
    my %url_params = (
      type   => 'Transcript',
      action => $page_type eq 'gene' || $action eq 'ProteinSummary' ? 'Summary' : $action
    );
    
    if ($count == 1) { 
      $plural =~ s/s$//;
      $splices =~ s/s$//;
    }   
    
    if ($page_type eq 'transcript') {
      my $gene_id  = $gene->stable_id;
      my $gene_url = $hub->url({
        type   => 'Gene',
        action => 'Summary',
        g      => $gene_id
      });
      $gene_html .= sprintf('<p>This transcript is a product of gene <a href="%s">%s</a> %s',
        $gene_url,
        $gene_id,
        $button
      );
    }
   
    ## Link to other haplotype genes
    my $alt_link = $object->get_alt_allele_link;
    if ($alt_link) {
      if ($page_type eq 'gene') {
        $location_html .= "<p>$alt_link</p>";
      }
    }   

    my @columns = (
       { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', label => 'bp', title => 'Length in base pairs'},
       { key => 'protein',    sort => 'html',    label => 'Protein', title => 'Protein length in amino acids' },
       { key => 'translation',sort => 'html',    title => 'Translation ID' },
       { key => 'biotype',    sort => 'html',    title => 'Biotype', align => 'left' },
    );

    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo_sapiens|Mus_musculus/;
    
    my @rows;
   
    my %extra_links = (
      uniprot => { match => "^UniProt", name => "UniProt", order => 0 },
      refseq => { match => "^RefSeq", name => "RefSeq", order => 1 },
    );
    my %any_extras;
 
    foreach (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      my $transcript_length = $_->length;
      my $tsi               = $_->stable_id;
      my $protein           = '';
      my $translation_id    = '';
      my $protein_url       = '';
      my $protein_length    = '-';
      my $ccds              = '-';
      my %extras;
      my $cds_tag           = '-';
      my $gencode_set       = '-';
      my $url               = $hub->url({ %url_params, t => $tsi });
      my (@flags, @evidence);
      
      if (my $translation = $_->translation) {
        $protein_url    = $hub->url({ type => 'Transcript', action => 'ProteinSummary', t => $tsi });
        $translation_id = $translation->stable_id;
        $protein_length = $translation->length;
      }

      my $dblinks = $_->get_all_DBLinks;
      if (my @CCDS = grep { $_->dbname eq 'CCDS' } @$dblinks) { 
        my %T = map { $_->primary_id => 1 } @CCDS;
        @CCDS = sort keys %T;
        $ccds = join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS;
      }
      foreach my $k (keys %extra_links) {
        if(my @links = grep {$_->status ne 'PRED' } grep { $_->dbname =~ /$extra_links{$k}->{'match'}/i } @$dblinks) {
          my %T = map { $_->primary_id => $_->dbname } @links;
          my $cell = '';
          my $i = 0;
          foreach my $u (map $hub->get_ExtURL_link($_,$T{$_},$_), sort keys %T) {
            $cell .= "$u ";
            if($i++==2 || $k ne 'uniprot') { $cell .= "<br/>"; $i = 0; }
          }
          $any_extras{$k} = 1;
          $extras{$k} = $cell;
        }
      }
      if ($trans_attribs->{$tsi}) {
        if ($trans_attribs->{$tsi}{'CDS_start_NF'}) {
          if ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
            push @flags,qq(<span class="glossary_mouseover">CDS 5' and 3' incomplete<span class="floating_popup">$trans_5_3_desc</span></span>);
          }
          else {
            push @flags,qq(<span class="glossary_mouseover">CDS 5' incomplete<span class="floating_popup">$trans_5_desc</span></span>);
          }
        }
        elsif ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
         push @flags,qq(<span class="glossary_mouseover">CDS 3' incomplete<span class="floating_popup">$trans_3_desc</span></span>);
        }
        if ($trans_attribs->{$tsi}{'TSL'}) {
          my $tsl = uc($trans_attribs->{$tsi}{'TSL'} =~ s/^tsl([^\s]+).*$/$1/gr);
          push @flags, sprintf qq(<span class="glossary_mouseover">TSL:%s<span class="floating_popup">%s</span></span>), $tsl, $glossary{"TSL$tsl"};
        }
      }

      if ($trans_gencode->{$tsi}) {
        if ($trans_gencode->{$tsi}{'gencode_basic'}) {
          push @flags,qq(<span class="glossary_mouseover">GENCODE basic<span class="floating_popup">$gencode_desc</span></span>);
        }
      }
      if ($trans_attribs->{$tsi}{'appris'}) {
        my ($code, $text) = @{$trans_attribs->{$tsi}{'appris'}};
        my $glossary_url  = $hub->url({'type' => 'Help', 'action' => 'Glossary', 'id' => '521', '__clear' => 1});
        my $appris_link   = $hub->get_ExtURL_link('APPRIS website', 'APPRIS');
        push @flags, $code
          ? sprintf('<span class="glossary_mouseover">APPRIS %s<span class="floating_popup">%s<br /><a href="%s" class="popup">Glossary entry for APPRIS</a><br />%s</span></span>', uc $code, $text, $glossary_url, $appris_link)
          : sprintf('<span class="glossary_mouseover">APPRIS<span class="floating_popup">%s<br />%s</span></span>', $text, $appris_link);
      }

      (my $biotype_text = $_->biotype) =~ s/_/ /g;
      if ($biotype_text =~ /rna/i) {
        $biotype_text =~ s/rna/RNA/;
      }
      else {
        $biotype_text = ucfirst($biotype_text);
      } 
      my $merged = '';
      $merged .= " Merged Ensembl/Havana gene." if $_->analysis->logic_name =~ /ensembl_havana/;
      $extras{$_} ||= '-' for(keys %extra_links);
      my $row = {
        name        => { value => $_->display_xref ? $_->display_xref->display_id : 'Novel', class => 'bold' },
        transcript  => sprintf('<a href="%s">%s</a>', $url, $tsi),
        bp_length   => $transcript_length,
        protein     => $protein_url ? sprintf '<a href="%s" title="View protein">%saa</a>', $protein_url, $protein_length : 'No protein',
        translation => $protein_url ? sprintf '<a href="%s" title="View protein">%s</a>', $protein_url, $translation_id : '-',
        biotype     => $self->colour_biotype($self->glossary_mouseover($biotype_text,undef,$merged),$_),
        ccds        => $ccds,
        %extras,
        has_ccds   => $ccds eq '-' ? 0 : 1,
        cds_tag    => $cds_tag,
        gencode_set=> $gencode_set,
        options    => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' },
        flags => join('',map { $_ =~ /<img/ ? $_ : "<span class='ts_flag'>$_</span>" } @flags),
        evidence => join('', @evidence),
      };
      
      $biotype_text = '.' if $biotype_text eq 'Protein coding';
      $biotype_rows{$biotype_text} = [] unless exists $biotype_rows{$biotype_text};
      push @{$biotype_rows{$biotype_text}}, $row;
    }
    foreach my $k (sort { $extra_links{$a}->{'order'} cmp
                          $extra_links{$b}->{'order'} } keys %any_extras) {
      my $x = $extra_links{$k};
      push @columns, { key => $k, sort => 'html', title => $x->{'name'}};
    }
    push @columns, { key => 'flags', sort => 'html', title => 'Flags', 'hidden' => 1 };  ## ParaSite: hide the flags column by default as we have no data here

    ## Additionally, sort by CCDS status and length
    while (my ($k,$v) = each (%biotype_rows)) {
      my @subsorted = sort {$b->{'has_ccds'} cmp $a->{'has_ccds'}
                            || $b->{'bp_length'} <=> $a->{'bp_length'}} @$v;
      $biotype_rows{$k} = \@subsorted;
    }

    # Add rows to transcript table
    push @rows, @{$biotype_rows{$_}} for sort keys %biotype_rows; 

    $transc_table = $self->new_table(\@columns, \@rows, {
      data_table        => 1,
      data_table_config => { asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
      toggleable        => 1,
      class             => 'fixed_width' . ($show ? '' : ' hide'),
      id                => 'transcripts_table',
      exportable        => 1
    });
    
    # since counts form left nav is gone, we are adding it in the description  
    if($page_type eq 'gene') {
      my @str_array;
      my $ortholog_url = $hub->url({
        type   => 'Gene',
        action => 'Compara_Ortholog',
        g      => $gene->stable_id
      });
      
      my $paralog_url = $hub->url({
        type   => 'Gene',
        action => 'Compara_Paralog',
        g      => $gene->stable_id
      });
      
      my $protein_url = $hub->url({
        type   => 'Gene',
        action => 'Family',
        g      => $gene->stable_id
      });

      my $phenotype_url = $hub->url({
        type   => 'Gene',
        action => 'Phenotype',
        g      => $gene->stable_id
      });    

      my $splice_url = $hub->url({
        type   => 'Gene',
        action => 'Splice',
        g      => $gene->stable_id
      });        
      
      push @str_array, sprintf('%s %s', 
                          $avail->{has_transcripts}, 
                          $avail->{has_transcripts} eq "1" ? "transcript (<a href='$splice_url'>splice variant</a>)" : "transcripts (<a href='$splice_url'>splice variants)</a>"
                      ) if($avail->{has_transcripts});
      push @str_array, sprintf('%s gene %s', 
                          $avail->{has_alt_alleles}, 
                          $avail->{has_alt_alleles} eq "1" ? "allele" : "alleles"
                      ) if($avail->{has_alt_alleles});
      push @str_array, sprintf('<a href="%s">%s %s</a>', 
                          $ortholog_url, 
                          $avail->{has_orthologs}, 
                          $avail->{has_orthologs} eq "1" ? "orthologue" : "orthologues"
                      ) if($avail->{has_orthologs});
      push @str_array, sprintf('<a href="%s">%s %s</a>',
                          $paralog_url, 
                          $avail->{has_paralogs}, 
                          $avail->{has_paralogs} eq "1" ? "paralogue" : "paralogues"
                      ) if($avail->{has_paralogs});    
      push @str_array, sprintf('is a member of <a href="%s">%s Ensembl protein %s</a>', $protein_url, 
                          $avail->{family_count}, 
                          $avail->{family_count} eq "1" ? "family" : "families"
                      ) if($avail->{family_count});
      push @str_array, sprintf('is associated with <a href="%s">%s %s</a>', 
                          $phenotype_url, 
                          $avail->{has_phenotypes}, 
                          $avail->{has_phenotypes} eq "1" ? "phenotype" : "phenotypes"
                      ) if($avail->{has_phenotypes});
     
      $counts_summary  = sprintf('This gene has %s.',$self->join_with_and(@str_array));    
      $gene_html      .= $button;
    } 
    
    if($page_type eq 'transcript') {    
      my @str_array;
      
      my $exon_url = $hub->url({
        type   => 'Transcript',
        action => 'Exons',
        g      => $gene->stable_id
      }); 
      
      my $similarity_url = $hub->url({
        type   => 'Transcript',
        action => 'Similarity',
        g      => $gene->stable_id
      }); 
      
      my $oligo_url = $hub->url({
        type   => 'Transcript',
        action => 'Oligos',
        g      => $gene->stable_id
      });     

      my $domain_url = $hub->url({
        type   => 'Transcript',
        action => 'Domains',
        g      => $gene->stable_id
      });
      
      my $variation_url = $hub->url({
        type   => 'Transcript',
        action => 'ProtVariations',
        g      => $gene->stable_id
      });     
     
      push @str_array, sprintf('<a href="%s">%s %s</a>', 
                          $exon_url, $avail->{has_exons}, 
                          $avail->{has_exons} eq "1" ? "exon" : "exons"
                        ) if($avail->{has_exons});
                        
      push @str_array, sprintf('is annotated with <a href="%s">%s %s</a>', 
                          $domain_url, $avail->{has_domains}, 
                          $avail->{has_domains} eq "1" ? "domain and feature" : "domains and features"
                        ) if($avail->{has_domains});

      push @str_array, sprintf('is associated with <a href="%s">%s %s</a>', 
                          $variation_url, 
                          $avail->{has_variations}, 
                          $avail->{has_variations} eq "1" ? "variation" : "variations",
                        ) if($avail->{has_variations});    
      
      push @str_array, sprintf('maps to <a href="%s">%s oligo %s</a>',    
                          $oligo_url,
                          $avail->{has_oligos}, 
                          $avail->{has_oligos} eq "1" ? "probe" : "probes"
                        ) if($avail->{has_oligos});
                  
      $counts_summary  = sprintf('<p>This transcript has %s.</p>', $self->join_with_and(@str_array));  
    }    
  }

  $table->add_row('Location', $location_html);

  my $insdc_accession;
  $insdc_accession = $self->object->insdc_accession if $self->object->can('insdc_accession');
  $table->add_row('INSDC coordinates',$insdc_accession) if $insdc_accession;
  
  $table->add_row( $page_type eq 'gene' ? 'About this gene' : 'About this transcript',$counts_summary) if $counts_summary;

## ParaSite: move the gene summary out of its own module (this code is all originally from EnsEMBL::Web::Component::Gene::GeneSummary
  if($page_type eq 'gene') {
    my $type = $object->gene_type;
    $table->add_row('Gene type', $type) if $type;
    eval {
      my $label = 'Annotation Method';
      my $text  = "<p>No $label defined in database</p>";
      my $o     = $object->Obj;
      if ($o && $o->can('analysis') && $o->analysis && $o->analysis->description) {
        $text = $o->analysis->description;
      } elsif ($object->can('gene') && $object->gene->can('analysis') && $object->gene->analysis && $object->gene->analysis->description) {
        $text = $object->gene->analysis->description;
      }
  
      $table->add_row($label, $text);
    };
  }
##

## ParaSite: show the orthologues from model organisms
#  if($page_type eq 'gene') {
#    my $orthologues = $object->get_homology_matches('ENSEMBL_ORTHOLOGUES', undef, undef, $cdb);
#    my %matches;
#    my $orth_text;
#    foreach my $match (keys %$orthologues) {
#      my $group = $hub->species_defs->COMPARA_SPECIES_SET->{lc($match)} || $hub->species_defs->get_config($match, 'SPECIES_GROUP') || 'all';
#      next unless $group eq 'models' || $group eq 'elegans' || $group eq 'human';
#      my $display = $hub->species_defs->species_label(lc($match));
#      $matches{$display} = join("; ", map("<a href=\"" . $hub->get_ExtURL($hub->species_defs->ENSEMBL_SPECIES_SITE->{lc($match)} . "_GENE", {'SPECIES'=>$match, 'ID'=>$_}) . "\" title=\"$_\">" . ($hub->database($cdb)->get_GeneMemberAdaptor->fetch_by_stable_id($_)->display_label || $_) . "</a>", keys %$orthologues->{$match}));
#    }
#    foreach(sort keys %matches) {
#      $orth_text .= "$_: $matches{$_}<br />";
#    }
#    $table->add_row('Model organism orthologues', $orth_text || 'None');
#  }
##

## ParaSite: check for wormbase_gene xref
  my $wormbase;
  my $xrefs = $page_type eq 'gene' ? $object->Obj->get_all_DBEntries() : $object->gene->get_all_DBEntries();
  foreach my $xref (@{$xrefs}) {
    $wormbase = $hub->get_ExtURL_link('[View at WormBase central]', 'WORMBASE_GENE', {'SPECIES'=>$species, 'ID'=>$gene->stable_id}) if $xref->dbname =~ /^wormbase_gene$/i;
  }
##

  $table->add_row($page_type eq 'gene' ? 'Transcripts' : 'Gene', $gene_html) if $gene_html;

## ParaSite: add in an external reference
  return sprintf '<div class="wormbase_panel">%s</div><div class="summary_panel">%s%s</div>', $wormbase, $table->render, $transc_table ? $transc_table->render : '';
##
}

sub get_gene_display_link {
  ## @param Gene object
  ## @param Gene xref object or description string
  my ($self, $gene, $xref) = @_;

  my $hub = $self->hub;

  if ($xref && !ref $xref) { # description string
    my $details = { map { split ':', $_, 2 } split ';', $xref =~ s/^.+\[|\]$//gr };
## ParaSite: modified this slightly to use the new code, but with the E80 API
    foreach(@{$gene->get_all_DBLinks}) {
      $xref = $_ if($_->primary_id eq $details->{'Acc'} && $_->db_display_name eq $details->{'Source'});
    }
##
  }

  return unless $xref && $xref->info_type ne 'PROJECTION';

  my $url = $hub->get_ExtURL($xref->dbname, $xref->primary_id);

  return $url ? ($url, $xref) : ();
}

1;
