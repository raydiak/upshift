unit class Upshift::Project;

use File::Find;
use Shell::Command;

use Upshift::Language::Upshift;
use Upshift::Language::Text;

# project root
has IO::Path $.path is required;

# destination for generated output
has IO::Path $.gen-path = $!path.child: 'gen';

# source files to process into gen
has IO::Path $.src-path = $!path.child: 'src';
has @.src-files = find(dir => $!src-path)».relative($!src-path)».IO.sort;

# files for use but not outputted into gen
has IO::Path $.lib-path = $!path.child: 'lib';
has @.lib-files = $!lib-path.e ??
    find(dir => $!lib-path)».relative($!lib-path)».IO.flat !! [];

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
multi method name (Str(Cool) $name, :&lookup) is rw { %!names{$name} //= self!load: $name }
multi method name ($name is copy, :&lookup) is rw {
    $name .= to-string: &lookup;
    %!names{$name} //= self!load: $name;
}

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
    my &lookup = -> $_ { self.name: $_, :&lookup };
    for @!src-files {
        my $src-path = $.src-path.child: $_;
        my $dest-path = $.gen-path.child: $_;
        when $src-path.d {
            if %gen-files && $dest-path.e {
                %gen-files{$dest-path.absolute} :delete;
            } else {
                $dest-path.mkdir;
            }
        }
        my $is-up = so $_ ~~ $up-ext;
        $dest-path = $dest-path.absolute.subst($up-ext,'').IO if $is-up;
        my $path-str = $dest-path.relative($.path);
        if %gen-files && $dest-path.e {
            %gen-files{$dest-path.absolute} :delete;
            when !$is-up &&
                $dest-path.s == $src-path.s &&
                $dest-path.modified > $src-path.modified {
                self.log: "Skipping up-to-date $path-str";
            }
            .unlink;
        }
        when !$is-up {
            self.log: "Including $path-str";
            $src-path.copy: $.gen-path.child: $_;
        }
        self.log: "Building $path-str";
        self.log-inc;
        my $obj = self.name: $_, :&lookup;
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
