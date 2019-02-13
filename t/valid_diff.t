#!perl -T

use strict;
use warnings FATAL => 'all';

use Struct::Diff qw(valid_diff);
use Test::More tests => 15;

use lib "t";
use _common qw(scmp);

my (@got, @exp);

### scalar context
is(
    valid_diff(sub { 0 }),
    undef,
    "Diff must be a HASH"
);

is(
    valid_diff({D => undef}),
    undef,
    "Wrong D value type"
);

is(
    valid_diff({D => [{A => 0, N => 1}]}),
    undef,
    "Invalid mix of tags"
);

### list context
@got = valid_diff(
    []
);
@exp = ([],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => {one => undef}}
);
@exp = ([{K => ['one']}],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [undef]}
);
@exp = ([[0]],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => undef}
);
@exp = ([],'BAD_D_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [{D => 0},{D => 0}]}
);
@exp = (
    [[0]],'BAD_D_TYPE',
    [[1]],'BAD_D_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => {a => {D => 1},b => {D => 1}}}
);
@exp = (
    [{K => ['a']}],'BAD_D_TYPE',
    [{K => ['b']}],'BAD_D_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [{D => 0},{N => 1},undef]}
);
@exp = (
    [[0]],'BAD_D_TYPE',
    [[2]],'BAD_DIFF_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {
        D => [
            # not ok
            {A => 0, N => 1},
            {A => 0, O => 1},
            {A => 0, R => 1},
            {A => 0, U => 1},

            {N => 1, A => 1},
            {N => 1, R => 1},
            {N => 1, U => 1},

            {O => 1, A => 1},
            {O => 1, R => 1},
            {O => 1, U => 1},

            {R => 0, A => 1},
            {R => 0, N => 1},
            {R => 0, O => 1},
            {R => 0, U => 1},

            {U => 0, A => 1},
            {U => 0, N => 1},
            {U => 0, O => 1},
            {U => 0, R => 1},

            # ok
            {A => 1, F => 0}, # external tags allowed (may extend diff format)
            {N => 1, O => 2},
        ]
    }
);
@exp = (
    [[0]], 'BAD_DIFF_TAGS',
    [[1]], 'BAD_DIFF_TAGS',
    [[2]], 'BAD_DIFF_TAGS',
    [[3]], 'BAD_DIFF_TAGS',
    [[4]], 'BAD_DIFF_TAGS',
    [[5]], 'BAD_DIFF_TAGS',
    [[6]], 'BAD_DIFF_TAGS',
    [[7]], 'BAD_DIFF_TAGS',
    [[8]], 'BAD_DIFF_TAGS',
    [[9]], 'BAD_DIFF_TAGS',
    [[10]], 'BAD_DIFF_TAGS',
    [[11]], 'BAD_DIFF_TAGS',
    [[12]], 'BAD_DIFF_TAGS',
    [[13]], 'BAD_DIFF_TAGS',
    [[14]], 'BAD_DIFF_TAGS',
    [[15]], 'BAD_DIFF_TAGS',
    [[16]], 'BAD_DIFF_TAGS',
    [[17]], 'BAD_DIFF_TAGS',
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

### indexes
ok(not valid_diff({D => [{A => 0, I => undef}]}));

@got = valid_diff(
    {
        D => [
            {A => 0, I => undef},
            {A => 0, I => 9},
            {A => 0, I => 0.3},
            {A => 0, I => 'foo'},
            {A => 0, I => sub { 0 }},
            {A => 0, I => -1},
            {A => 0, I => bless {}, 'foo'},
        ]
    }
);
@exp = (
    [[0]],'BAD_I_TYPE',
    [[2]],'BAD_I_TYPE',
    [[3]],'BAD_I_TYPE',
    [[4]],'BAD_I_TYPE',
    [[6]],'BAD_I_TYPE'
);
is_deeply(\@got, \@exp, "Integers permitted only") || diag scmp(\@got, \@exp);

is(
    valid_diff({I => 2}),
    undef,
    "Lonesome I, scalar context"
);

@got = valid_diff({I => 9});
@exp = (
    [],'LONESOME_I'
);
is_deeply(\@got, \@exp, "Integers permitted only") || diag scmp(\@got, \@exp);

