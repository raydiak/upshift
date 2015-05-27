unit class Upshift::Language::Upshift::Definition;

has @.children;

has $.call;
    has $.name = $!call ?? @!children[0] !! Any;
    has %.params = $!call && @!children > 1 ??
        @!children[1..*] !! ();

has $.conditional;
    has $.has-else = (@!children %% 2 if $!conditional);
    has @.conditions = (1, 3 ...^ @!children - 1 if $!conditional);

method gist {
    self.^name ~
    ' :call' x ?$.call ~
    ' :conditional' x ?$.conditional ~
    @.children.map( "\n" ~ *.gist.indent: 4 ).join
}

method to-string (&lookup) {
    when !@.children { '' }
    when ?$.call {
        my &new-lookup = %.params ??
            -> $_ {
                %.params{$_}:exists ??
                    %.params{$_} !!
                    lookup $_
            } !!
            &lookup;
        my $part = lookup $.name;
        unless defined $part {
            #note " * Assuming empty string for undefined name '$.name'";
            $part = '';
        }
        part-to-string $part, &new-lookup;
    }

    when ?$.conditional {
        my $cond-val = lookup @.children[0];
        unless defined $cond-val {
            #note " * Assuming empty string for undefined name '@.children[0]'";
            $cond-val = '';
        }
        $cond-val = part-to-string $cond-val, &lookup;

        my $i = @.conditions.first: -> $i { $cond-val ~~ @.children[$i] };
        when $i.defined { part-to-string @.children[$i+1], &lookup }
        when ?$.has-else { part-to-string @.children[*-1], &lookup }
        '';
    }
    
    my @new;
    for @.children.map({ part-to-string $_, &lookup }) {
        if $_ ~~ Str && @new && @new[*-1] ~~ Str {
            @new[*-1] ~= $_;
        } else {
            @new.push: $_;
        }
    }
    
    when @new == 1 && @new[0] ~~ Str { @new[0] }

    self.new: :children(@new);
}

multi sub part-to-string (::?CLASS $p, &lookup) { $p.to-string: &lookup }
multi sub part-to-string ($p, &lookup?) { ~$p }

# vim: ft=perl6
