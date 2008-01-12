package Test::A8N::TestCase;

# NB: Moose also enforces 'strict' and warnings;
use Moose;

my %default_lazy = (
    required => 1,
    lazy     => 1,
    is       => q{ro},
    default  => sub { die "need to override" },
);

has data => (
    is       => q{ro},
    required => 1,
    isa      => q{HashRef}
);

has index => (
    is       => q{ro},
    required => 1,
    isa      => q{Int}
);

has id => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        if (exists $self->data->{ID}) {
            return $self->data->{ID};
        } else {
            my $id = $self->name;
            $id =~ s/ /_/;
            return lc($id);
        }
    }
);

has name => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        return $self->data->{NAME};
    }
);

has summary => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        return $self->data->{SUMMARY};
    }
);

has tags => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{TAGS} eq 'ARRAY') {
            return [@{ $self->data->{TAGS} }];
        }
        return [];
    }
);

has instructions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{INSTRUCTIONS} eq 'ARRAY') {
            return [@{ $self->data->{INSTRUCTIONS} }];
        }
        return [];
    }
);

has preconditions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{PRECONDITIONS} eq 'ARRAY') {
            return [@{ $self->data->{PRECONDITIONS} }];
        }
        return [];
    }
);

has test_data => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        return $self->parse_data([
            @{ $self->preconditions },
            @{ $self->instructions },
        ]);
    }
);

sub parse_data {
    my $self = shift;
    my ($data) = @_;
    my @tests = ();
    foreach my $test (@$data) {
        # Handle single-string tests
        if (!ref($test)) {
            push @tests, [$test];
        }

        # Handle hash tests
        elsif (ref($test) eq 'HASH') {
            my ($name) = keys %$test;
            my ($value) = $test->{$name};
            push @tests, [$name, $value];
        }
    }
    return \@tests;
}

1;
__END__
