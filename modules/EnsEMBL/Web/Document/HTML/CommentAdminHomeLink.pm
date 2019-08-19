package EnsEMBL::Web::Document::HTML::CommentAdminHomeLink;

use strict;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
	my $self = shift;
	return '' unless ($self->hub->users_available && $self->hub->user);
	if (defined $self->hub->user->group($self->hub->species_defs->COMMENT_ADMIN_GROUP)) {
		return qq(
			<div class="round-box home-box">
				<h2>Comment</h2>
				<li><a href="/commentcp.html?sorts[changed_on]=-1" target="_blank">Admin Panel</a></li>
			</div>)
	}
}

1;
