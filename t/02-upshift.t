use v6;

use Test;
plan 22;

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
    'Parse insert and bare literal';
is $def.to-string(:name<World>), 'Hello, World!', 'Output insert';

$def = Upshift::Language::Upshift.from-string: '^?name \'hey I know you\';';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse single-clause boolean conditional and single quote';
is $def.to-string(:name<foo>), 'hey I know you', 'Output true conditional';
is $def.to-string, '', 'Don\'t output false conditional';

$def = Upshift::Language::Upshift.from-string:
    '^?name "hey I know you" ! "howdy stranger";';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-else boolean conditional and double quote';
is $def.to-string(:name<Camelia>), 'hey I know you', 'Output true conditional';
is $def.to-string, 'howdy stranger', 'Output false conditional';

$def = Upshift::Language::Upshift.from-string:
    q{^?name
        Superman "It's a bird!  It's a plane!" !
        'Admiral Ackbar' "It's a trap!" !
        ^?name
            ^"It's a ... ^name;?^" !
            'What is that?};
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-elsif-else, nesting, upquote, and implied terminators';
is $def.to-string(:name<Superman>), "It's a bird!  It's a plane!",
    'Output if conditional';
is $def.to-string(:name<Admiral Ackbar>), "It's a trap!",
    'Output elsif conditional';
is $def.to-string(:name<blue box>), "It's a ... blue box?",
    'Output else/true conditional';
is $def.to-string, 'What is that?', 'Output else/false conditional';

my $echo = Upshift::Language::Upshift.from-string: '^msg';
$def = Upshift::Language::Upshift.from-string:
    q{^echo msg 'eins '^"zwei ^"^echo msg drei};
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse compound literal';
is $def.to-string(:$echo), 'eins zwei drei',
    'Output compound literal';

done;
