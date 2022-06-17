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

package EnsEMBL::Web::Component::Shared;

use strict;
use Bio::EnsEMBL::Gene;

sub transcript_table {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;  
  my $species     = $hub->species;
  my $table       = $self->new_twocol;
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  my $description = $object->gene_description;
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
## EG - returns xref as string
#      $xref        = $xref->primary_id;
##
      $description =~ s|$xref|<a href="$url" class="constant">$xref</a>|;
    }

    $table->add_row('Description', $description);
  }

  my $location    = $hub->param('r') || sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

  my $site_type         = $hub->species_defs->ENSEMBL_SITETYPE; 
  my @SYNONYM_PATTERNS  = qw(%HGNC% %ZFIN%);
  my (@syn_matches, $syns_html, $about_count);
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

  $table->add_row('Synonyms', $syns_html) if $syns_html;

  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant">%s:%s-%s</a> %s.',
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
  my $gencode_desc    = "The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).";
  my $gene_html       = '';
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

    foreach my $trans (@$transcripts) {
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic TSL appris)) {
        (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
        next unless $attrib;
        if($attrib_type eq 'gencode_basic' && $attrib->value) {
          $trans_gencode->{$trans->stable_id}{$attrib_type} = $attrib->value;
        } elsif ($attrib_type eq 'appris'  && $attrib->value) {
          ## There should only be one APPRIS code per transcript
          my $short_code = $attrib->value;
          ## Manually shorten the full attrib values to save space
          $short_code =~ s/ernative//;
          $short_code =~ s/rincipal//;
          $trans_attribs->{$trans->stable_id}{'appris'} = [$short_code, $attrib->value]; 
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
      # { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', label => 'bp', title => 'Length in base pairs'},
       { key => 'protein',sort => 'html_numeric',label => 'Protein', title => 'Protein length in amino acids' },
       { key => 'translation',sort => 'html',    title => 'Translation ID', 'hidden' => 1 },
       { key => 'biotype',    sort => 'html',    title => 'Biotype', align => 'left' },
    );

    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo_sapiens|Mus_musculus/;
    
    my @rows;
   
    my %extra_links = (
      uniprot => { match => "^UniProt/[SWISSPROT|SPTREMBL]", name => "UniProt", order => 0 },
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
        if (my $incomplete = $self->get_CDS_text($trans_attribs->{$tsi})) {
          push @flags, $incomplete;
        }
        if ($trans_attribs->{$tsi}{'TSL'}) {
          my $tsl = uc($trans_attribs->{$tsi}{'TSL'} =~ s/^tsl([^\s]+).*$/$1/gr);
          push @flags, $self->helptip("TSL:$tsl", $self->get_glossary_entry("TSL:$tsl").$self->get_glossary_entry('TSL'));
        }
      }

      if ($trans_gencode->{$tsi}) {
        if ($trans_gencode->{$tsi}{'gencode_basic'}) {
          push @flags, $self->helptip('GENCODE basic', $gencode_desc);
        }
      }
      if ($trans_attribs->{$tsi}{'appris'}) {
        my ($code, $key) = @{$trans_attribs->{$tsi}{'appris'}};
        my $short_code = $code ? ' '.uc($code) : '';
          push @flags, $self->helptip("APPRIS$short_code", $self->get_glossary_entry("APPRIS: $key").$self->get_glossary_entry('APPRIS'));
      }

      (my $biotype_text = $_->biotype) =~ s/_/ /g;
      if ($biotype_text =~ /rna/i) {
        $biotype_text =~ s/rna/RNA/;
      }
      else {
        $biotype_text = ucfirst($biotype_text);
      } 

      $extras{$_} ||= '-' for(keys %extra_links);
      my $row = {
       # name        => { value => $_->display_xref ? $_->display_xref->display_id : 'Novel', class => 'bold' },
        transcript  => sprintf('<a href="%s">%s</a>', $url, $tsi),
        bp_length   => $transcript_length,
        protein     => $protein_url ? sprintf '<a href="%s" title="View protein">%saa</a>', $protein_url, $protein_length : 'No protein',
        translation => $protein_url ? sprintf '<a href="%s" title="View protein">%s</a>', $protein_url, $translation_id : '-',
        biotype     => $self->colour_biotype($biotype_text, $_),
        ccds        => $ccds,
        %extras,
        has_ccds    => $ccds eq '-' ? 0 : 1,
        cds_tag     => $cds_tag,
        gencode_set => $gencode_set,
        options     => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' },
        flags       => join('',map { $_ =~ /<img/ ? $_ : "<span class='ts_flag'>$_</span>" } @flags),
        evidence    => join('', @evidence),
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
  
    if($page_type eq 'gene') {        
      $gene_html      .= $button;
    } 
    
    $about_count = $self->about_feature; # getting about this gene or transcript feature counts
    
  }

  $table->add_row('Location', $location_html);

## ParaSite: add INSDC accession as separate row
  my $insdc_html;
  my $insdc_accession = $self->object->insdc_accession if $self->object->can('insdc_accession');
  if ($insdc_accession) {
    $insdc_html = sprintf('<p><a href="http://www.ebi.ac.uk/ena/data/view/%s">%s</a></p>', $insdc_accession, $insdc_accession);
    $table->add_row('INSDC Sequence ID', $insdc_html);
  }
##

  $table->add_row( $page_type eq 'gene' ? 'Gene Overview' : 'Transcript Overview',$about_count) if $about_count;
  
## ParaSite: move the gene summary out of its own module (this code is all originally from EnsEMBL::Web::Component::Gene::GeneSummary
  if($page_type eq 'gene') {
    my $type = $object->gene_type;
    $table->add_row('Gene Type', $type) if $type;
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

  $table->add_row($page_type eq 'gene' ? 'Transcripts' : 'Gene', $gene_html) if $gene_html;

  return sprintf '<div class="summary_panel">%s%s</div>', $table->render, $transc_table ? $transc_table->render : '';

}

sub species_stats {
  my $self = shift;
  my $sd = $self->hub->species_defs;
  my $html;
  my $db_adaptor = $self->hub->database('core');
  my $meta_container = $db_adaptor->get_MetaContainer();
  my $genome_container = $db_adaptor->get_GenomeContainer();
  my $html;

  my $cols = [
    { key => 'name', title => '', width => '30%', align => 'left' },
    { key => 'stat', title => '', width => '70%', align => 'left' },
  ];
  my $options = {'header' => 'no', 'rows' => ['bg3', 'bg1']};

  my $summary = $self->new_table($cols, [], $options);

  my( $a_id ) = ( @{$meta_container->list_value_by_key('assembly.name')},
                    @{$meta_container->list_value_by_key('assembly.default')});
  if ($a_id) {
    # look for long name and accession num
    if (my ($long) = @{$meta_container->list_value_by_key('assembly.long_name')}) {
      $a_id .= " ($long)";
    }
    if (my ($acc) = @{$meta_container->list_value_by_key('assembly.accession')}) {
      $acc = sprintf('<a href="http://www.ebi.ac.uk/ena/data/view/%s">%s</a>', $acc, $acc);
      $a_id .= ", $acc";
    }
  }
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Assembly</span>',
      'stat' => sprintf('%s%s', $a_id, $sd->ASSEMBLY_DATE ? ', '.$sd->ASSEMBLY_DATE : '')
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Strain</span>',
      'stat' => $sd->SPECIES_STRAIN
  }) if $sd->SPECIES_STRAIN;
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Database Version</span>',
      'stat' => 'WBPS' . $sd->SITE_RELEASE_VERSION
  });
  my $header = $self->glossary_helptip('Genome Size', 'Golden path length');
  $summary->add_row({
      'name' => qq(<span style="font-weight: bold">$header</span>),
      'stat' => $self->thousandify($genome_container->get_ref_length())
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Data Source</span>',
      'stat' => ref $sd->PROVIDER_NAME eq 'ARRAY' ? join(', ', @{$sd->PROVIDER_NAME}) : $sd->PROVIDER_NAME
  });
  $summary->add_row({
      'name' => '<span style="font-weight: bold">Annotation Version</span>',
      'stat' => $sd->GENEBUILD_VERSION
  });

  $html .= $summary->render;

  ## GENE COUNTS
  $html .= $self->_add_gene_counts($genome_container,$sd,$cols,$options,'','');

  return $html;

}

1;
