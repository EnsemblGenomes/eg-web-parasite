package EnsEMBL::Web::JobDispatcher::NcbiBlast;

use strict;

my $DEBUG = 0;

sub update_jobs {
  my ($self, $jobs) = @_;

  for my $job (@$jobs) {
    my $job_ref  = $job->dispatcher_reference;
    my $job_data = $job->dispatcher_data;
    my $status   = $self->_get('status', [ $job_ref ])->content;

    if ($status eq 'RUNNING') {

      $job->dispatcher_status('running') if $job->dispatcher_status ne 'running';

    } elsif ($status eq 'FINISHED') {

      $DEBUG && warn "UPDATE JOB DATA " . Dumper $job_data;

      eval {
        # fetch and process the output
        my $out_file = $job_data->{work_dir} . '/blast.out';
        my $xml_file = $job_data->{work_dir} . '/blast.xml';

        my $text = $self->_get('result', [ $job_ref, 'out' ])->content;
        file_put_contents($out_file, $text);

        my $xml = $self->_get('result', [ $job_ref, 'xml' ])->content;
        file_put_contents($xml_file, $xml);

        my $parser   = EnsEMBL::Web::Parsers::Blast->new($self->hub);
        my $hits     = $parser->parse_xml($xml, $job_data->{species}, $job_data->{source});
        my $now      = parse_date('now');
        my $orm_hits = [ map { {result_data => $_ || {}, created_at => $now } } @$hits ];

        $job->result($orm_hits);
        $job->status('done');
        $job->dispatcher_status('done');
      };

      $self->_fatal_job($job, $@, $self->default_error_message) if $@

    } elsif ($status =~ '^FAILED|FAILURE$') {

      my $error = $self->_get('result', [ $job_ref, 'error' ])->content;
      $self->_fatal_job($job, $error, $self->default_error_message);

    } elsif ($status eq 'NOT_FOUND') {

      $self->_fatal_job($job, $status, $self->default_error_message);

    } elsif ($status eq 'ERROR') {

      $job->job_message([{
        'display_message' => 'Error while trying to check job status',
        'fatal'           => 0
      }]);

    }

    $job->save('changes_only' => 1);
  }
}

1;

