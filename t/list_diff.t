#!perl -T

use strict;
use warnings;

use Struct::Diff qw(diff list_diff);
use Storable qw(freeze);

use Test::More tests => 8;

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

use lib "t";
use _common qw(sdump);

my ($frst, $scnd, @list, $frozen);

### keys sort ###
$frst = { '0' => 0,  '1' => 1, '02' => 2 };
$scnd = { '0' => '', '1' => 1, '02' => 2 };

@list = list_diff(diff($frst, $scnd), sort => 1);
is_deeply(
    \@list,
    [
        [{keys => ['0']}],
            \{N => '',O => 0},
        [{keys => ['02']}],
            \{U => 2},
        [{keys => ['1']}],
            \{U => 1}
    ],
    "lexical keys sort"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), sort => sub { sort { $b <=> $a } @_ });
is_deeply(
    \@list,
    [
        [{keys => ['02']}],
            \{U => 2},
        [{keys => [1]}],
            \{U => 1},
        [{keys => [0]}],
            \{N => '',O => 0}
        ],
    "numeric keys sort (desc)"
) or diag sdump \@list;

### mixed structures ###
$frst = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]};
$scnd = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 3 ]}}, 8 ]};

@list = list_diff(diff($frst, $frst));
is_deeply(
    \@list,
    [
        [],
            \{U => {a => [{aa => {aaa => [7,4]}},8]}}
    ],
    "MIXED: unchanged"
) or diag sdump \@list;

my $d = diff($frst, $scnd);
$frozen = freeze($d);
@list = list_diff($d);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0],{keys => ['aa']},{keys => ['aaa']},[0]],
            \{U => 7},
        [{keys => ['a']},[0],{keys => ['aa']},{keys => ['aaa']},[1]],
            \{N => 3,O => 4},
        [{keys => ['a']},[1]],
            \{U => 8}
    ],
    "MIXED: complex"
) or diag sdump \@list;

ok(freeze($d) eq $frozen, "Check diff structure unchanged");

### depth ###
@list = list_diff(diff($frst, $scnd), depth => 0);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0],{keys => ['aa']},{keys => ['aaa']},[0]],
            \{U => 7},
        [{keys => ['a']},[0],{keys => ['aa']},{keys => ['aaa']},[1]],
            \{N => 3,O => 4},
        [{keys => ['a']},[1]],
            \{U => 8}
    ],
    "depth 0 (full list)"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), depth => 1);
is_deeply(
    \@list,
    [
        [{keys => ['a']}],
            \{D => [{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}
    ],
    "depth 1"
) or diag sdump \@list;

@list = list_diff(diff($frst, $scnd), depth => 2);
is_deeply(
    \@list,
    [
        [{keys => ['a']},[0]],
            \{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},
        [{keys => ['a']},[1]],
            \{U => 8}
    ],
    "depth 2"
) or diag sdump \@list;
