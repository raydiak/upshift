unit class Upshift::Project;

use File::Find;
use Shell::Command;

use Upshift::Language::Upshift;

has $.in-lang = Upshift::Language::Upshift;

# project root
has IO::Path $.path = die 'path is required';

# destination for generated output
has IO::Path $.gen-path = $!path.child: 'gen';

# source files/templates to convert into gen
has IO::Path $.src-path = $!path.child: 'src';
has IO::Path @.src-files =
    find(:dir($!src-path), :type<file>)».relative($!src-path)».IO;

# processed template library for use but not outputted into gen
has IO::Path $.lib-path = $!path.child: 'lib';
has IO::Path @.lib-files = $!lib-path.e ??
    find(:dir($!lib-path), :type<file>)».relative($!lib-path)».IO !! ();

# included in gen but not processed as templates
has IO::Path $.inc-path = $!path.child: 'inc';
has IO::Path @.inc-files = $!inc-path.e ??
    find(:dir($!inc-path), :type<file>)».relative($!inc-path)».IO !! ();

# raw unprocessed resources not copied into gen but available to use
has IO::Path $.res-path = $!path.child: 'res';
has IO::Path @.res-files = $!res-path.e ??
    find(:dir($!res-path), :type<file>)».relative($!res-path)».IO !! ();

has %!names;
method name ($name) is rw { %!names{$name} //= self!load: $name }

method !load ($name) {
    for <src lib inc res> {
        my @files := self."$_\-files"();
        if $name ~~ @files».Str.any {
            self.log: "Reading $_/$name";
            if $_ ~~ <src lib>.any {
                my $str = self."$_\-path"().child($name).slurp;
                self.log: "Parsing $name";
                return $.in-lang.read: $str.chomp;
            }
            return self."$_\-path"().child($name).slurp;
        }
    }
    return Any;
}

submethod BUILD (:$path?, :$gen-path?) {
    if $path.defined {
        die 'The empty string is not allowed as a path (Upshift::Project.path); use "." to represent the current directory, or an undefined value to use the default' if $path eq '';
        $!path = $path.IO;
    }
    if $gen-path.defined {
        die 'The empty string is not allowed as a path (Upshift::Project.gen-path); use "." to represent the current directory, or an undefined value to use the default, and take special care with the gen-path as its existing contents will be entirely erased' if $gen-path eq '';
        $!gen-path = $gen-path.IO;
    }
}

method build () {
    use fatal;

    rm_rf $.gen-path if $.gen-path.e;
    $.gen-path.mkdir;

    for @!inc-files {
        self.log: "Including $_";
        $.inc-path.child($_).copy: $.gen-path.child: $_;
    }

    my &lookup = -> $_ { self.name: $_ };
    for @!src-files {
        self.log: "Generating $_";
        my $def = self.name: $_;
        my $dest-path = $.gen-path.child: $_;
        my $dest-dir = $dest-path.parent;
        $dest-dir.mkdir unless $dest-dir.e;
        my $out = $def.reduce: &lookup;
        die "Error reducing $_" unless $out ~~ Str;
        $out ~= "\n" unless $out.ends-with: "\n";
        self.log: "Writing $dest-path.relative($.path)";
        $dest-path.spurt: $out;
    }
}

method log ($msg) { note $msg }



# vim: ft=perl6
