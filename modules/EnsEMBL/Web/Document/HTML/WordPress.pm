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

package EnsEMBL::Web::Document::HTML::WordPress;

use strict;
use warnings;

use EnsEMBL::LWP_UserAgent;
use JSON;
use URI;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use POSIX qw(strftime);
use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Document::HTML);
use parent qw(EnsEMBL::Web::Document::FileCache);

sub render {
  my $self = shift;
  return $self->read_html($SiteDefs::BLOG_REFRESH_RATE);
}

sub make_html {
  my ($self, $request) = @_;
  my $debug = 0;

  my $species_defs = EnsEMBL::Web::SpeciesDefs->new();

  # Render the posts
  my $html;

  # Put announcement posts at the top. Max 2 posts.
  my $announce_posts = get_wordpress_posts("number=2&category=web-announcements");
  if (!defined $announce_posts) {
  # Deal with Wordpress API problem
    return qq(<div class="blog-story round-box home-box"><h2 data-generic-icon="U">Announcements</h2><h3>There is an error accessing our Wordpress blog</h3> <br></div>);
  }
  
  my $announce_html;
  my $announce_count = 0;
  foreach my $post (@{$announce_posts->{'posts'}}) {
    next if $post->{'tags'}->{'Hidden'};
    next unless $post->{'sticky'};
    $announce_html .= print_post($post);
    $announce_count++;
  }
  $html .= sprintf(qq(<div class="blog-story round-box home-box"><h2 data-generic-icon="U">Announcements</h2>%s</div>), $announce_html) if $announce_count > 0;
  
  # Put meeting posts at the second panel. Sorted by priority tag, then in date tag (priority tag: pr-\d+ . date tag: date-yyyymmdd). Max 3 posts.
  my $meeting_posts = get_wordpress_posts("category=meeting-announcements");
  my $current_date_tag = strftime 'date-%Y%m%d', gmtime();
  my @upcoming_meetings;
  my @upcoming_meetings_sorted;
  

  foreach my $post (@{$meeting_posts->{'posts'}}) {
    my $priotity_tag = 0;
    next if $post->{'tags'}->{'Hidden'};

    for my $post_tag (keys %{$post->{'tags'}}) {
      if ($post_tag =~ /pr-(\d+)/) {
        $priotity_tag = $1;
      }      
    }

    for my $post_tag (keys %{$post->{'tags'}}) {
      if ($post_tag =~ /date-\d{8}/ && $post_tag ge $current_date_tag) {
        $post->{'meeting_date_tag'} = $post_tag;
        $post->{'priority_tag'} = $priotity_tag;
        push @upcoming_meetings, $post; 
      }
    }         
  }

  @upcoming_meetings_sorted = sort {
    $b->{'priority_tag'} <=> $a->{'priority_tag'} ||
    $a->{'meeting_date_tag'} cmp $b->{'meeting_date_tag'} } @upcoming_meetings;

  if (scalar @upcoming_meetings_sorted > 0) {
    $html .= qq(<div class="blog-story round-box home-box"><h2 data-generic-icon="4">Meetings</h2>);
    my $meeting_count = 0;
    foreach my $post (@upcoming_meetings_sorted) {
      #warn "Tag date is: " . $post->{'meeting_date_tag'} . " Priority tag is: " . $post->{'priority_tag'};
      $meeting_count++;
      last if $meeting_count > 3;
      $html .= print_post($post);
            
    }
    $html .= qq(</div>);
  }


  # Put normal uncategorized blog posts (including sticky posts) at the bottom. Max 4 posts.
  my @blog_posts;
  my $sticky_posts = get_wordpress_posts("number=2&category=uncategorized&sticky=require");
  my $normal_posts = get_wordpress_posts("number=2&category=uncategorized&sticky=exclude");

  unshift @blog_posts, @{$normal_posts->{'posts'}};
  unshift @blog_posts, @{$sticky_posts->{'posts'}};

  $html .= qq(<div class="blog-story round-box home-box"><h2 data-social-icon="R">Blog</h2>);
  foreach my $post (@blog_posts) {
    next if $post->{'tags'}->{'Hidden'};
    $html .= print_post($post);
  }
  $html .= qq(<p><a class="blog-link" href="http://wbparasite.wordpress.com" rel="notexternal">[Older]</a></p>);
  $html .= qq(</div>);
  
  return $html;

}


sub get_wordpress_posts {
  my ($params) = @_;

  my $url = "https://public-api.wordpress.com/rest/v1.1/sites/wbparasite.wordpress.com/posts/?$params";
  my $uri = URI->new($url);

  my $response = EnsEMBL::LWP_UserAgent->user_agent->get($uri->as_string);
  my $content  = $response->content;

  if ($response->is_error) {
    warn 'WormBase blog error: ' . $response->status_line;
    return;
  }

  return from_json($content);
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
  $html .= qq(<h4><span title="$date_formatted">posted $date_pretty</span> by <a href="https://wbparasite.wordpress.com/author/$post->{'author'}->{'nice_name'}/" rel="notexternal">$post->{'author'}->{'name'}</a></h4>);
  $post->{'excerpt'} =~ s/<[\/]*p>//g;
  $post->{'excerpt'} =~ s/\[\&hellip;\]/<a rel="notexternal" href="$post->{'URL'}">\[read&nbsp;more\]<\/a>/g;
  $html .= qq(<p>$post->{'excerpt'}</p>);
  return $html;
}

1;

