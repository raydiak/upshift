use v6;

use Test;
plan 20;

use lib $?FILE.IO.parent.parent.child: 'lib';
use lib $?FILE.IO.parent.parent.child('blib').child: 'lib';

use Upshift::Language::Upshift;

ok 1, 'Module loads successfully';

my $def = Upshift::Language::Upshift.from-string: '';
isa-ok $def, Upshift::Language::Upshift::Definition, 'Parse empty string';
is $def.to-string, '', 'Round-trip empty string';

$def = Upshift::Language::Upshift.from-string: "abc def\nghi\n";
isa-ok $def, Upshift::Language::Upshift::Definition, 'Parse literal text';
is $def.to-string, "abc def\nghi\n", 'Output preserves trailing newline';

$def = Upshift::Language::Upshift.from-string: 'abc^^def';
isa-ok $def, Upshift::Language::Upshift::Definition, 'Parse literal escape';
is $def.to-string, 'abc^def', 'Output literal escape';

$def = Upshift::Language::Upshift.from-string: 'Hello, ^name;!';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse inserts and bare literals';
is $def.to-string(:name<World>), 'Hello, World!', 'Output inserts';

$def = Upshift::Language::Upshift.from-string: '^?name \'hey I know you\';';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse single-clause boolean conditionals and single quotes';
is $def.to-string(:name<foo>), 'hey I know you', 'Output true conditionals';
is $def.to-string, '', 'Don\'t output false conditionals';

$def = Upshift::Language::Upshift.from-string:
    '^?name "hey I know you" ! "howdy stranger";';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-else boolean conditionals and double quotes';
is $def.to-string(:name<Camelia>), 'hey I know you', 'Output true conditionals';
is $def.to-string, 'howdy stranger', 'Output false conditionals';

$def = Upshift::Language::Upshift.from-string:
    q{^?name
        Superman "It's a bird!  It's a plane!" !
        'Admiral Ackbar' "It's a trap!" !
        ^?name
            ^"It's a ... ^name;?^" !
            'What is that?};
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-elsif-else, nesting, upshifts, and implied terminators';
is $def.to-string(:name<Superman>), "It's a bird!  It's a plane!",
    'Output if conditional';
is $def.to-string(:name<Admiral Ackbar>), "It's a trap!",
    'Output elsif conditional';
is $def.to-string(:name<blue box>), "It's a ... blue box?",
    'Output else/true conditional';
is $def.to-string, 'What is that?', 'Output else/false conditional';

done;
