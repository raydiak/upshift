unit role Upshift::Language[Grammar $grammar, Any $actions];

method from-file (IO::Path:D $file) {
    self.from-string: $file.slurp.chomp;
}
method from-string (Str:D $str) {
    $grammar.parse($str, actions => $actions.new).?made //
        die "Parse failed";
}

# vim: ft=perl6
