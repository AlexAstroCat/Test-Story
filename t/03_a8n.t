#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(t/mock t/lib);

use Test::More tests => 26;
use Test::Deep;
BEGIN { 
    use_ok('Test::Story') 
};

Basic_usage: {
    ok( Test::Story->meta->has_attribute('filenames'), q{filenames attribute}) ;
    ok( Test::Story->meta->has_attribute('files'), q{files attribute}) ;
    ok( Test::Story->meta->has_attribute('file_root'), q{file_root attribute}) ;
    ok( Test::Story->meta->has_attribute('fixture_base'), q{fixture_base attribute}) ;
    my $obj = Test::Story->new({
        filenames => [qw( t/cases/test1.tc )],
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });
    isa_ok($obj, 'Test::Story', q{object constructed}) ;
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});
    is_deeply($obj->file_paths(), [ 't/cases/test1.tc' ], q{file_paths returned testcase file path});
    ok(ref $obj->files() eq 'ARRAY', q{files returns array ref});
    ok(ref $obj->files()->[0] eq 'Test::Story::File', q{files returned Test::Story::File object});

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $obj->run_tests();
    cmp_deeply(
        $Test::FITesque::Suite::ADDED_TESTS,
        [
            [
                [ 'MockFixture', { testcase => ignore(), verbose => ignore() } ],
                [ 'fixture1'                                                   ],
                [ 'fixture2', 'foo'                                            ],
                [ 'fixture3', { bar => 'baz' }                                 ],
                [ 'fixture4', [qw( boo bork )]                                 ],
            ]
        ],
        q{Check that run_tests runs all 4 fixtures}
    );
    isa_ok($Test::FITesque::Suite::ADDED_TESTS->[0][0][1]->{testcase}, 'Test::Story::TestCase');
}

Different_extension: {
    ok( Test::Story->meta->has_attribute('filenames'), q{filenames attribute}) ;
    ok( Test::Story->meta->has_attribute('files'), q{files attribute}) ;
    ok( Test::Story->meta->has_attribute('file_root'), q{file_root attribute}) ;
    ok( Test::Story->meta->has_attribute('fixture_base'), q{fixture_base attribute}) ;
    my $obj = Test::Story->new({
        filenames => [qw( t/cases/storytest.st )],
        fixture_base => 'MockFixture',
        file_root => 't/cases',
	allowed_extensions => ["tc","st"],
    });
    isa_ok($obj, 'Test::Story', q{object constructed}) ;
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});
    is_deeply($obj->file_paths(), [ 't/cases/storytest.st' ], q{file_paths returned testcase file path});
    ok(ref $obj->files() eq 'ARRAY', q{files returns array ref});
    ok(ref $obj->files()->[0] eq 'Test::Story::File', q{files returned Test::Story::File object});

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $obj->run_tests();
    cmp_deeply(
        $Test::FITesque::Suite::ADDED_TESTS,
        [
            [
                [ 'MockFixture', { testcase => ignore(), verbose => ignore() } ],
                [ 'fixture1'                                                   ],
                [ 'fixture2', 'foo'                                            ],
                [ 'fixture3', { bar => 'baz' }                                 ],
                [ 'fixture4', [qw( boo bork )]                                 ],
            ]
        ],
        q{Check that run_tests runs all 4 fixtures}
    );
    isa_ok($Test::FITesque::Suite::ADDED_TESTS->[0][0][1]->{testcase}, 'Test::Story::TestCase');
}

Directories: {
    my $obj = Test::Story->new({
        filenames => [qw( t/cases/UI )],
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});

    my @files = grep {/\.tc/} @{ $obj->file_paths };
    is_deeply(
        [ sort @files ],
        [ sort qw(
            t/cases/UI/Reports/Report_Dashboard.tc
            t/cases/UI/Config/Certificates/Views_Root_CA.tc
            t/cases/UI/Config/Accounts/Alert_Recipients.tc
        )],
        q{Check the files returned}
    );
}

Directories_All: {
    my $obj = Test::Story->new({
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });

    my @files = grep {/\.tc/} @{ $obj->file_paths };
    is_deeply(
        [ sort @files ],
        [ sort(
            't/cases/test1.tc',
            't/cases/test with spaces.tc',
            't/cases/UI/Reports/Report_Dashboard.tc',
            't/cases/UI/Config/Certificates/Views_Root_CA.tc',
            't/cases/UI/Config/Accounts/Alert_Recipients.tc',
            't/cases/System Status/Basic Status.tc',
        )],
        q{Check file list when no filename is selected, e.g. "All Files"}
    );
}
