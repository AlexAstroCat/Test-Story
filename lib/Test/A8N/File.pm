package Test::A8N::File;

# NB: Moose also enforces 'strict' and warnings;
use Moose;
use YAML::Syck;
use Test::A8N::TestCase;
use Module::Load;
use Test::FITesque::Suite;
use Test::FITesque::Test;

my %default_lazy = (
    required => 1,
    lazy     => 1,
    is       => q{ro},
    default  => sub { die "need to override" },
);

has filename => (
    is          => q{rw},
    required    => 1,
    isa         => q{Str}
);

has file_root => (
    is          => q{rw},
    required    => 1,
    isa         => q{Str}
);

has fixture_base => (
    is          => q{rw},
    required    => 1,
    isa         => q{Str}
);

has verbose => (
    is          => q{rw},
    required    => 0,
    isa         => q{Bool}
);

has data => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my $content = [ LoadFile($self->filename) ];
        return $content;
    }
);

has cases => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my @cases;
        my $idx = 0;
        my $filename = $self->filename;
        foreach my $case (@{ $self->data }) {
            push @cases, new Test::A8N::TestCase({
                data    => $case,
                'index' => ++$idx,
                filename => $filename,
            });
        }
        return \@cases;
    }
);

has fixture_class => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        local @INC = @INC;
        unless (grep $self->fixture_base, @INC) {
            unshift @INC, $self->fixture_base;
        }
        my $filename = $self->filename;
        my $root = $self->file_root;
        $filename =~ s#^$root/?##;
        $filename =~ s/\s+//g;
        my @path = split('/', $filename);
        pop @path; # take off the filename
        unshift @path, split(/::/, $self->fixture_base);

        while ($#path > -1) {
            my $class = join('::', @path);
            warn "Attempting to load fixture class $class\n" if ($self->verbose);
            eval { 
                load($class);
            };
            unless ($@) {
                return $class;
            }
            if ($@ !~ /^Can't locate /) {
                warn "Error while loading fixture $class: $@\n";
            }
            pop @path;
        }
        die 'Cannot find a fixture class for "' . $self->filename . '"';
    }
);

sub run_tests {
    my $self = shift;

    my $suite = Test::FITesque::Suite->new();

    my $cases = $self->cases();
    foreach my $case (@{ $cases }) {
        my @data = @{ $case->test_data };
        my $test = Test::FITesque::Test->new({
            data => [ 
                [$self->fixture_class, { testcase => $case, verbose => $self->verbose } ], 
                @data 
            ],
        });
        $suite->add($test);
    }
    $suite->run_tests();
}

sub BUILD {
    my $self = shift;
    my ($params) = @_;

    if (!-f $self->filename){
        die 'Could not find a8n file "' . $self->filename . '"';
    }
}

# unimport moose functions and make immutable
no Moose;
__PACKAGE__->meta->make_immutable();

1;
__END__
