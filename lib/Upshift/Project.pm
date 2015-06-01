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

method lang ($lang is copy) {
    $lang .= lc;
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
    $!path = $path.IO if $path.defined;
    $!gen-path = $gen-path.IO if $gen-path.defined;
}

method build (Bool :$force = False) {
    use fatal;

    my %gen-files;
    if $force {
        rm_rf $.gen-path;
        $.gen-path.mkdir;
    } else {
        if $.gen-path.e {
            %gen-files = find(dir => $.gen-path).map:
                { .absolute => $_ };
        } else {
            $.gen-path.mkdir;
        }
    }

    my $up-ext = rx:i/\.up$/;
    my $gen-str = $.gen-path.absolute;
    my &lookup = -> $_ { self.name: $_ };
    for @!src-files {
        my $is-up = so $_ ~~ $up-ext;
        my $dest-path = $.gen-path.child: $_;
        $dest-path = $dest-path.absolute.subst($up-ext,'').IO if $is-up;
        my $dest-dir = $dest-path.parent;
        $dest-dir.mkdir unless $dest-dir.e;
        my $path-str = $dest-path.relative($.path);
        if %gen-files && $dest-path.e {
            %gen-files{$dest-path.absolute} :delete;
            my $dir = $dest-dir;
            my $dir-str = $dir.absolute;
            while $dir-str.chars > $gen-str.chars {
                %gen-files{$dir-str} :delete;
                $dir .= parent;
                $dir-str = $dir.absolute;
            }
            if !$is-up && $dest-path.modified > $.src-path.child($_).modified {
                self.log: "Skipping up-to-date $path-str";
                next;
            }
            .unlink;
        }
        when !$is-up {
            self.log: "Including $path-str";
            $.src-path.child($_).copy: $.gen-path.child: $_;
        }
        self.log: "Building $path-str";
        self.log-inc;
        my $obj = self.name: $_;
        my $lang = self.lang: $_;
        $lang.to-file: $dest-path, $obj, &lookup;
        self.log-dec;
    }

    for %gen-files.sort.reverse».value {
        self.log: "Removing nonexistent $_.relative($.path)";
        .d ?? .rmdir !! .unlink;
    }
}

has $!log-depth = 0;
method log ($msg) { note '    ' x $!log-depth ~ $msg }
method log-inc { ++$!log-depth }
method log-dec { $!log-depth && --$!log-depth }



# vim: ft=perl6
