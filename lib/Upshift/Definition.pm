unit class Upshift::Definition;

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

method reduce (&lookup) {
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
        reduce-part $part, &new-lookup;
    }

    when ?$.conditional {
        my $cond-val = lookup @.children[0];
        unless defined $cond-val {
            #note " * Assuming empty string for undefined name '@.children[0]'";
            $cond-val = '';
        }
        $cond-val = reduce-part $cond-val, &lookup;

        my $i = @.conditions.first: -> $i { $cond-val ~~ @.children[$i] };
        when $i.defined { reduce-part @.children[$i+1], &lookup }
        when ?$.has-else { reduce-part @.children[*-1], &lookup }
        '';
    }
    
    my @new;
    for @.children.map({ reduce-part $_, &lookup }) {
        if $_ ~~ Str && @new && @new[*-1] ~~ Str {
            @new[*-1] ~= $_;
        } else {
            @new.push: $_;
        }
    }
    
    when @new == 1 && @new[0] ~~ Str { @new[0] }

    self.new: :children(@new);
}

multi sub reduce-part (::?CLASS $p, &lookup) { $p.reduce: &lookup }
multi sub reduce-part ($p, &lookup?) { ~$p }

# vim: ft=perl6
