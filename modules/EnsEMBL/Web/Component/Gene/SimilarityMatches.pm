=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::SimilarityMatches;

use strict;

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self       = shift;
  my @dbtypes   = qw(MISC LIT);
  my $matches    = $self->_matches('similarity_matches', 'Similarity Matches', 'PRIMARY_DB_SYNONYM', @dbtypes, 'RenderAsTables');
  my $no_matches = qq();
  my $html       = $matches ? $matches : $no_matches;
  $html         .= $self->matches_to_html(@dbtypes);
  return $html;
}

sub matches_to_html {
  my $self           = shift;
  my @dbtypes          = @_;
  my $hub            = $self->hub;
  my $count_ext_refs = 0;
  my $table          = $self->new_table([], [], { data_table => 'no_col_toggle', sorting => [ 'transcriptid asc' ], exportable => 1 });
  my (%existing_display_names, @rows, $html);

  my @columns = ({
    key        => 'transcriptid' ,
    title      => 'Transcript ID',
    align      => 'left',
    sort       => 'string',
    priority   => 2147483647, # Give transcriptid the highest priority as we want it to be the 1st colum
    display_id => '',
    link_text  => ''
  });

  my %options = map { $_ => 1 } $self->view_config->options;
  
  foreach (@{$self->object->Obj->get_all_Transcripts}) {
    my $url = sprintf '<a href="%s">%s</a>', $hub->url({ type => 'Transcript', action => 'Summary', function => undef, t => $_->stable_id }), $_->stable_id;
    my $row = { transcriptid => $url };

    foreach ($self->get_matches_by_transcript($_, @dbtypes)) {

      #switch off rows that should be off
      next unless $options{$_->db_display_name} && $hub->param($_->db_display_name) ne 'off';

      my %similarity_links = $self->get_similarity_links_hash($_);
      my $ext_db_entry     = $similarity_links{'link'} ? qq{<a href="$similarity_links{'link'}">$similarity_links{'link_text'}</a>}  : $similarity_links{'link_text'};
      $row->{$_->db_display_name} .= ' ' if defined $row->{$_->db_display_name};
      $row->{$_->db_display_name} .= $ext_db_entry;
      $count_ext_refs++;

      if (!defined $existing_display_names{$_->db_display_name}) {
        push @columns, {
          key        => $_->db_display_name, 
          title      => $self->format_column_header($_->db_display_name),
          align      => 'left', 
          sort       => 'string', 
          priority   => $_->priority, 
          display_id => $_->display_id, 
          link_text  => $similarity_links{'link_text'}
        };
        $existing_display_names{$_->db_display_name} = 1;
      }
    }
    push @rows, $row if (1 < keys %$row);
  }
  @columns = sort { $b->{'priority'} <=> $a->{'priority'} || $a->{'title'} cmp $b->{'title'} || $a->{'link_text'} cmp $b->{'link_text'} } @columns;
  #@columns = sort { default_on($a) <=> default_on($b) || $a->{'title'} cmp $b->{'title'}} @columns;
  @rows    = sort { keys %{$b} <=> keys %{$a} } @rows; # show rows with the most information first

  $table->add_columns(@columns);
  $table->add_rows(@rows);

  if ($count_ext_refs == 0) {
    $html.= '<p>No external database contains identifiers which correspond to the transcripts of this gene.</p>';
  } else {
    $html .= '<p><strong>The following database identifier' . ($count_ext_refs > 1 ? 's' : '') . ' correspond' . ($count_ext_refs > 1 ? '' : 's') . ' to the transcripts of this gene:</strong></p>';
    $html .= $table->render;
  }

  return $html;
}

1;
