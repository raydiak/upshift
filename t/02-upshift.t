use v6;

use Test;
plan 20;

use lib $?FILE.IO.parent.parent.child: 'lib';
use lib $?FILE.IO.parent.parent.child('blib').child: 'lib';

use Upshift::Language::Upshift;

ok 1, 'Module loads successfully';

my %names;
my &n = sub ($_) { %names{$_} };
my $def = Upshift::Language::Upshift.from-string:
    '';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse emtpy string';
is $def.to-string(&n), '',
    'Round-trip empty string';

$def = Upshift::Language::Upshift.from-string:
    "abc def\nghi\n";
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse literal text';
is $def.to-string(&n), "abc def\nghi\n",
    'Round-trip preserves trailing newline';

$def = Upshift::Language::Upshift.from-string:
    'abc^^def';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse literal escape';
is $def.to-string(&n), 'abc^def',
    'Output literal escape';

%names<name> = 'World';
$def = Upshift::Language::Upshift.from-string:
    'Hello, ^name;!';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse inserts and barewords';
is $def.to-string(&n), 'Hello, World!',
    'Output inserts';

$def = Upshift::Language::Upshift.from-string:
    '^?name \'hey I know you\';';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse single-clause boolean conditionals and single quotes';
is $def.to-string(&n), 'hey I know you',
    'Output true conditionals';
%names = ();
is $def.to-string(&n), '',
    'Don\'t output false conditionals';

$def = Upshift::Language::Upshift.from-string:
    '^?name "hey I know you" ! "howdy stranger";';
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-else boolean conditionals and double quotes';
is $def.to-string(&n), 'howdy stranger',
    'Output false conditionals';
%names<name> = 'Camelia';
is $def.to-string(&n), 'hey I know you',
    'Output true conditionals';

$def = Upshift::Language::Upshift.from-string:
    q{^?name
        Superman "It's a bird!  It's a plane!" !
        'Admiral Ackbar' "It's a trap!" !
        ^?name
            ^"It's a ... ^name;?^" !
            'What is that?};
isa-ok $def, Upshift::Language::Upshift::Definition,
    'Parse if-elsif-else conditionals, nested conditionals, upshifts, and implied terminators';
is $def.to-string(&n), 'It\'s a ... Camelia?',
    'Output else/true conditional';
%names = ();
is $def.to-string(&n), 'What is that?',
    'Output else/false conditional';
%names<name> = 'Superman';
is $def.to-string(&n), "It's a bird!  It's a plane!",
    'Output if conditional';
%names<name> = 'Admiral Ackbar';
is $def.to-string(&n), "It's a trap!",
    'Output elsif conditional';

done;
