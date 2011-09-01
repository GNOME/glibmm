package GirTopLevelHandlers;

use strict;
use warnings;
use GirParser;

sub _namespace_handler ($@)
{
  my ($self, $
}

sub get_handlers ()
{
  return
  {
    'namespace' => \&_namespace_handler
  }
}
