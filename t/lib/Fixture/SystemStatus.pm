package Fixture::System_Status;

use strict;
use warnings;
use base qw(Fixture);
use Test::More;

sub systemstatus : Test {
    my ($self, $file) = @_;
    pass('System Status test works');
}

1;

