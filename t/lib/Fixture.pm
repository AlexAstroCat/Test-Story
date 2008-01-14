package Fixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);
use Test::More;

sub file_exists : Test {
    my ($self, $file) = @_;
    ok -e $file, qq{File ’$file’ exists};
}

1;
