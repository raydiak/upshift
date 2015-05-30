unit role Upshift::Language[Grammar $grammar, Any $actions];

method from-file (IO::Path:D $file) {
    use fatal;
    self.from-string: $file.slurp.chomp;
}

method from-string (Str:D $str) {
    $grammar.parse($str, actions => $actions.new).?made //
        die "Parse failed"
}

method to-file (IO::Path:D $file, $obj, |args) {
    use fatal;
    my $build = self.to-string: $obj, |args;
    $build ~= "\n" unless $build.ends-with: "\n";
    $file.spurt: $build;
}

multi method to-string (Str $obj, |) { $obj }
multi method to-string ($obj, |args) { $obj.to-string: |args }

# vim: ft=perl6
