#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;
use Encode qw( _utf8_on _utf8_off );

use lib "t";
use _common;

my $ascii = 'foobar';
my $utf8 = $ascii;
_utf8_off($utf8);
_utf8_on($utf8);

my @TESTS = (
    {
        a       => '',
        b       => undef,
        name    => 'empty_string_vs_undef',
        diff    => {N => undef,O => ''},
    },
    {
        a       => '',
        b       => 0,
        name    => 'empty_string_vs_0',
        diff    => {N => 0,O => ''}
    },
    {
        a       => 'a',
        b       => 'a',
        name    => 'a_vs_a',
        diff    => {U => 'a'},
    },
    {
        a       => 'a',
        b       => 'b',
        name    => 'a_vs_b',
        diff    => {N => 'b',O => 'a'},
    },
    {
        a       => $ascii,
        b       => $ascii,
        name    => 'ascii_vs_ascii',
        diff    => {U => 'foobar'},
    },
    {
        a       => $utf8,
        b       => $utf8,
        name    => 'utf8_vs_utf8',
        diff    => {U => 'foobar'},
    },
    {
        a       => $ascii,
        b       => $utf8,
        name    => 'ascii_vs_utf8',
        diff    => {U => 'foobar'},
    },
);

run_batch_tests(@TESTS);

done_testing();
