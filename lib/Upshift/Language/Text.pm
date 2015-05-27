use Upshift::Language;

class Upshift::Language::Text does Upshift::Language[
    my grammar { token TOP { .* } },
    my class { method TOP ($/) { make ~$/ } }
] { }

# vim: ft=perl6
