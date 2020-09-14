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

package EnsEMBL::Web::Template::Legacy;

use strict;

sub render_masthead {
  my ($self, $elements) = @_;
  my $hub = $self->hub;
  my $page = $self->page;

## ParaSite - layout changes
  my $tabs        = $elements->{'tabs'} ? qq(<div id="mh-tabs"><div class="tabs_holder print_hide">$elements->{'tabs'}</div></div>) : '';
  ## MASTHEAD & GLOBAL NAVIGATION
  return qq(
  <div id="min_width_container">
    <div id="min_width_holder">

     <!-- Announcement Banner -->    
        $elements->{'tmp_message'}->{'announcement_banner_message'}
    <!-- /Announcement Banner -->

      <div class="js_panel">
        <input type="hidden" class="panel_type" value="Masthead" />
        <div id="masthead">
          <div class="logo_holder">$elements->{'logo'}</div>
          <div class="mh print_hide">
            <div class="search_holder print_hide">$elements->{'search_box'}</div>
          </div>
        </div>
        <div id="masthead-menu">
          <div class="mh-tools print_hide">
            <div class="mh_tools_holder">$elements->{'tools'}</div>
          </div>
        </div>
        $tabs
      </div>
  );
##
}

sub render_footer {
  my ($self, $elements) = @_;
  my $hub = $self->hub;
  my $page = $self->page;

  my $footer_id = $self->{'lefthand_menu'} ? 'footer' : 'wide-footer';
## ParaSite
  return qq(
        <div id="$footer_id">
          <div class="column-wrapper">$elements->{'copyright'}$elements->{'footerlinks'}
            <p class="invisible">.</p>
          </div>
        </div>
  );
##
}

sub render_content {
  my ($self, $elements) = @_;
  my $hub = $self->hub;
  my $page = $self->page;

  ## LOCAL NAVIGATION & MAIN CONTENT

  my $icons       = $page->icon_bar if $page->can('icon_bar');
  my $panel_type  = $page->can('panel_type') ? $page->panel_type : '';
  my $main_holder = $panel_type ? qq(<div id="main_holder" class="js_panel">$panel_type) : '<div id="main_holder">';
  my $main_class  = $self->{'main_class'};

  my $nav;
  my $nav_class   = $page->isa('EnsEMBL::Web::Document::Page::Configurator') ? 'cp_nav' : 'nav';
  if ($self->{'lefthand_menu'}) {
    $nav = qq(
      <div id="page_nav_wrapper">
        <div id="page_nav" class="$nav_class print_hide js_panel floating">
          $elements->{'navigation'}
          $elements->{'tool_buttons'}
          $elements->{'acknowledgements'}
          <p class="invisible">.</p>
        </div>
      </div>
    );
  }

## ParaSite
  return qq(

      $main_holder
      $nav

      <div id="$main_class">
          $elements->{'breadcrumbs'}
          $elements->{'message'}
          $elements->{'content'}
          $elements->{'mobile_nav'}
      </div>
  );
##
}

1;
