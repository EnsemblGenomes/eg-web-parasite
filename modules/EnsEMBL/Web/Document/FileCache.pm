package EnsEMBL::Web::Document::FileCache;
use strict;
use warnings;
use Fcntl ':flock';

my $debug = 0;
sub read_html {
  my $self = shift;
  my $refresh_period = $_[0] || 86400;
  my $classname= (split/::/, ref($self))[-1];
  my $content;
  my $time = time();
  my $filename = "$SiteDefs::ENSEMBL_TMP_DIR/$classname.html";
  
  $debug && warn ">>>> Refresh period is $refresh_period";
  $debug && warn ">>>> File name is $filename";

  if (-f $filename && -e $filename) {
    if (open my $fh, $filename) {
      flock($fh, LOCK_EX);
      local($/) = undef;
      my $last_mod_time = (stat ($fh))[9];
      $content = <$fh>;
      close $fh;
      if ($time - $last_mod_time > $refresh_period) {
        $self->write_html($filename);
      }
      $debug && warn ">>>> Content length is " . length($content);
      return $content;
    } else {
      return "<p>Server side error loading this page<p>";
    }
  } else {
    $self->write_html($filename);
  }
}

sub write_html {
  my $self = shift;
  my $filename = $_[0];
  $debug && warn ">>>> Writing file $filename";
  open my $fh, '>', $filename or die "Can't open $filename $!";
  my $result = flock($fh, LOCK_EX);
  my $html = $self->make_html();
  print $fh $html;
  close $fh;
}

1;