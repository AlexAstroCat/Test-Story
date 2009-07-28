#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;
use Test::Deep;
use lib qw(t/mock t/lib);

BEGIN { 
    use_ok('Test::Story::File') 
};

Basic_usage: {
    ok(Test::Story::File->meta->has_attribute('filename'), q{filename attribute});
    ok(Test::Story::File->meta->has_attribute('file_root'), q{file_root attribute});
    ok(Test::Story::File->meta->has_attribute('fixture_base'), q{fixture_base attribute});
    ok(Test::Story::File->meta->has_attribute('fixture_class'), q{fixture attribute});
    ok(Test::Story::File->meta->has_attribute('data'), q{data attribute});
    ok(Test::Story::File->meta->has_attribute('cases'), q{cases attribute});

    throws_ok(
        sub {
            Test::Story::File->new({
                filename     => 't/cases/test_doesnt_exist.tc',
                file_root    => 't/cases',
                parser       => 'Test::Sophos::Parser',
                fixture_base => 'Test::Sophos::Fixture',
            });
        },
        qr{Could not find a8n file "t/cases/test_doesnt_exist.tc"},
        q{File not existing}
    );
}

Simple_File: {
    my $file = Test::Story::File->new({
        filename     => 't/cases/test1.tc',
        file_root    => 't/cases',
        fixture_base => 'MockFixture',
    });
    isa_ok($file, 'Test::Story::File', q{Created File object for test1.tc});
    is($file->filename, 't/cases/test1.tc', q{Filename property contains valid value});

    my $test1 = {
        'NAME'         => 'Test Case 1',
        'ID'           => 'some_test_case_1',
        'SUMMARY'      => 'This is a test summary',
        'TAGS'         => [qw( tag1 tag2 )],
        'INSTRUCTIONS' => [
            'fixture1',
            { 'fixture2' => 'foo' },
            { 'fixture3' => { 'bar' => 'baz' } },
            { 'fixture4' => [ 'boo', 'bork' ] }
        ],
        'EXPECTED'     => 'Some output',
    };
    is_deeply($file->data, [$test1,undef], q{YAML data returned correctly});
    is( scalar @{ $file->cases }, 1, q{cases() returns correct number of cases} );
    isa_ok($file->cases->[0], 'Test::Story::TestCase', q{cases() returned a Test::Story::TestCase object});
    is($file->fixture_base, 'MockFixture', q{fixture_base property matches what was supplied});
    is($file->fixture_class, 'MockFixture', q{Correct fixture class located});

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $file->run_tests();
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
}

Files_with_spaces: {
    my $file = Test::Story::File->new({
        filename     => 't/cases/test with spaces.tc',
        file_root    => 't/cases',
        fixture_base => 'MockFixture',
    });
    isa_ok($file, 'Test::Story::File', q{Created File object for "test with spaces.tc"});
    is($file->filename, 't/cases/test with spaces.tc', q{Filename property contains valid value});
}

Files_with_different_extensions: {
    my $file = Test::Story::File->new({
        filename     => 't/cases/storytest.st',
        file_root    => 't/cases',
        fixture_base => 'MockFixture',
    });
    isa_ok($file, 'Test::Story::File', q{Created File object for "storytest.st"});
    is($file->filename, 't/cases/storytest.st', q{Filename property contains valid value});
}

Inherited_Fixtures: {
    my $file = Test::Story::File->new({
        filename     => 't/cases/UI/Config/Accounts/Alert_Recipients.tc',
        file_root    => 't/cases',
        fixture_base => 'Fixture',
    });
    isa_ok($file, 'Test::Story::File', q{Created File object for Alert_Recipients.tc});
    is($file->fixture_class, 'Fixture::UI::Config', q{Inherited fixture class located});
}

Fixtures_With_Spaces: {
    my $file = Test::Story::File->new({
        filename     => 't/cases/System Status/Basic Status.tc',
        file_root    => 't/cases',
        fixture_base => 'Fixture',
    });
    is($file->fixture_class, 'Fixture::SystemStatus', q{Fixture class has been found for a directory with a space});
}

