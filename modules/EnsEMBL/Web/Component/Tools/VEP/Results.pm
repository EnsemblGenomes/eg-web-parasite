package EnsEMBL::Web::Component::Tools::VEP::Results;

use strict;
use warnings;

our %PROTEIN_DOMAIN_LABELS = (
  'Pfam_domain'         => 'PFAM',
  'Prints_domain'       => 'PRINTS',
  'TIGRFAM_domain'      => 'TIGRFAM',
  'SMART_domains'       => 'SMART',
  'Superfamily_domains' => 'SUPERFAMILY',
  'hmmpanther'          => 'PANTHERDB',
  'PROSITE_profiles'    => 'PROSITE_PROFILES',
  'PROSITE_patterns'    => 'PROSITE_PATTERNS',
);

# Get a list of comma separated items and transforms it into a bullet point list
sub get_items_in_list {
  my $self    = shift;
  my $row_id  = shift;
  my $type    = shift;
  my $label   = shift;
  my $data    = shift;
  my $species = shift;
  my $min_items_count = shift;

  my $hub = $self->hub;

  $min_items_count ||= 5;

  my $div = ', ';
  if($type eq 'variant_synonyms'){
    $div = '--';
  }
  elsif($type eq 'IntAct_pmid' or $type eq 'IntAct_interaction_ac'){
    $div = ',';
  }

  my @items_list = split($div,$data);
  my @items_with_url;

  # Prettify format for phenotype entries
  if ($type eq 'phenotype') {
    @items_list = $self->prettify_phenotypes(\@items_list, $species);
    @items_with_url = @items_list;
  }
  elsif ($type eq 'disgenet') {
    foreach my $entry (@items_list) {
      # entry example '18630525:0.02:Malignant_Neoplasms'
      $entry =~ s/_/&nbsp;/g;
      my @disgenet_value = split /:/, $entry;
      my $pmid_url = $hub->get_ExtURL_link($disgenet_value[0], 'EPMC_MED', $disgenet_value[0]);
      my $new_entry = $pmid_url . ' <b>Score:</b>&nbsp;' . $disgenet_value[1] . ' <b>Disease:</b>&nbsp;' . $disgenet_value[2];
      push (@items_with_url, $new_entry);
    }
  }
  elsif ($type eq 'variant_synonyms') {
    my %synonyms;
    foreach my $entry (@items_list) {
      my @parts = split('::', $entry);
      $synonyms{$parts[0]} = $parts[1];
    }
    foreach my $source (keys %synonyms) {
      my @items_with_url_source;
      my $source_id = $source;
      if(uc $source eq 'CLINVAR') {
        $source_id = 'CLINVAR_VAR';
      }
      if(uc $source eq 'UNIPROT') {
        $source_id = 'UNIPROT_VARIATION';
      }
      if(uc $source eq 'PHARMGKB') {
        $source_id = 'PHARMGKB_VARIANT';
      }
      my @values = split(', ', $synonyms{$source});
      foreach my $value (@values) {
        my $new_value = $value;
        if(uc $source eq 'OMIM') {
          $new_value =~ s/\./#/;
        }
        next if(uc $source eq 'CLINVAR' && $value =~ /^RCV/);
        my $item_url = $hub->get_ExtURL_link($value, $source_id, $new_value);
        push(@items_with_url_source, uri_unescape($item_url));
      }
      $source =~ s/\_/ /g;
      my $new_source = '<b>'.$source.'</b>';
      push(@items_with_url, $new_source.'&nbsp;'.join(', ', @items_with_url_source));
    }
  }
  # Add external links
  else {
    foreach my $item (@items_list) {
      my $item_url = $item;
      if ($type eq 'pubmed') {
        $item_url = $hub->get_ExtURL_link($item, 'EPMC_MED', $item);
      }
      elsif ($item =~ /^(PDB-ENSP_mappings:)((.+)\.\w)$/i) {
        $item_url = "$1&nbsp;".$hub->get_ExtURL_link($2, 'PDB', $3);
      }
      ## ParaSite: different prefix and id format 
      elsif ($item =~ /^AlphaFold_DB_import:(.+)$/i) {
        # The alphafold ids we store in Ensembl databases (e.g. AF-P63151-F1.A)
        # are fake ids, which consist of the real alphafold id followed by a dot and a chain name.
        # Meanwhile, the alphafold site uses Uniprot ids as accession ids.
        # A Uniprot id is the middle part of an alphafold id (separated by hyphens).
        # Hopefully, things will improve in the future.
        my $actual_alphafold_id = $1;
        my ( $uniprot_id ) = $actual_alphafold_id =~ /-(.+)-/; # the middle part of an alphafold id
        $item_url = "AlphaFold_DB_import:" . "&nbsp" . $hub->get_ExtURL_link($actual_alphafold_id, 'ALPHAFOLD', $uniprot_id);
      }
      ##
      elsif ($type eq 'mastermind_mmid3') {
        $item_url = $hub->get_ExtURL_link($item, 'MASTERMIND', $item);
      }
      elsif ($type eq 'IntAct_interaction_ac') {
      	$item =~ s/^\s+|\s+$//;
        $item_url = $hub->get_ExtURL_link($item, 'INTACT', $item);
      }
      elsif ($type eq 'IntAct_pmid') {
        $item =~ s/^\s+|\s+$//;
        $item_url = $hub->get_ExtURL_link($item, 'EPMC_MED', $item);
      }
      elsif ($type eq 'GO'){
        $item =~ s/^\s+|\s+$//;
        # Replace underscores with spaces to avoid long column width
        $item =~ s/_/ /g;

        # Some GO term descriptions have colons, so only split item by first 2 colons
        # e.g. GO:0008499:UDP-galactose:beta-N-acetylglucosamine_beta-1,3-galactosyltransferase_activity
        my @parts = split(":", $item, 3);
        my $go_term = "$parts[0]:$parts[1]";
        my $go_description = $parts[2];
        $item_url = $hub->get_ExtURL_link($go_term, 'GO', $go_term) . " $go_description";
      }
      else {
        foreach my $label (keys(%PROTEIN_DOMAIN_LABELS)) {
          if ($item =~ /^$label:(.+)$/) {
            $item_url = "$label:&nbsp;".$hub->get_ExtURL_link($1, $PROTEIN_DOMAIN_LABELS{$label}, $1);
            last;
          }
        }
      }
      push(@items_with_url, $item_url);
    }
  }

  if (scalar @items_list > $min_items_count) {
    my $div_id = 'row_'.$row_id.'_'.$type;
    return display_items_list($div_id, $type, $label, \@items_with_url, \@items_list);
  }
  else {
    return join('<br />',@items_with_url);
  }
}

sub render_protein_matches {
  my (
    $self,
    $row_data,
    $row_id,
    $gene_id,
    $feature_id,
    $consequence,
    $species
  ) = @_;

  my $hub = $self->hub;
  my $domain_ids = $row_data->{'DOMAINS'};

  my $should_add_pdb_view_button = $domain_ids =~ /PDB-ENSP/i;
  # we are currently only comfortable with showing the alphafold view only in case of missense variants
  ## ParaSite: change prefix
  my $should_add_afdb_view_button = $domain_ids =~ /AlphaFold_DB_import/i && $consequence =~ /missense_variant/i;
  ##
  my $should_add_protein_view_buttons = $should_add_pdb_view_button || $should_add_afdb_view_button;

  my $rendered_protein_matches = $self->get_items_in_list($row_id, 'domains', 'Protein matches', $domain_ids, $species);

  if (!$should_add_protein_view_buttons) {
    $row_data->{'DOMAINS'} = $rendered_protein_matches;
    return;
  }

  my $db_adaptor  = $hub->database('core');
  my $adaptor     = $db_adaptor->get_TranscriptAdaptor;
  my $transcript  = $adaptor->fetch_by_stable_id($feature_id);
  my $safe_transcript_id = $transcript ? $transcript->stable_id : $feature_id;

  my $pdb_structure_button = '';
  my $afdb_structure_button = '';

  if ($should_add_pdb_view_button) {
    my $url = $hub->url({
      type    => 'Tools',
      action  => 'VEP/PDB',
      var     => $row_data->{'ID'},
      pos     => $row_data->{'Protein_position'},
      cons    => $consequence,
      g       => $gene_id,
      t       => $safe_transcript_id,
      species => $species
    });

    $pdb_structure_button = qq{<div class="in-table-button"><a href="$url">Protein Structure View</a></div>};
  }

  if ($should_add_afdb_view_button) {
    my $url = $hub->url({
      type    => 'Tools',
      action  => 'VEP/AFDB',
      var     => $row_data->{'ID'},
      pos     => $row_data->{'Protein_position'},
      cons    => $consequence,
      g       => $gene_id,
      t       => $safe_transcript_id,
      species => $species
    });

    $afdb_structure_button = qq{<div class="in-table-button"><a href="$url">Alphafold model</a></div>};
  }

  $row_data->{'DOMAINS'} = $pdb_structure_button . $afdb_structure_button . $rendered_protein_matches;
}

1;
