unit class Upshift::Project;

use File::Find;
use Shell::Command;

use Upshift::Language::Upshift;
use Upshift::Language::Text;

# project root
has IO::Path $.path = die 'path is required';

# destination for generated output
has IO::Path $.gen-path = $!path.child: 'gen';

# source files to process into gen
has IO::Path $.src-path = $!path.child: 'src';
has IO::Path @.src-files =
    find(:dir($!src-path), :type<file>)».relative($!src-path)».IO;

# files for use but not outputted into gen
has IO::Path $.lib-path = $!path.child: 'lib';
has IO::Path @.lib-files = $!lib-path.e ??
    find(:dir($!lib-path), :type<file>)».relative($!lib-path)».IO !! ();

has %!langs =
    up  => Upshift::Language::Upshift,
    txt => Upshift::Language::Text;

method lang ($lang) {
    %!langs{$lang}:exists ??
        %!langs{$lang} !!
        %!langs<txt>
}

has %!names;
method name ($name) is rw { %!names{$name} //= self!load: $name }

method !load ($name) {
    for <src lib> {
        my @files := self."$_\-files"();
        next unless $name ~~ @files».Str.any;
        my $lang = self.lang: $name.IO.extension;
        self.log: "Loading $name";
        return $lang.from-file: self."$_\-path"().child($name);
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

    my &lookup = -> $_ { self.name: $_ };
    for @!src-files -> $_ is copy {
        my $dest-path = $.gen-path.child: $_;
        my $dest-dir = $dest-path.parent;
        $dest-dir.mkdir unless $dest-dir.e;
        when $_ !~~ /\.up$/ {
            self.log: "Including $_.relative($.path)";
            $.src-path.child($_).copy: $.gen-path.child: $_;
        }
        my $obj = self.name: $_;
        s/\.up$//;
        $dest-path = $dest-path.absolute.subst(rx/\.up$/,'').IO;
        unless $obj ~~ Str {
            self.log: "Building $_";
            $obj .= build: &lookup;
            die "Error building $_" unless $obj ~~ Str;
        }
        self.log: "Writing $dest-path.relative($.path)";
        $dest-path.spurt: $obj;
    }
}

method log ($msg) { note $msg }



# vim: ft=perl6
