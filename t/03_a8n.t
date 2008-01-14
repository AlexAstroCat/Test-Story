#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(t/mock t/lib);

use Test::More tests => 14;
BEGIN { 
    use_ok('Test::A8N') 
};

Basic_usage: {
    ok( Test::A8N->meta->has_attribute('filenames'), q{filenames attribute}) ;
    ok( Test::A8N->meta->has_attribute('files'), q{files attribute}) ;
    ok( Test::A8N->meta->has_attribute('file_root'), q{file_root attribute}) ;
    ok( Test::A8N->meta->has_attribute('fixture_base'), q{fixture_base attribute}) ;
    my $obj = Test::A8N->new({
        filenames => [qw( t/cases/test1.tc )],
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });
    isa_ok($obj, 'Test::A8N', q{object constructed}) ;
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});
    is_deeply($obj->file_paths(), [ 't/cases/test1.tc' ], q{file_paths returned testcase file path});
    ok(ref $obj->files() eq 'ARRAY', q{files returns array ref});
    ok(ref $obj->files()->[0] eq 'Test::A8N::File', q{files returned Test::A8N::File object});

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $obj->run_tests();
    is_deeply(
        $Test::FITesque::Suite::ADDED_TESTS,
        [
            [
                [ 'MockFixture'                 ],
                [ 'fixture1'                    ],
                [ 'fixture2', 'foo'             ],
                [ 'fixture3', { bar => 'baz' }  ],
                [ 'fixture4', [qw( boo bork )]  ],
            ]
        ],
        q{Check that run_tests runs all 4 fixtures}
    );
}

Directories: {
    my $obj = Test::A8N->new({
        filenames => [qw( t/cases/UI )],
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});

    is_deeply(
        $obj->file_paths,
        [qw(
            t/cases/UI/Reports/Report_Dashboard.tc
            t/cases/UI/Config/Certificates/Views_Root_CA.tc
            t/cases/UI/Config/Accounts/Alert_Recipients.tc
        )],
        q{Check the files returned}
    );
}

Directories_All: {
    my $obj = Test::A8N->new({
        fixture_base => 'MockFixture',
        file_root => 't/cases',
    });

    is_deeply(
        $obj->file_paths,
        [
            't/cases/test1.tc',
            't/cases/UI/Reports/Report_Dashboard.tc',
            't/cases/UI/Config/Certificates/Views_Root_CA.tc',
            't/cases/UI/Config/Accounts/Alert_Recipients.tc',
            't/cases/System Status/Basic_Status.tc',
        ],
        q{Check file list when no filename is selected, e.g. "All Files"}
    );
}
