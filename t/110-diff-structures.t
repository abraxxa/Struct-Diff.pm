#!perl -T

use strict;
use warnings;
use Storable qw(freeze);
use Test::More tests => 38;

use Struct::Diff qw(diff);

use lib "t";
use _common qw(scmp);

$Storable::canonical = 1;
my ($a, $b, $d, $frozen_a, $frozen_b);

### arrays ###
ok($d = diff([], [ 1 ]) and
    scmp($d, {A => [1]}, "[] vs [1]")
);

ok($d = diff([], [ 1 ], 'noA' => 1) and
    scmp($d, {}, "[] vs [1], noA => 1")
);

ok($d = diff([ 1 ], []) and
    scmp($d, {R => [1]}, "[1] vs []")
);

ok($d = diff([ 1 ], [], 'noR' => 1) and
    scmp($d, {}, "[1] vs [], noR => 1")
);

ok($d = diff([[ 0 ]], [[ 1 ]]) and # deep single-nested changed
    scmp($d, {D => [{D => [{N => 1,O => 0}]}]}, "[[0]] vs [[1]]")
);

ok($d = diff([], [[[[[ 0, 1 ]]]]]) and
    scmp($d, {A => [[[[[0,1]]]]]}, "[] vs [[[[[0,1]]]]]")
);

ok($d = diff([[[[[ 0, 1 ]]]]], []) and
    scmp($d, {R => [[[[[0,1]]]]]}, "[[[[[0,1]]]]] vs []")
);

ok($d = diff([[[[[ 0, 1 ]]]]], [], 'trimR' => 1) and
    scmp($d, {R => [undef]}, "[[[[[0,1]]]]] vs [], trimR => 1")
);

ok($d = diff([ 0, [[[[ 0, 1 ]]]]], [ 0 ], 'trimR' => 1) and
    scmp($d, {D => [{U => 0},{R => undef}]}, "[ 0, [[[[ 0, 1 ]]]]] vs [ 0 ], trimR => 1")
);

ok($d = diff([ 'a' ], [ 'b' ], 'noO' => 1) and
    scmp($d, {N => ['b']}, "[a] vs [b], noO => 1")
);

ok($d = diff([ 'a' ], [ 'b' ], 'noN' => 1) and
    scmp($d, {O => ['a']}, "[a] vs [b], noN => 1")
);



ok($d = diff([ 0 ], [ 0, 1 ]) and
    scmp($d, {D => [{U => 0},{A => 1}]}, "[0] vs [0,1]")
);

ok($d = diff([ 0, 1 ], [ 0 ]) and
    scmp($d, {D => [{U => 0},{R => 1}]}, "[0,1] vs [0]")
);

ok($d = diff([ 0 ], [ 0, 1 ], 'noU' => 1) and
    scmp(
        $d,
        {D => [{A => 1,I => 1}]},
        "[0] vs [0,1], noU => 1"
    )
);

ok($d = diff([ 0, 1 ], [ 0 ], 'noU' => 1) and
    scmp(
        $d,
        {D => [{I => 1,R => 1}]},
        "[0,1] vs [0], noU => 1"
    )
);

# LCS
ok(
    $d = diff([ qw(a b c e h j l m n p) ], [ qw(b c d e f j k l m r s t) ]) and
    scmp(
        $d,
        {
            D => [
                {R => 'a'},
                {U => 'b'},
                {U => 'c'},
                {A => 'd'},
                {U => 'e'},
                {N => 'f',O => 'h'},
                {U => 'j'},
                {A => 'k'},
                {U => 'l'},
                {U => 'm'},
                {N => 'r',O => 'n'},
                {N => 's',O => 'p'},
                {A => 't'}
            ]
        },
        "qw(a b c e h j l m n p) vs qw(b c d e f j k l m r s t)"
    )
);

ok(
    $d = diff([ qw(a b c e h j l m n p) ], [ qw(b c d e f j k l m r s t) ], noU => 1) and
    scmp(
        $d,
        {
            D => [
                {R => 'a'},
                {A => 'd',I => 3},
                {I => 5,N => 'f',O => 'h'},
                {A => 'k',I => 7},
                {I => 10,N => 'r',O => 'n'},
                {I => 11,N => 's',O => 'p'},
                {A => 't',I => 12}
            ]
        },
        "qw(a b c e h j l m n p) vs qw(b c d e f j k l m r s t), noU => 1"
    )
);

$a = [ 0, 1, 2]; # must be considered as equal by ref (wo descending into it)
$b = $a;
ok($d = diff($a, $b) and
    scmp(
        $d,
        {U => [0,1,2]},
        "same ref arrays"
    )
);

my $sub_array = [ 0, [ 11, 12 ], 2 ];
$a = [ 0, [[ 100 ]], [ 20, 'a' ], 4 ];
$b = [ 0, [[ 100 ]], [ 20, 'b' ], 5 ];

$frozen_a = freeze($a);
$frozen_b = freeze($b);

ok($d = diff($a, $b) and
    scmp(
        $d,
        {D => [{U => 0},{U => [[100]]},{D => [{U => 20},{N => 'b',O => 'a'}]},{N => 5,O => 4}]},
        "complex array diff"
    )
);

ok($d = diff($a, $b, 'noU' => 1) and
    scmp(
        $d,
        {D => [{D => [{I => 1,N => 'b',O => 'a'}],I => 2},{I => 3,N => 5,O => 4}]},
        "same array, noU => 1"
    )
);

ok($frozen_a eq freeze($a) and $frozen_b eq freeze($b)); # original structs must remain unchanged

### hashes ###
ok($d = diff({}, { 'a' => 'va' }) and
    scmp($d, {A => {a => 'va'}}, "{} vs {a => 'va'}")
);

ok($d = diff({}, { 'a' => 'va' }, 'noA' => 1) and
    scmp($d, {}, "{} vs {a => 'va'}, noA => 1")
);

ok($d = diff({ 'a' => 'va' }, {}) and
    scmp($d, {R => {a => 'va'}}, "{a => 'va'} vs {}")
);

ok($d = diff({ 'a' => 'va' }, {}, 'noR' => 1) and
    scmp($d, {}, "{a => 'va'} vs {}, noR => 1")
);

ok(
    $d = diff(
        {a =>{aa => {aaa => 'aaav'}}},
        {a =>{aa => {aaa => 'aaan'}}},
    ) and
    scmp(
        $d,
        {D => {a => {D => {aa => {D => {aaa => {N => 'aaan',O => 'aaav'}}}}}}},
        "HASH: deep single-nested changed"
    )
);

ok($d = diff({ 'a' => { 'aa' => { 'aaa' => 'vaaaa' }}}, {}, 'trimR' => 1) and
    scmp($d, {R => {a => undef}}, "{a => {aa => {aaa => 'vaaaa'}}} vs {}, trimR => 1")
);

ok($d = diff({ 'a' => { 'aa' => { 'aaa' => 'vaaaa' }}, 'b' => 'vb'}, { 'b' => 'vb' }, 'trimR' => 1) and
    scmp(
        $d,
        {D => {a => {R => undef},b => {U => 'vb'}}},
        "{a => {aa => {aaa => 'vaaaa'}},b => 'vb'} vs {b => 'vb'}, trimR => 1"
    )
);

ok($d = diff({ 'a' => 'va' }, { 'a' => 'vb' }, 'noO' => 1) and
    scmp($d, {N => {a => 'vb'}}, "{a => 'va'} vs {a => 'vb'}, noO => 1")
);

ok($d = diff({ 'a' => 'va' }, { 'a' => 'vb' }, 'noN' => 1) and
    scmp($d, {O => {a => 'va'}}, "{a => 'va'} vs {a => 'vb'}, noN => 1")
);

$a = { 'a' => 'a1', 'b' => { 'ba' => 'ba1', 'bb' => 'bb1' }, 'c' => 'c1' };
$b = { 'a' => 'a1', 'b' => { 'ba' => 'ba2', 'bb' => 'bb1' }, 'd' => 'd1' };

$frozen_a = freeze($a);
$frozen_b = freeze($b);

ok($d = diff($a, $b) and
    scmp(
        $d,
        {
            D => {
                a => {U => 'a1'},
                b => {D => {ba => {N => 'ba2',O => 'ba1'},bb => {U => 'bb1'}}},
                c => {R => 'c1'},
                d => {A => 'd1'}
            }
        },
        "complex hash"
    )
);

ok($d = diff($a, $b, 'noU' => 1) and
    scmp(
        $d,
        {D => {b => {D => {ba => {N => 'ba2',O => 'ba1'}}},c => {R => 'c1'},d => {A => 'd1'}}},
        "complex hash, noU => 1"
    )
);

ok($frozen_a eq freeze($a) and $frozen_b eq freeze($b)); # original structs must remain unchanged

### mixed structures ###
$a = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 4 ]}}, 8 ]};
$b = { 'a' => [ { 'aa' => { 'aaa' => [ 7, 3 ]}}, 8 ]};

$frozen_a = freeze($a);
$frozen_b = freeze($b);

ok($d = diff($a, $b) and
    scmp(
        $d,
        {D => {a => {D => [{D => {aa => {D => {aaa => {D => [{U => 7},{N => 3,O => 4}]}}}}},{U => 8}]}}},
        "mixed structure"
    )
);

ok($d = diff($a, $b, noO => 1, noU => 1) and
    scmp(
        $d,
        {D => {a => {D => [{D => {aa => {D => {aaa => {D => [{I => 1,N => 3}]}}}}}]}}},
        "mixed structure, noO => 1, noU => 1"
    )
);

ok($d = diff($a, $a, 'noU' => 1) and scmp($d, {}, "mixed structure to itself, noU => 1"));

ok($d = diff($a, $a) and freeze($d->{'U'}) eq $frozen_a);

ok($frozen_a eq freeze($a) and $frozen_b eq freeze($b)); # original structs must remain unchanged
