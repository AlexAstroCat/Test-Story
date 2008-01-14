#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use lib qw(t/mock t/lib);

BEGIN { 
    use_ok('Test::A8N::File') 
};

Basic_usage: {
    ok(Test::A8N::File->meta->has_attribute('filename'), q{filename attribute});
    ok(Test::A8N::File->meta->has_attribute('file_root'), q{file_root attribute});
    ok(Test::A8N::File->meta->has_attribute('fixture_base'), q{fixture_base attribute});
    ok(Test::A8N::File->meta->has_attribute('fixture_class'), q{fixture attribute});
    ok(Test::A8N::File->meta->has_attribute('data'), q{data attribute});
    ok(Test::A8N::File->meta->has_attribute('cases'), q{cases attribute});

    throws_ok(
        sub {
            Test::A8N::File->new({
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
    my $file = Test::A8N::File->new({
        filename     => 't/cases/test1.tc',
        file_root    => 't/cases',
        fixture_base => 'MockFixture',
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for test1.tc});
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
    is_deeply($file->data, [$test1], q{YAML data returned correctly});
    isa_ok($file->cases->[0], 'Test::A8N::TestCase', q{cases() returned a Test::A8N::TestCase object});
    is($file->fixture_base, 'MockFixture', q{fixture_base property matches what was supplied});
    is($file->fixture_class, 'MockFixture', q{Correct fixture class located});

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $file->run_tests();
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

Inherited_Fixtures: {
    my $file = Test::A8N::File->new({
        filename     => 't/cases/UI/Config/Accounts/Alert_Recipients.tc',
        file_root    => 't/cases',
        fixture_base => 'Fixture',
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for Alert_Recipients.tc});
    is($file->fixture_class, 'Fixture::UI::Config', q{Inherited fixture class located});
}
