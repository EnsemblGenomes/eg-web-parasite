package Bio::EnsEMBL::DBSQL::ArchiveStableIdAdaptor;

use strict;
use warnings;


sub get_current_release {
  return $SiteDefs::SITE_RELEASE_VERSION;
}

1
