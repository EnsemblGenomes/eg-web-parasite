=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Apache::Handlers;

sub handler {
  my $r = shift; # Get the connection handler

  $ENSEMBL_WEB_REGISTRY->timer->set_name('REQUEST ' . $r->uri);

  my $u           = $r->parsed_uri;
  my $file        = $u->path;
  my $querystring = $u->query;
  my @web_cookies = EnsEMBL::Web::Cookie->retrieve($r, map {'name' => $_, 'encrypted' => 1}, $SiteDefs::ENSEMBL_SESSION_COOKIE, $SiteDefs::ENSEMBL_USER_COOKIE);
  my $cookies     = {
    'session_cookie'  => $web_cookies[0] || EnsEMBL::Web::Cookie->new($r, {'name' => $SiteDefs::ENSEMBL_SESSION_COOKIE, 'encrypted' => 1}),
    'user_cookie'     => $web_cookies[1] || EnsEMBL::Web::Cookie->new($r, {'name' => $SiteDefs::ENSEMBL_USER_COOKIE,    'encrypted' => 1})
  };

  my @raw_path = split '/', $file;
  shift @raw_path; # Always empty

## ParaSite: redirect WormBase species out to WormBase
  my $sp = $raw_path[0];
  my %param = split ';|=', $querystring;
  my $site_type = $species_defs->ENSEMBL_SPECIES_SITE->{lc($sp)};
  if($site_type !~ /^parasite|wormbase$/i) {
    my $redirect_url;
    if($raw_path[1] eq 'Gene') {
      $redirect_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_GENE"};
      $redirect_url =~ s/###SPECIES###/$sp/;
      $redirect_url =~ s/###ID###/$param{'g'}/;
    } elsif ($raw_path[1] eq 'Transcript') {
      $redirect_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_TRANSCRIPT"};
      $redirect_url =~ s/###SPECIES###/$sp/;
      $redirect_url =~ s/###ID###/$param{'t'}/;
    } elsif ($raw_path[1] eq 'Info' || !$raw_path[1]) {
      $redirect_url = $site_type eq 'WORMBASE' ? $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($sp) . "_URL"} : $species_defs->ENSEMBL_EXTERNAL_URLS->{uc($site_type) . "_SPECIES"};
      $redirect_url =~ s/###SPECIES###/$sp/;
    }
    if($redirect_url) {
      $r->headers_out->add('Location' => $redirect_url);
      $r->child_terminate;
      $ENSEMBL_WEB_REGISTRY->timer_push('Handler "REDIRECT"', undef, 'Apache');
      return HTTP_MOVED_PERMANENTLY;
    }
  }
##

  my $redirect = 0;
  ## Redirect to contact form
  if (scalar(@raw_path) == 1 && $raw_path[0] =~ /^contact$/i) {
    $r->uri('/Help/Contact');
    $redirect = 1;
  }

  ## Fix URL for V/SV Explore pages
  if ($raw_path[1] =~ /Variation/ && $raw_path[2] eq 'Summary') {
    $file =~ s/Summary/Explore/;
    $file .= '?'.$querystring if $querystring;
    $r->uri($file);
    $redirect = 1;
  }

  ## Redirect to blog from /jobs
  if ($raw_path[0] eq 'jobs') {
    $r->uri('http://www.ensembl.info/blog/category/jobs/');
    $redirect = 1;
  }

  ## Fix for moved eHive documentation
  if ($file =~ /info\/docs\/eHive\//) {
    $r->uri('/info/docs/eHive.html');
    $redirect = 1;
  }

  ## ParaSite: redirect the old species list which has appeared in some publications
  if ($file =~ /info\/website\/species\.html/) {
    $r->uri('/species.html');
    $redirect = 1;
  }
  ##

  ## Simple redirect to VEP

  if ($SiteDefs::ENSEMBL_SUBTYPE eq 'Pre' && $file =~ /\/vep/i) { ## Pre has no VEP, so redirect to tools page
    $r->uri('/info/docs/tools/index.html');
    $redirect = 1;
  } elsif ($file =~ /\/info\/docs\/variation\/vep\/vep_script.html/) {
    $r->uri('/info/docs/tools/vep/script/index.html');
    $redirect = 1;
  } elsif (($raw_path[0] && $raw_path[0] =~ /^VEP$/i) || $file =~ /\/info\/docs\/variation\/vep\//) {
    $r->uri('/info/docs/tools/vep/index.html');
    $redirect = 1;
  }

  if ($redirect) {
    $r->headers_out->add('Location' => $r->uri);
    $r->child_terminate;

    $ENSEMBL_WEB_REGISTRY->timer_push('Handler "REDIRECT"', undef, 'Apache');

    return HTTP_MOVED_PERMANENTLY;
  }

  my $aliases = $species_defs->multi_val('SPECIES_ALIASES') || {};
  my %species_map = (
    %$aliases,
    common => 'common',
    multi  => 'Multi',
    map { lc($_) => $SiteDefs::ENSEMBL_SPECIES_ALIASES->{$_} } keys %$SiteDefs::ENSEMBL_SPECIES_ALIASES
  );

  $species_map{lc $_} = $_ for values %species_map; # Self-mapping

## EG MULTI 
  foreach ($species_defs->valid_species) {
    $species_map{lc($_)} = $_;
  }
##

  ## Identify the species element, if any
  my ($species, @path_segments);

  ## Check for stable id URL (/id/ENSG000000nnnnnn) 
  ## and malformed Gene/Summary URLs from external users
  if (($raw_path[0] && $raw_path[0] =~ /^id$/i && $raw_path[1]) || ($raw_path[0] eq 'Gene' && $querystring =~ /g=/ )) {
    my ($stable_id, $object_type, $db_type, $retired, $uri);

    if ($raw_path[0] =~ /^id$/i) {
      $stable_id = $raw_path[1];
    } else {
      $querystring =~ /g=(\w+)/;
      $stable_id = $1;
    }

    my $unstripped_stable_id = $stable_id;

    $stable_id =~ s/\.[0-9]+$// if $stable_id =~ /^ENS/; ## Remove versioning for Ensembl ids

    ## Try to register stable_id adaptor so we can use that db (faster lookup)
    my %db = %{$species_defs->multidb->{'DATABASE_STABLE_IDS'} || {}};

    if (keys %db) {
      my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
        -species => 'multi',
        -group   => 'stable_ids',
        -host    => $db{'HOST'},
        -port    => $db{'PORT'},
        -user    => $db{'USER'},
        -pass    => $db{'PASS'},
        -dbname  => $db{'NAME'}
      );
    }

    ($species, $object_type, $db_type, $retired) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id, undef, undef, undef, undef, 1);

    if (!$species || !$object_type) {
      ($species, $object_type, $db_type, $retired) = Bio::EnsEMBL::Registry->get_species_and_object_type($unstripped_stable_id, undef, undef, undef, undef, 1);
      $stable_id = $unstripped_stable_id if($species && $object_type);
    }

    if ($object_type) {
      $uri = $species ? "/$species/" : '/Multi/';

      if ($object_type eq 'Gene') {
        $uri .= sprintf 'Gene/%s?g=%s', $retired ? 'Idhistory' : 'Summary', $stable_id;
      } elsif ($object_type eq 'Transcript') {
        $uri .= sprintf 'Transcript/%s?t=%s',$retired ? 'Idhistory' : 'Summary', $stable_id;
      } elsif ($object_type eq 'Translation') {
        $uri .= sprintf 'Transcript/%s?t=%s', $retired ? 'Idhistory/Protein' : 'ProteinSummary', $stable_id;
      } elsif ($object_type eq 'GeneTree') {
        $uri = "/Multi/GeneTree/Image?gt=$stable_id"; # no history page!
      } elsif ($object_type eq 'Family') {
        $uri = "/Multi/Family/Details?fm=$stable_id"; # no history page!
      } else {
        $uri .= "psychic?q=$stable_id";
      }
    }

    $uri ||= "/Multi/psychic?q=$stable_id";

    $r->uri($uri);
    $r->headers_out->add('Location' => $r->uri);
    $r->child_terminate;

    $ENSEMBL_WEB_REGISTRY->timer_push('Handler "REDIRECT"', undef, 'Apache');

    return HTTP_MOVED_PERMANENTLY;
  }

  my %lookup = map { $_ => 1 } $species_defs->valid_species;
  my $lookup_args = {
    sd     => $species_defs,
    map    => \%species_map,
    lookup => \%lookup,
    uri    => $r->unparsed_uri,
  };

  foreach (@raw_path) {
    $lookup_args->{'dir'} = $_;

    my $check = _check_species($lookup_args);

    if ($check && $check =~ /^http/) {
      $r->headers_out->set( Location => $check );
      return REDIRECT;
    } elsif ($check && !$species) {
      $species = $_;
    } else {
      push @path_segments, $_;
    }
  }

  if (!$species) {
    if (grep /$raw_path[0]/, qw(Multi das common default)) {
      $species = $raw_path[0];
      shift @path_segments;
    } elsif ($path_segments[0] eq 'Gene' && $querystring) {
      my %param = split ';|=', $querystring;

      if (my $gene_stable_id = $param{'g'}) {
        my ($id_species) = Bio::EnsEMBL::Registry->get_species_and_object_type($gene_stable_id);
            $species     = $id_species if $id_species;
      }
    }
  }

  @path_segments = @raw_path unless $species;

  # Some memcached tags (mainly for statistics)
  my $prefix = '';
  my @tags   = map { $prefix = join '/', $prefix, $_; $prefix; } @path_segments;

  if ($species) {
    @tags = map {( "/$species$_", $_ )} @tags;
    push @tags, "/$species";
  }

  $ENV{'CACHE_TAGS'}{$_} = $_ for @tags;

  my $Tspecies  = $species;
  my $script    = undef;
  my $path_info = undef;
  my $species_name = $species_map{lc $species};
  my $return;

  if (!$species && $raw_path[-1] !~ /\./) {
    $species      = 'common';
    $species_name = 'common';
    $file         = "/common$file";
    $file         =~ s|/$||;
  }

  if ($raw_path[0] eq 'das') {
    my ($das_species) = split /\./, $path_segments[0];

    $return = EnsEMBL::Web::Apache::DasHandler::handler_das($r, $cookies, $species_map{lc $das_species}, \@path_segments, $querystring);

    $ENSEMBL_WEB_REGISTRY->timer_push('Handler for DAS scripts finished', undef, 'Apache');
  } elsif ($species && $species_name) { # species script
    $return = EnsEMBL::Web::Apache::SpeciesHandler::handler_species($r, $cookies, $species_name, \@path_segments, $querystring, $file, $species_name eq $species);

    $ENSEMBL_WEB_REGISTRY->timer_push('Handler for species scripts finished', undef, 'Apache');
    shift @path_segments;
    shift @path_segments;
  }

  if (defined $return) {
    if ($return == OK) {
      push_script_line($r) if $SiteDefs::ENSEMBL_DEBUG_FLAGS & $SiteDefs::ENSEMBL_DEBUG_HANDLER_ERRORS;

      $r->push_handlers(PerlCleanupHandler => \&cleanupHandler_script);
      $r->push_handlers(PerlCleanupHandler => \&Apache2::SizeLimit::handler);
    }

    return $return;
  }

  $species = $Tspecies;
  $script = join '/', @path_segments;

  # Permanent redirect for old species home pages:
  # e.g. /Homo_sapiens or Homo_sapiens/index.html -> /Homo_sapiens/Info/Index  
  if ($species && $species_name && (!$script || $script eq 'index.html')) {
    my $species_uri = redirect_species_page($species_name); #move to separate function so that it can be overwritten in mobile plugin

    $r->uri($species_uri);
    $r->headers_out->add('Location' => $r->uri);
    $r->child_terminate;
    $ENSEMBL_WEB_REGISTRY->timer_push('Handler "REDIRECT"', undef, 'Apache');

    return HTTP_MOVED_PERMANENTLY;
  }

  #commenting this line out because we do want biomart to redirect. If this is causing problem put it back.
  #return DECLINED if $species eq 'biomart' && $script =~ /^mart(service|results|view)/;

  my $path = join '/', $species || (), $script || (), $path_info || ();

  $r->uri("/$path");

  my $filename = get_static_file_for_path($r, $path);

## ParaSite: do not force a redirect to index.html on the homepage
  if ($filename =~ /^! (.*)$/ && $path eq '') {
    $path = 'index.html';
    $filename = get_static_file_for_path($r, $path);
  } elsif($filename =~ /^! (.*)$/) {
    $r->uri($r->uri . ($r->uri      =~ /\/$/ ? '' : '/') . 'index.html');
    $r->filename($1 . ($r->filename =~ /\/$/ ? '' : '/') . 'index.html');
    $r->headers_out->add('Location' => $r->uri);
    $r->child_terminate;
    $ENSEMBL_WEB_REGISTRY->timer_push('Handler "REDIRECT"', undef, 'Apache');
    return HTTP_MOVED_TEMPORARILY
  }

  if ($filename) {
    $r->filename($filename);
    $r->content_type('text/html');
    $ENSEMBL_WEB_REGISTRY->timer_push('Handler "OK"', undef, 'Apache');

    EnsEMBL::Web::Apache::SSI::handler($r, $cookies);

    return OK;
  }
## ParaSite

  # Give up
  $ENSEMBL_WEB_REGISTRY->timer_push('Handler "DECLINED"', undef, 'Apache');

  return DECLINED;
}

sub _check_species {
## Do this in a private function so it's more easily pluggable, e.g. on Pre!
## This default version just checks if this is a valid species for the site
  my $args = shift;
  return $args->{'lookup'}{$args->{'map'}{lc $args->{'dir'}}};
}

sub logHandler {
  my $r = shift;
  my $T = time;

  $r->subprocess_env->{'ENSEMBL_CHILD_COUNT'}  = $ENSEMBL_WEB_REGISTRY->timer->get_process_child_count;
  $r->subprocess_env->{'ENSEMBL_SCRIPT_START'} = sprintf '%0.6f', $T;
  $r->subprocess_env->{'ENSEMBL_SCRIPT_END'}   = sprintf '%0.6f', $ENSEMBL_WEB_REGISTRY->timer->get_script_start_time;
  $r->subprocess_env->{'ENSEMBL_SCRIPT_TIME'}  = sprintf '%0.6f', $T - $ENSEMBL_WEB_REGISTRY->timer->get_script_start_time;

  return DECLINED;
}

1;
