package EnsEMBL::Web::Document::HTML::CommentAdminPage;

use strict;
use base qw(EnsEMBL::Web::Document::HTML);

#Comment Admin Page
sub render {
	my $self = shift;
	my $html = q(
    <div id="comment_admincp_id">
        <div id="control_btns_id">
            <button id="24_btn_id" class="time_query_btn">Last 24 hours</button>
            <button id="72_btn_id" class="time_query_btn">Last 3 days</button>
            <button id="168_btn_id" class="time_query_btn">Last 7 days</button>
            <button id="100_top_btn_id" class="count_query_btn">Top 100</button>
            <button id="500_top_btn_id" class="count_query_btn">Top 500</button>
        </div>
        <br>
        <table id="comment_table_id" class="table table-striped table-bordered">
            <thead>
                <tr>
                    <th data-dynatable-column="user" style="width:6%">User</th>
                    <th data-dynatable-column="geneid" style="width:8%">Gene Id</th>
                    <th data-dynatable-column="comment_data" class="comment_txt">Comment</th>
                    <th data-dynatable-column="posted_on" style="text-align:center; width:12%">Posted on</th>
                    <th data-dynatable-column="changed_on" style="text-align:center; width:12%">Changed on</th>
                    <th data-dynatable-column="wasDeleted" style="width:5%">Removed?</th>
                    <th data-dynatable-column="wasEdited" style="width:5%">Edited?</th>
                    <th data-dynatable-column="edit_btn" style="width:5%" data-dynatable-no-sort="true">Edit</th>
                    <th data-dynatable-column="del_btn" style="width:5%" data-dynatable-no-sort="true">Delete</th>
                </tr>
            </thead>
            <tfoot>
                <tr>
                    <th data-dynatable-column="user" style="width:6%">User</th>
                    <th data-dynatable-column="geneid" style="width:8%">Gene Id</th>
                    <th data-dynatable-column="comment_data" style="text-align:center">Comment</th>
                    <th data-dynatable-column="posted_on" style="text-align:center; width:12%">Posted on</th>
                    <th data-dynatable-column="changed_on" style="text-align:center; width:12%">Changed on</th>
                    <th data-dynatable-column="wasDeleted" style="width:5%">Removed?</th>
                    <th data-dynatable-column="wasEdited" style="width:5%">Edited?</th>
                    <th data-dynatable-column="edit_btn" style="width:5%" data-dynatable-no-sort="true">Edit</th>
                    <th data-dynatable-column="del_btn" style="width:5%" data-dynatable-no-sort="true">Delete</th>
                </tr>
            </tfoot>
        </table>
    <div>);

    return '<h2>Forbidden</h2' unless ($self->hub->users_available && $self->hub->user);
    if (defined $self->hub->user->group($self->hub->species_defs->COMMENT_ADMIN_GROUP)) {
        return $html;      
    }
}

1;