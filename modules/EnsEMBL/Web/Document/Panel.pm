package EnsEMBL::Web::Document::Panel;

use previous qw(component_content);

sub component_content {
  my $self    = shift;

## ParaSite: Use the EG/Ensembl version of this if 'SinglePage' is not defined
  my $singlepage = 0;
  my $html;
  foreach my $entry (map @{$self->{'components'}->{$_} || []}, $self->components) {
    $singlepage = 1 if $entry =~ /SinglePage/;
  }
  if($singlepage == 0) {
    $html = $self->PREV::component_content(@_);
  } else {
    $html = $self->component_content_singlepage;
  }
  return $html;
## ParaSite
}

## This has been adapted from component_content, but modified to support all the components on a single page
sub component_content_singlepage {
  my $self    = shift;
  my $html    = $self->{'content'};
  my $builder = $self->{'builder'};
  my $hub     = $self->hub;

  return $html unless $builder;
  return $self->das_content if $self->{'components'}->{'das_features'};
  return $html unless scalar keys %{$self->{'components'}};

  my $modal        = $self->renderer->{'_modal_dialog_'};
  my $ajax_request = $self->_is_ajax_request;
  my $base_url     = $hub->species_defs->ENSEMBL_BASE_URL;
  my $function     = $hub->function;
  my $is_html      = ($hub->param('_format') || 'HTML') eq 'HTML';
  my $table_count  = 0;
  
  foreach my $component_name ($self->components) {
    my $entry = @{$self->{'components'}->{$component_name}}[0];
    next unless $entry;
    my ($module_name, $content_function) = split /\//, $entry;
    my $component;
    
    next if $module_name =~ /SinglePage/;  ## ParaSite mod
    
    ### Attempt to require the Component module
    if ($self->dynamic_use($module_name)) {
      eval {
        $component = $module_name->new($hub, $builder, $self->renderer);
      };

      if ($@) {
        $html .= $self->component_failure($@, $entry, $module_name);
        next;
      }
    } else {
      $html .= $self->component_failure($self->dynamic_use_failure($module_name), $entry, $module_name);
      next;
    }

    ### If this component is configured to be loaded by an AJAX request, print just the div which the content will be loaded into
    my $ajaxable = $component->ajaxable;
    if ($ajaxable && !$ajax_request && $is_html) {

      my $url   = encode_entities($component->ajax_url($content_function)),
      my $class = 'initial_panel' . ($component->has_image == 1 ? ' image_panel' : ''); # classes required by the javascript

      # Safari requires a unique name on inputs when using browser-cached content (eq when the user presses the back button)
      # $panel_name is the memory location of the current object, so unique for each panel.
      # Without this, ajax panels don't load, or load the wrong content.
      my ($panel_name) = $self =~ /\((.+)\)$/;

      # If this is going to be a POST request, move all POST and GET params to hidden inputs (this is done because GET params are not read in a post request by hub->param)
      my $ajax_post = '';
      if ($ajaxable eq 'post') {
        my $input = $hub->input;
        my %inps  = map { $_ => $hub->param($_) } $hub->param; # all params
        exists $inps{$_} or $inps{$_} = $input->url_param($_) for $input->url_param; # any remaining GET params
        foreach my $param_name (keys %inps) {
          $inps{$param_name} = [ $inps{$param_name} ] unless ref $inps{$param_name};
          for (@{$inps{$param_name}}) {
            $ajax_post .= qq(<input class="ajax_post" type="hidden" name="$param_name" value="$_" />);
          }
        }
      }

## ParaSite: put the section in a round box and add button to configure this section
      my $panel_component = $1 if $module_name =~ /::([^:]*?)$/;
      my $view_config = $hub->get_viewconfig($panel_component);
      my $config_component = $view_config ? lc($view_config->component) : undef;
      my $config_url = $view_config ? $hub->url('Config', {
              type      => $view_config->type,
              action    => $panel_component,
              function  => undef,
            }) : '';
      my $tool_buttons = $config_url ? qq(<a href="$config_url" class="modal_link config" rel="modal_config_$config_component">Configure this section</a>) : '';
      my $caption = $component->section_title;
      $html .= sprintf(
        '<div class="round-box" id="panel-%s">%s<div class="component-collapse"><div class="component-tools tool_buttons">%s</div><div class="ajax %s"><input type="hidden" class="ajax_load" name="%s" value="%s">%s</div></div></div>',
        $panel_component,
        $caption ? qq(<h2 class="component-header"><span class="component-plus" style="display: none">[+]</span><span class="component-minus">[-]</span> $caption</h2>) : '',
        $tool_buttons, $class, $panel_name, $url, $ajax_post
      );
## ParaSite

    } else {
      my $content;

      ### Try to call the required content function on the Component module
      eval {
        my $func = $ajax_request ? lc $function : $content_function;
        $func    = "content_$func" if $func;
        $content = $component->get_content($func);
      };

      if ($@) {
        $html .= $self->component_failure($@, $entry, $module_name);
      } elsif ($content) {
        if ($ajax_request) {
          my $id         = $component->id;
          my $panel_type = $modal || $content =~ /panel_type/ ? '' : '<input type="hidden" class="panel_type" value="Content" />';

          # Only add the wrapper if $content is html, and the update_panel parameter isn't present
          $content = qq{<div class="js_panel" id="$id">$panel_type$content</div>} if !$hub->param('update_panel') && $content =~ /^\s*<.+>\s*$/s;
        } else {
          my $caption = $component->caption;
          $html .= sprintf '<h2>%s</h2>', encode_entities($caption) if $caption;
        }

        $html .= $content;
      }
    }

    ## Does this component have any tables?
    if ($component && $component->{'_table_count'}) {
      $table_count += $component->{'_table_count'};
    }

  }

  if ($table_count > 1) {
    my $button = sprintf(
      '<div class="component_tools tool_buttons"><p style="display:inline-block"><a class="export" href="%s;filename=%s;_format=Excel" title="Download all tables as CSV">Download all tables as CSV</a></p></div>',
      $hub->url, $hub->filename
    );
    $html = $button.$html;
  }

  $html .= sprintf '<div class="more"><a href="%s">more about %s ...</a></div>', $self->{'link'}, encode_entities($self->parse($self->{'caption'})) if $self->{'link'};

  return $html;
}

1;
