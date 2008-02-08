package Test::A8N::Fixture;

use Moose;

BEGIN {
    # This ensures the constructor from Moose::Object is
    # preferred over the FITesque one... this is IMPORTANT!
    extends(qw(Moose::Object Test::FITesque::Fixture));
}

use Test::More;
use YAML::Syck;
use File::Temp qw(tempfile);
use WWW::Selenium;
our @EXCLUDE_METHODS = qw(
    config
    selenium
    testcase
    ctxt
    verbose
    page_mapping
    parse_method_string
    disallowed_phrases
    parse_arguments
);

sub BUILD {
    my $self = shift;
    my ($params) = @_;
    if ($params->{QUIET} || $ENV{QUIET_FIXTURES}) {
        Test::Builder->new->no_diag(1);
    }
    diag sprintf(q{Using fixture class "%s"}, blessed($self))
        if ($self->verbose);
    diag "START: " . $self->testcase->id;
}

sub DEMOLISH {
    my $self = shift;
    if (exists $self->ctxt->{selenium}) {
        $self->ctxt->{selenium}->stop();
    }
    diag "FINISH: " . $self->testcase->id;
}

has 'config' => (
    is => 'ro',
    required => 1,
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my %user_config = ();

        my $tc_config = $self->testcase->configuration;
        my @config_files = @{ $tc_config };

        my $file_config = $self->testcase->filename;
        $file_config =~ s/\.st$/.conf/;
        push @config_files, $file_config
           if (-f $file_config);

        push @config_files, glob('~/.a8rc');

        while (my $config = shift @config_files) {
            my $config_data = LoadFile($config);
            die "Configuration $config is not a hash"
                unless (ref($config_data) eq 'HASH');
            %user_config = (%user_config, %$config_data);
        }
        return \%user_config;
    }
);

has 'testcase' => (
    is => 'rw',
    isa => 'Object'
);

has 'ctxt' => (
    is => 'rw',
    required => 1,
    isa => 'HashRef',
    default => sub { {} },
    lazy => 1,
);

has verbose => (
    is          => q{rw},
    required    => 0,
    isa         => q{Bool}
);

sub page_mapping {
    my $self = shift;
    my ($url) = @_;
    if ($url =~ m#^/#) {
        return $url;
    }
    die sprintf("Can't find the URL for %s", $url);
}

# NB: this is a FITesque method, please do not edit.
sub parse_method_string {
  my ($self, $method_string) = @_;
  (my $method_name = $method_string) =~ s/\s+/_/g;

  # don't allow test cases to call private methods
  if($method_name =~ m{^_}){
    warn "Cannot call '$method_name' from test cases";
    return undef;
  }

  if (ref($self) and $self->verbose) {
      diag "Fixture method $method_name";
  }

  # Don't allow testcases to talk about implementaion details
  if(grep { $method_name =~ m{$_} } $self->disallowed_phrases()){

    #
    # Test cases should be completely oblivious to how things are done
    # internally since they should be written from the perspective of the
    # user. This is just a catchall to make sure that the developer really
    # means "do something like the user would" instead of "hoke around the
    # internals"
    #
    warn "'$method_name' refers to implementation details";
    return undef;
  }

  my $coderef = $self->can($method_name);
  return $coderef;
}

sub disallowed_phrases {
  my ($self) = @_;
  return qw();
}

sub selenium {
    my $self = shift;

    return $self->ctxt->{selenium}
        if (exists $self->ctxt->{selenium});

    my %args = (
        host => $self->_get_metavar('selenium.server'),
        port => $self->_get_metavar('selenium.port'),
        browser => $self->_get_metavar('selenium.browser'),
        browser_url => $self->_get_metavar('selenium.browser_url'),
    );

    foreach my $key (keys %args) {
        delete $args{$key} unless ($args{$key});
    }

    $args{browser} = "*$args{browser}" if (exists $args{browser});

    # Create, save and return a selenium object for this appliance
    $self->ctxt->{selenium} = WWW::Selenium->new( %args );
    $self->ctxt->{selenium}->start();
    return $self->ctxt->{selenium};
}

sub _get_metavar {
    my $self = shift;
    my ($name) = @_;
    my $config_ref = $self->config;

    my @path = split(/\./, $name);
    foreach my $sub_name (@path) {
        $config_ref = $config_ref->{$sub_name} or last;
    }
    warn qq{Config reference "$name" does not point to a value}
        if (ref($config_ref));
    return $config_ref;
}

sub _parse_metavars {
    my $self = shift;
    my ($str) = @_;
    $str ||= '';

    my @keys = $str =~ /\$\(([^\)]+)\)/g;
    foreach (@keys) {
        my $value = $self->_get_metavar($_);
        $str =~ s/\$\($_\)/$value/g;
    }

    return $str;
}
sub _recurse_parse_arguments {
    my $self = shift;
    my $arg = shift;
    if (ref($arg) eq 'HASH') {
        foreach my $key (keys %$arg) {
            if (ref($arg->{$key})) {
                $arg->{$key} = $self->_recurse_parse_arguments($arg->{$key});
            } else {
                $arg->{$key} = $self->_parse_metavars($arg->{$key});
            }
        }
    } elsif (ref($arg) eq 'ARRAY') {
        foreach my $idx (0 .. scalar(@$arg) - 1) {
            if (ref($arg->[$idx])) {
                $arg->[$idx] = $self->_recurse_parse_arguments($arg->[$idx]);
            } else {
                $arg->[$idx] = $self->_parse_metavars($arg->[$idx]);
            }
        }
    } else {
        $arg = $self->_parse_metavars($arg);
    }
    return $arg;
}

# NB: This is a FITesque required function
sub parse_arguments {
    my $self = shift;
    return @_ if !ref($self);

    my @args = ();
    my $recurse;

    foreach my $arg (@_) {
        push @args, $self->_recurse_parse_arguments($arg);
    }
    return @args;
}

=head1 FIXTURE ACTIONS

=cut

=head2 todo fail

  todo fail: [ message ]

Marks a place in the test case where you would like it to fail, flagging it as a TODO item.

=cut

sub todo_fail {
    my $self = shift;
    my ($arg) = @_;
    TODO: {
        local $TODO = "Marked as a failing TODO: $arg";
        fail($arg);
    }
}

=head2 goto page

  goto page: /some/url
  goto page: PageName

Sets the current browser context to a page, either using the absolute path supplied, or
using an abstract page name as defined by the page_mapping hash.  Either set this at run-time,
or override it in a subclass.

=cut

sub goto_page {
    my $self = shift;
    my ($page) = @_;

    $self->selenium->open( $self->page_mapping($page) );
    if ($self->config->{selenium}->{browser} eq 'firefox' and !exists($self->{resized})) {
        #$self->selenium->resizeWindow();
        #$self->{resized} = 1;
    }
}


1;
__END__

=head1 SEE ALSO

L<Test::A8N>, L<Test::FITesque::Fixture>

=cut

