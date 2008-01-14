package Fixture::UI::Config;

use strict;
use warnings;
use base qw(Fixture::UI);
use Test::More;

sub config_test1 : Test {
    my ($self, $file) = @_;
    pass('Config test works');
}

1;
