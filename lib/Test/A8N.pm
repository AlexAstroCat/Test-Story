package Test::A8N;

# NB: Moose also enforces 'strict' and warnings;
use Moose;
use Test::A8N::File;
use File::Find;

our $VERSION = '0.01';

my %default_lazy = (
    required => 1,
    lazy     => 1,
    is       => q{ro},
    default  => sub { die "need to override" },
);

has filenames => (
    is          => q{rw},
    required    => 0,
    isa         => q{ArrayRef}
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

has file_paths => ( 
    is       => q{ro}, 
    required => 1, 
    lazy     => 1, 
    isa      => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my @file_list = ();
        my $wanted = sub {
            my $filename = $File::Find::name;
            if (-f) {
                push @file_list, $filename;
            }
        };
        my $root = $self->file_root;
        my @files = ref($self->filenames()) eq 'ARRAY' ? @{ $self->filenames() } : $root;
        find($wanted, @files);
        return \@file_list;
    }
);

has files => ( 
    is => q{ro}, 
    required => 1, 
    lazy => 1, 
    default => sub { 
        my $self = shift;
        my @files = ();
        for my $filename ( @{ $self->file_paths } ) {
            push @files, Test::A8N::File->new({
                filename     => $filename,
                fixture_base => $self->fixture_base,
                file_root    => $self->file_root,
            });
        }
        return \@files;
    }
);

sub run_tests {
    my $self = shift;
    foreach my $file (@{ $self->files }) {
        $file->run_tests();
    }
}

1;