package EnsEMBL::Web::Component::Summary;

use strict;

use parent qw(EnsEMBL::Web::Component);

sub summary {
  my ($self, $page_type) = @_;

  my $hub         = $self->hub;
  my $object      = $self->object;  
  my $species     = $hub->species;

  ## Build two-column layout of main content
  my $two_col     = $self->new_twocol;
  my $gene        = $page_type eq 'gene' ? $object->Obj : $object->gene;

  my $description = $self->get_description;
  $two_col->add_row('Description', $description) if $description;
  
  my $synonyms = $self->get_synonym_html($gene);
  $two_col->add_row('Gene Synonyms', $synonyms) if $synonyms;

  my $location_html = $self->get_location_html($page_type);
  $two_col->add_row('Location', $location_html);

## ParaSite: add INSDC accession as separate row
  my $insdc_html;
  my $insdc_accession = $object->insdc_accession if $object->can('insdc_accession');
  if ($insdc_accession) {
    $insdc_html = sprintf('<p><a href="http://www.ebi.ac.uk/ena/data/view/%s">%s</a></p>', $insdc_accession, $insdc_accession);
    $two_col->add_row('INSDC Sequence ID', $insdc_html);
  }
##  

  ## Extra content (if relevant)
  my @extra_rows = $self->get_extra_rows($page_type);
  $two_col->add_rows(@extra_rows) if scalar @extra_rows;

  ## Finally add general information
  my $about_count = $gene ? $self->about_feature : 0; 
  $two_col->add_row( $page_type eq 'gene' ? 'About this gene' : 'About this transcript', $about_count) if $about_count;

## ParaSite: move the gene summary out of its own module (this code is all originally from EnsEMBL::Web::Component::Gene::GeneSummary
  if($page_type eq 'gene') {
  my $type = $object->gene_type;
  $two_col->add_row('Gene Type', $type) if $type;
  eval {
    my $label = 'Annotation Method';
    my $text  = "<p>No $label defined in database</p>";
    my $o     = $object->Obj;
    if ($o && $o->can('analysis') && $o->analysis && $o->analysis->description) {
      $text = $o->analysis->description;
    } elsif ($object->can('gene') && $object->gene->can('analysis') && $object->gene->analysis && $object->gene->analysis->description) {
      $text = $object->gene->analysis->description;
    }

    $two_col->add_row($label, $text);
  };
} 
##

  ## Add button to toggle table (below)
  my $show        = $hub->get_cookie_value('toggle_transcripts_table') eq 'open';
  my $button_html = $self->get_button_html($gene, $page_type, $show);
  $two_col->add_row($page_type eq 'gene' ? 'Transcripts' : 'Gene', $button_html) if $button_html;

  ## Now create togglable transcript table
  my $table = $self->transcript_table($page_type, $gene, $show);

  ## Return final HTML
  return sprintf '<div class="summary_panel">%s%s</div>', $two_col->render, $table ? $table->render : '';
}


sub get_location_html {
  my ($self, $page_type) = @_;
  my $object  = $self->object;
  my $hub     = $self->hub;

  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location    = sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant dynamic-link">%s: %s-%s</a> %s.',
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

## ParaSite do not include INSDC here
  # my $insdc_accession = $object->insdc_accession if $object->can('insdc_accession');
  # if ($insdc_accession) {
  #   $location_html .= "<p>$insdc_accession</p>";
  # }
##

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
          $self->hub->species, $altchr, $altstart, $altend, $altchr,
          $self->thousandify($altstart),
          $self->thousandify($altend)
        );
      }

      $location_html .= '
        </ul>';
    }
    ## Link to other haplotype genes
    my $alt_link = $object->get_alt_allele_link;
    if ($alt_link) {
      $location_html .= "<p>$alt_link</p>";
    }   
  }

  return $location_html;
}

sub transcript_table {
  my ($self, $page_type, $gene, $show) = @_;
  return unless $gene;

  my $object    = $self->object;
  my $hub       = $self->hub;
  my $species   = $hub->species;
  my $sub_type  = $hub->species_defs->ENSEMBL_SUBTYPE;

  my $table = $self->new_table([], [], {
      data_table        => 1,
      data_table_config => { bPaginate => 'false', asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
      toggleable        => 1,
      class             => 'fixed_width' . ($show ? '' : ' hide'),
      id                => 'transcripts_table',
      exportable        => 1
  });

  my $has_ccds = $hub->species eq 'Homo_sapiens' || $hub->species =~ /^Mus_musculus/;
  my @columns = $self->set_columns($has_ccds);
  my @rows;

  my $gencode_desc    = qq(The GENCODE set is the gene set for human and mouse. <a href="/Help/Glossary?id=500" class="popup">GENCODE Basic</a> is a subset of representative transcripts (splice variants).);

  my $version     = $object->version ? ".".$object->version : "";
  my $transcript  = $page_type eq 'transcript' ? $object->stable_id : $hub->param('t');
  my $transcripts = $gene->get_all_Transcripts;
  my $count       = @$transcripts;
  my $action      = $hub->action;
  my %biotype_rows;

  #keys are attrib_type codes, values are glossary entries 
  my %MANE_attrib_codes = (
    MANE_Select => 'MANE Select',
    MANE_Plus_Clinical   => 'MANE Plus Clinical');

  my $trans_attribs = {};
  my @attrib_types = ('is_canonical','gencode_basic','appris','TSL','CDS_start_NF','CDS_end_NF');
  push(@attrib_types, keys %MANE_attrib_codes);

  foreach my $trans (@$transcripts) {
    foreach my $attrib_type (@attrib_types) {
      (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
      next unless $attrib && $attrib->value;
      if ($attrib_type eq 'appris') {
        ## Assume there is only one APPRIS attribute per transcript
        my $short_code = $attrib->value;
        ## Manually shorten the full attrib values to save space
        $short_code =~ s/ernative//;
        $short_code =~ s/rincipal//;
        $trans_attribs->{$trans->stable_id}{'appris'} = [$short_code, $attrib->value]; 
      }
      elsif ($MANE_attrib_codes{$attrib_type}) {
        $trans_attribs->{$trans->stable_id}{$attrib_type} = [$attrib->name, $attrib->value];
      }
      else {
        $trans_attribs->{$trans->stable_id}{$attrib_type} = $attrib->value;
      }
    }
  }

  my %url_params = (
      type   => 'Transcript',
      action => $page_type eq 'gene' ? 'Summary' : $action,
  );
   
  my %extra_links = %{$self->get_extra_links}; 
  my %any_extras;
  foreach (@$transcripts) {
    my $transcript_length = $_->length;
    my $version           = $_->version ? ".".$_->version : "";
    my $tsi               = $_->stable_id;
    my $protein           = '';
    my $translation_id    = '';
    my $translation_ver   = '';
    my $protein_url       = '';
    my $protein_length    = '-';
    my $ccds              = '-';
    my %extras;
    my $cds_tag           = '-';
    my $gencode_set       = '-';
    my (@flags, @evidence);

    ## Override link destination if this transcript has no protein
    if (!$_->translation && ($action eq 'ProteinSummary' || $action eq 'Domains' || $action eq 'ProtVariations')) {
      $url_params{'action'} = 'Summary';
    }
    my $url = $hub->url({ %url_params, t => $tsi });

    if (my $translation = $_->translation) {
      $translation_id   = $translation->stable_id;
      $protein_url      = $hub->url({ type => 'Transcript', action => $self->protein_action($translation_id), t => $tsi });
      $translation_ver  = $translation->version ? $translation_id.'.'.$translation->version:$translation_id;
      $protein_length   = $translation->length;
    }

    my $ccds;
    if (my @CCDS = @{ $_->get_all_DBLinks('CCDS') }) { 
      my %T = map { $_->primary_id => 1 } @CCDS;
      @CCDS = sort keys %T;
      $ccds = join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS;
    }

    foreach my $k (keys %extra_links) {

      my @links;
      if ($extra_links{$k}->{'match'}) { 
        ## Non-vertebrates - use API to filter db links, as faster
        @links = grep {$_->status ne 'PRED' } @{ $_->get_all_DBLinks($extra_links{$k}->{'match'}) }
      }
      else {
        my $dblinks = $_->get_all_DBLinks; 
        @links = grep {$_->status ne 'PRED' } grep { $_->dbname =~ /$extra_links{$k}->{'first_match'}/i } @$dblinks;
        ## Try second match
        if(!@links && $extra_links{$k}->{'second_match'}){
          @links = grep {$_->status ne 'PRED' } grep { $_->dbname =~ /$extra_links{$k}->{'second_match'}/i } @$dblinks;
        }
      }

      if(@links) {
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

    # Flag order: is_canonical, MANE_select, MANE_plus_clinical, gencode_basic, appris, TSL, CDS_start_NF, CDS_end_NF
    my $refseq_url;
    if ($trans_attribs->{$tsi}) {
      if ($trans_attribs->{$tsi}{'is_canonical'}) {
        push @flags, helptip("Ensembl Canonical", get_glossary_entry($hub, "Ensembl canonical"));
      }

      foreach my $MANE_attrib_code (keys %MANE_attrib_codes) {
        if (my $mane_attrib = $trans_attribs->{$tsi}{$MANE_attrib_code}) {
          my ($mane_name, $refseq_id) = @{$mane_attrib};
          $refseq_url  = $hub->get_ExtURL_link($refseq_id, 'REFSEQ_MRNA', $refseq_id);
          my $flagtip = helptip($mane_name, get_glossary_entry($hub, $MANE_attrib_codes{$MANE_attrib_code}));
          $MANE_attrib_code eq  'MANE_Select'? unshift @flags, $flagtip : push @flags, $flagtip;
        }
      }

      if ($sub_type eq 'GRCh37') {
        ## Get RefSeq id from xrefs
        my @db_links =  @{$_->get_all_DBLinks(undef, 'MISC')};
        foreach my $db_entry (@db_links) {
          my $key = $db_entry->db_display_name;
          next unless $key eq "RefSeq mRNA";
          my $refseq_id = $db_entry->display_id;
          $refseq_url   = $hub->get_ExtURL_link($refseq_id, 'REFSEQ_MRNA', $refseq_id);
        }
      }

      if ($trans_attribs->{$tsi}{'gencode_basic'}) {
        push @flags, helptip('GENCODE basic', $gencode_desc);
      }

      if ($trans_attribs->{$tsi}{'appris'}) {
        my ($code, $key) = @{$trans_attribs->{$tsi}{'appris'}};
        my $short_code = $code ? ' '.uc($code) : '';
        push @flags, helptip("APPRIS $short_code","<p>APPRIS $short_code: ".get_glossary_entry($hub, "APPRIS$short_code")."</p><p>".get_glossary_entry($hub, 'APPRIS')."</p>");
      }

      if ($trans_attribs->{$tsi}{'TSL'}) {
        my $tsl = uc($trans_attribs->{$tsi}{'TSL'} =~ s/^tsl([^\s]+).*$/$1/gr);
        push @flags, helptip("TSL:$tsl", "<p>TSL $tsl: ".get_glossary_entry($hub, "TSL $tsl")."</p><p>".get_glossary_entry($hub, 'Transcript support level')."</p>");
      }

      if (my $incomplete = $self->get_CDS_text($trans_attribs->{$tsi})) {
        push @flags, $incomplete;
      }
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
      name        => $self->transcript_name($_),
      transcript  => sprintf('<a href="%s">%s%s</a>', $url, $tsi, $version),
      bp_length   => $transcript_length,
      protein     => $protein_url ? sprintf '<a href="%s" title="View protein">%saa</a>', $protein_url, $protein_length : 'No protein',
      translation => $protein_url ? sprintf '<a href="%s" title="View protein">%s</a>', $protein_url, $translation_ver : '-',
      biotype     => $self->colour_biotype($biotype_text, $_),
      is_canonical  => $trans_attribs->{$tsi}{'is_canonical'} || $trans_attribs->{$tsi}{'MANE_Select'}? 1 : 0,
      ccds        => $ccds,
      %extras,
      has_ccds    => $ccds eq '-' ? 0 : 1,
      cds_tag     => $cds_tag,
      gencode_set => $gencode_set,
      refseq  => $refseq_url ? $refseq_url : '-',
      options     => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' },
      flags       => @flags ? join('',map { $_ =~ /<img/ ? $_ : "<span class='ts_flag'>$_<span class='hidden export'>, </span></span>" } @flags) : '-',
      evidence    => join('', @evidence),
    };

    $biotype_text = '.' if $biotype_text eq 'Protein coding';
    $biotype_rows{$biotype_text} = [] unless exists $biotype_rows{$biotype_text};
    push @{$biotype_rows{$biotype_text}}, $row;
  }

  foreach my $k (sort { $extra_links{$a}->{'order'} cmp
                        $extra_links{$b}->{'order'} } keys %any_extras) {
    my $x = $extra_links{$k};
    push @columns, { key => $k, sort => 'html', title => $x->{'title'}, label => $x->{'name'}, class => '_ht'};
  }
  
  if ($species eq 'Homo_sapiens') {
    if ($sub_type eq 'GRCh37') {
      push @columns, { key => 'refseq', sort => 'html', label => 'RefSeq', title => get_glossary_entry($self->hub, 'RefSeq'), class => '_ht' };
    }
    else {
      push @columns, { key => 'refseq', sort => 'html', label => 'RefSeq Match', title => get_glossary_entry($self->hub, 'RefSeq Match'), class => '_ht' };
    }
  }

  my $title = encode_entities('<a href="/info/genome/genebuild/transcript_quality_tags.html" target="_blank">Tags</a>');
## ParaSite: hide the flags column by default as we have no data here 
  #push @columns, { key => 'flags', sort => 'html', label => 'Flags', title => $title, class => '_ht'};
  push @columns, { key => 'flags', sort => 'html', title => 'Flags', 'hidden' => 1 };
##
## ParaSite: hide the name column which appears to be the 1st column of @columns
  $columns[0]->{'hidden'} = 1;
##

  ## Transcript order: biotype => canonical => CCDS => length
  while (my ($k,$v) = each (%biotype_rows)) {
    my @subsorted = sort {$b->{'is_canonical'} cmp $a->{'is_canonical'}
                          || $b->{'has_ccds'} cmp $a->{'has_ccds'}
                          || $b->{'bp_length'} <=> $a->{'bp_length'}} @$v;
    $biotype_rows{$k} = \@subsorted;
  }

  # Add rows to transcript table
  push @rows, @{$biotype_rows{$_}} for sort keys %biotype_rows; 

  ## Add everything to the table
  $table->add_columns(@columns);
  $table->add_rows(@rows);
  return $table;
}

1;
