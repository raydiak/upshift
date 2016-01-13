use v6;

use Test;
plan 1;

use lib $?FILE.IO.parent.parent.child('lib').Str;
use lib $?FILE.IO.parent.parent.child('blib').child('lib').Str;

use Upshift;

ok 1, 'Module loads successfully';

done-testing;
