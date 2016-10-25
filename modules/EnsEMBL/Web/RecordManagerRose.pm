package EnsEMBL::Web::RecordManagerRose;

sub basket     :Deprecated('use records') { shift->records('basket');     }

1;
