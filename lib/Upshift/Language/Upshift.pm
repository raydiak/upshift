use Upshift::Language;
use Upshift::Language::Upshift::Definition;

# some of these probably ought to be renamed

grammar Upshift::Language::Upshift::Grammar {
    token TOP { ( <literal> || <escape> )* }
    token literal { ( <literal-normal> || <literal-escape> )+ }
    token literal-normal { <-[\^]>+ }
    token literal-escape { '^^' }
    token escape {
        <escape-block> ||
        <escape-statement> #`[[[ ||
        <!before <[\!\;]>> # don't error on region delimiters (just fail)
            { die "Invalid escape sequence at position $/.from()" }
            maintenance and performance cost too high ]]]
    }
    token escape-block { \^ <.ws> \{ ~ \} .*? { die "Escape block NYI" } }
    token escape-statement {
        \^ <.ws> [
            <escape-statement-conditional> ||
            <escape-statement-call>
        ] <.ws> [ \; || $ ]
    }
    token escape-statement-call {
        <name=.escape-literal-bare>
        [ \s+ <param=.escape-literal>* % \s+ ]?
    }
    rule escape-statement-conditional
        {\? <escape-statement-conditional-if>
        <escape-statement-conditional-elsif>*
        <escape-statement-conditional-else>?}
    token escape-statement-conditional-if {
        <escape-statement-conditional-if-value> ||
        <escape-statement-conditional-if-true>
    }
    rule escape-statement-conditional-if-true
        {<name=.escape-literal-bare>\s+ <literal=.escape-literal>}
    rule escape-statement-conditional-if-value
        {<name=.escape-literal-bare>\s+
        <value=.escape-literal>\s+
        <literal=.escape-literal>}
    rule escape-statement-conditional-elsif
        {\!
        <value=.escape-literal>
        <literal=.escape-literal>}
    rule escape-statement-conditional-else {\! <literal=.escape-literal>}
    
    token escape-literal {
        <escape-literal-bare> ||
        <escape-literal-quoted> ||
        <escape-literal-doublequoted> ||
        <escape-literal-upquoted> ||
        <escape-literal-updoublequoted> ||
        #<escape-literal-symbol> ||
        <escape> #`[[[ TODO
            making this work everywhere probably includes more ::Definition changes
                and possibly ::Project as well
            which probably means upquotes and symbols have the same issues
            also, making this work seems mutually exclusive with symbol (above)
            starting to need tests ]]]
    }
    token escape-literal-bare { <[ \w \- \/ \\ \. ]>+ }
    token escape-literal-quoted {
        \' (
            <escape-literal-quoted-literal> ||
            <escape-literal-quoted-literal-quote> ||
            <escape-literal-quoted-literal-escape>
        )* [\' || $]
    }
    token escape-literal-quoted-literal { <-[\'\^]>+ }
    rule escape-literal-quoted-literal-escape {\^ \^}
    rule escape-literal-quoted-literal-quote {\^ \'}
    token escape-literal-doublequoted {
        \" (
            <escape-literal-doublequoted-literal> ||
            <escape-literal-doublequoted-literal-quote> ||
            <escape-literal-doublequoted-literal-escape>
        )* [\" || $]
    }
    token escape-literal-doublequoted-literal { <-[\"\^]>+ }
    rule escape-literal-doublequoted-literal-escape {\^ \^}
    rule escape-literal-doublequoted-literal-quote {\^ \"}
    rule escape-literal-upquoted {\^ \'<TOP>[\^ \'||$]}
    rule escape-literal-updoublequoted {\^ \"<TOP>[\^ \"||$]}
    #token escape-literal-symbol { \^ <escape-literal-bare> }
}

class Upshift::Language::Upshift::Actions {
    has @.cond-names;

    method TOP ($/) { make Upshift::Language::Upshift::Definition.new: :children($0».values».made) }
    method literal ($/) { make join '', $0».values».made }
    method literal-normal ($/) { make ~$/ }
    method literal-escape ($/) { make '^' }
    method escape ($/) { make $/.values[0].made }
    method escape-statement ($/) { make $/.values[0].made }
    method escape-statement-call ($/) {
        make Upshift::Language::Upshift::Definition::Call.new: :children(
            $<name>.made,
            @($<param>».made)
        )
    }
    method escape-statement-conditional ($/) {
        my $if = $<escape-statement-conditional-if>.values[0];
        my @children = 
            $if<name>.made,
            $if<value>.?made // * ne '',
            $if<literal>.made,
            @<escape-statement-conditional-elsif>.map({
                .<value>.?made // * ne '',
                .<literal>.made
            }),
            $<escape-statement-conditional-else><literal>.?made // ();
        
        make Upshift::Language::Upshift::Definition::Conditional.new: :@children;
    }
    method escape-literal ($/) { make $/.values[0].made }
    method escape-literal-bare ($/) { make ~$/ }
    method escape-literal-quoted ($/) { make join '', $0».values».made }
    method escape-literal-quoted-literal ($/) { make ~$/ }
    method escape-literal-quoted-literal-escape ($/) { make '^' }
    method escape-literal-quoted-literal-quote ($/) { make "'" }
    method escape-literal-doublequoted ($/) { make join '', $0».values».made }
    method escape-literal-doublequoted-literal ($/) { make ~$/ }
    method escape-literal-doublequoted-literal-escape ($/) { make '^' }
    method escape-literal-doublequoted-literal-quote ($/) { make '"' }
    method escape-literal-upquoted ($/) { make $<TOP>.made }
    method escape-literal-updoublequoted ($/) { make $<TOP>.made }
    #`[[[
    method escape-literal-symbol ($/) {
        make Upshift::Language::Upshift::Definition::Call.new:
            children => $<escape-literal-bare>.made;
    }
    #]]]
}

class Upshift::Language::Upshift does Upshift::Language[
    Upshift::Language::Upshift::Grammar,
    Upshift::Language::Upshift::Actions
] { }

# vim: ft=perl6
