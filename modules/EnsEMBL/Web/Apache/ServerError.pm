package EnsEMBL::Web::Apache::ServerError;

use strict;
use warnings;

use Sys::Hostname;

sub handler {
  ## Handles 500 errors (via /Crash) and internal exceptions (called by EnsEMBL::Web::Apache::Handlers)
  ## @param Apache2::RequestRec request object
  ## @param EnsEMBL::Web::SpeciesDefs object (only when called by EnsEMBL::Web::Apache::Handlers)
  ## @param EnsEMBL::Web::Exception object (only when called by EnsEMBL::Web::Apache::Handlers)
  my ($r, $species_defs, $exception) = @_;

  my ($content, $content_type);

  my $heading = '500 Server Error';
  my $message = 'An unknown error has occurred';
  my $stack   = '';

  try {

    if ($exception) {
## ParaSite: also include the machine name, so we know which server this error relates to
      (my $hostname = hostname) =~ s/\.ebi\.ac\.uk$//;
      my $error_id  = $hostname . "_" . random_string(8);
##
      $heading      = sprintf 'Server Exception: %s', $exception->type;
## ParaSite: custom error
      $message      = sprintf(q(There was a problem with our website. Please report this issue to %s, quoting error reference '%s' and a brief explanation of how you navigated to this page.), $species_defs->ENSEMBL_HELPDESK_EMAIL, $error_id);
##

      warn "ERROR: $error_id (Server Exception)\n";
      warn $exception;
    }

    my $template = dynamic_require(get_template($r))->new({
      'species_defs'  => $species_defs,
      'heading'       => $heading,
      'message'       => $message,
      'helpdesk'      => 1,
      'back_button'   => 1
    });

    $content_type = $template->content_type;
    $content      = $template->render;

  } catch {
    warn $_;
    $content_type = 'text/plain; charset=utf-8';
    $content      = "$heading\n\n$message\n\n$stack";
  };

  $r->status(Apache2::Const::SERVER_ERROR);
  $r->content_type($content_type) if $content_type;
  $r->print($content);

  return undef;
}

1;
