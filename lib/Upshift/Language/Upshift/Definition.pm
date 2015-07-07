class Upshift::Language::Upshift::Definition {
    has $.root is rw;
    has @.children;

    method gist {
        self.^name ~
        @.children.map( "\n" ~ *.gist.indent: 4 ).join
    }

    multi method to-string (*%lookup, |args) {
        self.to-string: %lookup, |args
    }
    multi method to-string (%lookup, |args) {
        %lookup ??
            self.to-string: -> $_ { %lookup{$_} }, |args !!
            self.to-string: -> $ {}, |args;
    }
    multi method to-string (&lookup, :&root is copy, |args) {
        when !@.children { '' }

        &root = &lookup if $.root;
        my @new;
        for @.children.map({ self.part-to-string: $_, &lookup, :&root, |args }) {
            if $_ ~~ Str && @new && @new[*-1] ~~ Str {
                @new[*-1] ~= $_;
            } else {
                @new.push: $_;
            }
        }

        when @new == 1 && @new[0] ~~ Str { @new[0] }

        self.new: :children(@new);
    }

    multi method part-to-string (::?CLASS $p, |args) { $p.to-string: |args }
    multi method part-to-string (Str(Cool) $p, |) { $p }
    multi method part-to-string ($p, |) { $p }
}

class Upshift::Language::Upshift::Definition::Call {
    also is Upshift::Language::Upshift::Definition;

    has $.subcall = False;
    has $.invocant = self.subcall ??
        self.children[*-1] !! self.children[0];
    has %.params{Any} = self.children < 2 ?? () !!
        self.subcall ??
            self.children[0..*-2] !!
            self.children[1..*-1];
    has %.direct{Any};
    has %.defer{Any};

    #`[[[
    submethod BUILD (:$!name, :%!params) {
        die "$?CLASS.^name() requires one or more \@.children"
            unless self.children;
    }
    ]]]

    method !build-lookup (&lookup, :&root is copy, |args) {
        if %.params {
            my %defer = %.defer.map: -> $_ {
                self.part-to-string(.key, &lookup, :&root, |args) => .value
            } if %.defer;
            my %params = %defer ??
                %.params.map: -> $_ {
                    my $key = self.part-to-string(.key, &lookup, :&root, |args);
                    $key => ( %defer{$key}:exists ??
                        %defer{$key} !!
                        self.part-to-string(.value, &lookup, :&root, |args)
                    );
                } !!
                %.params.map: -> $_ {
                    self.part-to-string(.key, &lookup, :&root, |args) =>
                    self.part-to-string(.value, &lookup, :&root, |args)
                };

            if %.direct {
                my %direct = %defer ??
                    %.direct.map: -> $_ {
                        my $key = self.part-to-string(.key, &lookup, :&root, |args);
                        $key => ( %defer{$key}:exists ??
                            %defer{$key} !!
                            self.part-to-string(.value, &lookup, :&root, |args)
                        );
                    } !!
                    %.direct.map: -> $_ {
                        self.part-to-string(.key, &lookup, :&root, |args) =>
                        self.part-to-string(.value, &lookup, :&root, |args)
                    };
                my &inner-root = &root ??
                    -> $_ is copy {
                        $_ .= to-string: &lookup, :&root, |args unless $_ ~~ Str;
                        root($_) // %direct{$_};
                    } !!
                    -> $_ is copy {
                        $_ .= to-string: &lookup, :&root, |args unless $_ ~~ Str;
                        %direct{$_};
                    };
                -> $_ is copy {
                    $_ .= to-string: &lookup, :&root, |args unless $_ ~~ Str;
                    if %direct{$_}:exists {
                        inner-root $_;
                    } else {
                        %params{$_} // lookup $_;
                    }
                }
            } else {
                -> $_ is copy {
                    $_ .= to-string: &lookup, :&root, |args unless $_ ~~ Str;
                    %params{$_} // lookup $_;
                };
            }
        } else {
            &lookup;
        }
    }

    multi method to-string (&lookup, |args) {
        my $part = $.subcall ?? $.invocant !!
            lookup self.part-to-string: $.invocant, &lookup, |args;
            #lookup $.invocant;
        unless defined $part {
            #note " * Assuming empty string for undefined name '$.name'";
            $part = '';
        }
        return ~$part if $part ~~ Cool;

        self.part-to-string:
            $part,
            self!build-lookup(&lookup, |args),
            |args;
    }
}

class Upshift::Language::Upshift::Definition::Conditional {
    also is Upshift::Language::Upshift::Definition;

    has $.has-else = self.children %% 2;
    has @.conditions = 1, 3 ...^ self.children - 1;

    #`[[[
    submethod BUILD (:$!has-else, :@!conditions) {
        die "$?CLASS.^name() requires two or more \@.children"
            unless self.children >= 2;
    }
    ]]]

    multi method to-string (&lookup, |args) {
        my $cond-val = lookup @.children[0];
        unless defined $cond-val {
            #note " * Assuming empty string for undefined name '@.children[0]'";
            $cond-val = '';
        }
        $cond-val = self.part-to-string: $cond-val, &lookup, |args;

        my $i = @.conditions.first: -> $i {
            $cond-val ~~ self.part-to-string: @.children[$i], &lookup, |args
        };
        when $i.defined { self.part-to-string: @.children[$i+1], &lookup, |args }
        when ?$.has-else { self.part-to-string: @.children[*-1], &lookup, |args }
        '';
    }
}

# vim: ft=perl6
