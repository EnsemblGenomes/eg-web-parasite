=head1 LICENSE

Copyright [2014-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::WordPress;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP;
use URI;
use Net::SSL;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use EnsEMBL::Web::RegObj;
use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my ($class, $request) = @_;

  my $debug = 0;

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;

  $ENV{HTTPS_PROXY} = $species_defs->ENSEMBL_WWW_PROXY;
  my $ua = LWP::UserAgent->new(
    ssl_opts => { verify_hostname => 0 },
  );
  $ua->agent('ParaSite Web ' . $ua->agent());
  $ua->env_proxy;
  $ua->proxy(['http', 'https'], $species_defs->ENSEMBL_WWW_PROXY);
  $ua->timeout(10);
  
  my $URL = 'https://public-api.wordpress.com/rest/v1.1/sites/wbparasite.wordpress.com/posts/?number=5';

  my $req = HTTP::Request->new('GET', $URL);
  
  my $response = $ua->request($req);
  my $content  = $response->content;
  
  if ($response->is_error) {
    warn 'WormBase blog error: ' . $response->status_line;
    return '';
  }
  
  $debug && warn "Response " . $content;
  my $output = from_json($content);
  
  # Render the posts
  my $html;

  # Put the 'sticky' posts at the top
  $html .= qq(<div class="blog-story round-box home-box"><h2 data-generic-icon="U">Announcements</h2>);
  foreach my $post (@{$output->{'posts'}}) {
    next if $post->{'tags'}->{'Hidden'};
    next unless $post->{'sticky'};
    $html .= print_post($post);
  }
  $html .= qq(</div>);

  # Then everything else
  $html .= qq(<div class="blog-story round-box home-box"><h2 data-social-icon="R">Blog</h2>);
  foreach my $post (@{$output->{'posts'}}) {
    next if $post->{'tags'}->{'Hidden'};
    next if $post->{'sticky'};
    $html .= print_post($post);
  }
  $html .= qq(<p><a class="blog-link" href="http://wbparasite.wordpress.com" rel="notexternal">[Older]</a></p>);
  $html .= qq(</div>);
  
  return $html;

}

sub print_post {
  my ($post) = @_;
  my $html;
  my $date = DateTime::Format::ISO8601->parse_datetime($post->{'date'});
  my $diff = DateTime->now->subtract_datetime_absolute($date);

  my $date_formatted = $date->strftime('%d/%m/%Y %H:%M');

  my $date_pretty;
  if($diff->seconds < 60) { # < 1 min
    $date_pretty = "just a moment ago";
  } elsif ($diff->seconds < 3600) { # < 1 hour
    my $mins = int (($diff->seconds)/60);
    $date_pretty = $mins == 1 ? "$mins minute ago" : "$mins minutes ago";
  } elsif ($diff->seconds < 86400) { # < 24 hours
    my $hours = int (($diff->seconds)/60/60);
    $date_pretty = $hours == 1 ? "$hours hour ago" : "$hours hours ago";
  } elsif ($diff->seconds < 2678400) { # < 31 days
    my $days = int (($diff->seconds)/60/60/24);
    $date_pretty = $days == 1 ? "$days day ago" : "$days days ago";
  } elsif ($diff->seconds < 31536000) { # < 1 year
    my $months = DateTime->now->delta_md($date)->delta_months(); # Have to calculate the months differently as the length varies
    $date_pretty = $months == 1 ? "$months month ago" : "$months months ago";
  } elsif ($diff->seconds >= 31536000) { # > 1 year
    my $years = int (($diff->seconds)/60/60/24/365);
    $date_pretty = $years == 1 ? "$years year ago" : "$years years ago";
  } else { # Catch anything that slipped through the time filters
    $date_pretty = "on $date_formatted";
  }

  $html .= qq(<h3><a class="blog-link" rel="notexternal" href="$post->{'URL'}">$post->{'title'}</a></h3>);
  $html .= qq(<h4 title="$date_formatted">posted $date_pretty</h4>);
  $post->{'excerpt'} =~ s/<[\/]*p>//g;
  $post->{'excerpt'} =~ s/\[\&hellip;\]/<a rel="notexternal" href="$post->{'URL'}">\[\x{2026}\]<\/a>/g;
  $html .= qq(<p>$post->{'excerpt'}</p>);
  return $html;
}

1;

