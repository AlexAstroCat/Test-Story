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

sub BUILD {
    my $self = shift;
    my ($params) = @_;
    if ($params->{QUIET} || $ENV{QUIET_FIXTURES}) {
        Test::Builder->new->no_diag(1);
    }
    diag sprintf(q{Using fixture class "%s"}, blessed($self));
    diag "START: " . $self->testcase->id;
}

sub DEMOLISH {
    my $self = shift;
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
        $file_config =~ s/\.tc$/.conf/;
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

# NB: this is a FITesque method, please do not edit.
sub parse_method_string {
  my ($self, $method_string) = @_;
  (my $method_name = $method_string) =~ s/\s+/_/g;

  # don't allow test cases to call private methods
  if($method_name =~ m{^_}){
    warn "Cannot call '$method_name' from test cases";
    return undef;
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
  return qw(sophox configd upkeep hexcd);
}

sub selenium {
    my $self = shift;
    # Return a previously-created selenium object for this appliance
    my $app_name = $self->appliance->hostname;

    return $self->ctxt->{selenium}->{$app_name}
        if (exists $self->ctxt->{selenium}->{$app_name});

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
    $args{browser_url} = $self->appliance->admin_url
        unless (exists($args{browser_url}));

    # Create, save and return a selenium object for this appliance
    $self->ctxt->{selenium}->{$app_name} = Sophos::Tank::Selenium->new( %args );
    return $self->ctxt->{selenium}->{$app_name};
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

# NB: This is a FITesque required function
sub parse_arguments {
    my $self = shift;
    my @args = ();
    foreach my $arg (@_) {
        next unless ($arg);
        if (my ($name) = $arg =~ /\$\(([^\)]+)\)/) {
            my $value = $self->_get_metavar($name);
            $arg =~ s/\$\($name\)/$value/g;
        }
        push @args, $arg;
    }
    return @args;
}

1;

__END__
