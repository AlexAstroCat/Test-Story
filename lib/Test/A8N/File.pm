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

has fixture_root => (
    is          => q{rw},
    required    => 1,
    isa         => q{Str}
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
        foreach my $case (@{ $self->data }) {
            push @cases, new Test::A8N::TestCase({
                data    => $case,
                'index' => ++$idx,
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
        unless (grep $self->fixture_root, @INC) {
            unshift @INC, $self->fixture_root;
        }
        my $filename = $self->filename;
        my $root = $self->file_root;
        $filename =~ s#^$root##;
        my @path = split('/', $self->filename);
        pop @path; # take off the filename
        unshift @path, $self->fixture_root;

        while ($#path > -1) {
            my $class = join('::', @path);
            eval { 
                load($class);
            };
            unless ($@) {
                return $class;
            }
            pop @path;
        }
        die 'Cannot find a fixture class for "' . $self->filename . '"';
    }
);

sub run_tests {
    my $self = shift;

    my $suite = Test::FITesque::Suite->new();
    foreach my $case (@{ $self->cases }) {
        my @data = @{ $case->test_data };
        my $test = Test::FITesque::Test->new({ data => [ [$self->fixture_class], @data ] });
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

1;
__END__
