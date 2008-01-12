package Test::FITesque::Test;
use Moose;
has data => (
    isa => 'ArrayRef',
    is  => q{rw},
);

1;
