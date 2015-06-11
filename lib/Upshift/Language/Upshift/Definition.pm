class Upshift::Language::Upshift::Definition {
    has @.children;

    method gist {
        self.^name ~
        @.children.map( "\n" ~ *.gist.indent: 4 ).join
    }

    multi method to-string (*%lookup) {
        %lookup ??
            self.to-string: %lookup !!
            self.to-string: -> $ {}
    }
    multi method to-string (%lookup) {
        %lookup ??
            self.to-string: -> $name { %lookup{$name} } !!
            self.to-string: -> $ {}
    }
    multi method to-string (&lookup) {
        when !@.children { '' }

        my @new;
        for @.children.map({ self.part-to-string: $_, &lookup }) {
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
    multi method part-to-string ($p, |) { $p.Str }
}

class Upshift::Language::Upshift::Definition::Call {
    also is Upshift::Language::Upshift::Definition;

    has $.subcall = False;
    has $.invocant = self.subcall ??
        self.children[*-1] !! self.children[0];
    has %.params = self.children < 2 ?? () !!
        self.subcall ??
            self.children[0..*-2] !!
            self.children[1..*-1];

    #`[[[
    submethod BUILD (:$!name, :%!params) {
        die "$?CLASS.^name() requires one or more \@.children"
            unless self.children;
    }
    ]]]

    method build-lookup (&lookup) {
        %.params ??
            -> $_ is copy {
                $_ .= to-string: &lookup unless $_ ~~ Str;
                %.params{$_}:exists ??
                    %.params{$_} !!
                    lookup $_
            } !!
            &lookup
    }

    multi method to-string (&lookup) {
        my &new-lookup = self.build-lookup: &lookup;
        my $part = $.subcall ?? $.invocant !! new-lookup $.invocant;
        unless defined $part {
            #note " * Assuming empty string for undefined name '$.name'";
            $part = '';
        }
        self.part-to-string: $part, &new-lookup;
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

    multi method to-string (&lookup) {
        my $cond-val = lookup @.children[0];
        unless defined $cond-val {
            #note " * Assuming empty string for undefined name '@.children[0]'";
            $cond-val = '';
        }
        $cond-val = self.part-to-string: $cond-val, &lookup;

        my $i = @.conditions.first: -> $i { $cond-val ~~ @.children[$i] };
        when $i.defined { self.part-to-string: @.children[$i+1], &lookup }
        when ?$.has-else { self.part-to-string: @.children[*-1], &lookup }
        '';
    }
}

# vim: ft=perl6
