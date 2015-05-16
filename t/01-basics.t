use v6;

use Test;
plan 1;

use lib $?FILE.IO.parent.parent.child: 'lib';
use lib $?FILE.IO.parent.parent.child('blib').child: 'lib';

use Upshift;

ok 1, 'Module loads successfully';

done;
