unit role Upshift::Language[Grammar $grammar, Any $actions];

method grammar { $grammar }
method actions { $actions }
method read (Str:D $str) {
    $grammar.parse($str, actions => $actions.new).?made //
    die "Parse failed";
}

# vim: ft=perl6
