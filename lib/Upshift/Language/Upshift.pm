use Upshift::Language;
use Upshift::Language::Upshift::Definition;

# some of these probably ought to be renamed

grammar Upshift::Language::Upshift::Grammar {
    token TOP { <uptop> }
    token uptop { ( <literal> || <escape> )* }
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
            <escape-statement-call> ||
            <escape-statement-subcall>
        ] <.ws> [ \; || $ ]
    }
    rule escape-statement-call {
        <name=.escape-literal>
        [<escape-statement-call-declaration> ]*
    }
    rule escape-statement-subcall {
        \= [<escape-statement-call-declaration> ]* <body=.escape-literal>}
    rule escape-statement-call-declaration {
        [
            [ <direct=[\*]> <defer=[\\]>? ] |
            [ <defer=[\\]> <direct=[\*]>? ]
        ]?
        <name=.escape-literal> <value=.escape-literal>
    }
    rule escape-statement-conditional
        {\? <escape-statement-conditional-if>
        <escape-statement-conditional-elsif>*
        <escape-statement-conditional-else>?}
    token escape-statement-conditional-if {
        <not=.escape-statement-conditional-not>? <.ws> [
            <escape-statement-conditional-if-value> ||
            <escape-statement-conditional-if-true>
        ]
    }
    rule escape-statement-conditional-if-true
        {<name=.escape-literal>\s+ <literal=.escape-literal>}
    rule escape-statement-conditional-if-value
        {<name=.escape-literal>\s+
        <value=.escape-literal>\s+
        <literal=.escape-literal>}
    rule escape-statement-conditional-elsif
        {\!
        <not=.escape-statement-conditional-not>?
        <value=.escape-literal>
        <literal=.escape-literal>}
    rule escape-statement-conditional-else {\! <literal=.escape-literal>}
    token escape-statement-conditional-not { \! }
    
    token escape-literal {
        (
            <escape-literal-bare> ||
            <escape-literal-quoted> ||
            <escape-literal-doublequoted> ||
            <escape-literal-upquoted> ||
            #<escape-literal-symbol> ||
            <escape> #`[[[ TODO
                making this work everywhere probably includes more ::Definition changes
                    and possibly ::Project as well
                which probably means upquotes and symbols have the same issues
                also, making this work seems mutually exclusive with symbol (above)
                starting to need tests ]]]
        )+
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
    rule escape-literal-upquoted {\^ \(<uptop>[\^ \)||$]}
    #token escape-literal-symbol { \^ <escape-literal-bare> }
}

class Upshift::Language::Upshift::Actions {
    method TOP ($/) {
        my $def = make $<uptop>.made;
        $def.root = True;
        $def;
    }
    method uptop ($/) {
        make Upshift::Language::Upshift::Definition.new:
            :children(@0».values.flat».made)
    }
    method literal ($/) { make join '', $0».values».made }
    method literal-normal ($/) { make ~$/ }
    method literal-escape ($/) { make '^' }
    method escape ($/) { make $/.values[0].made }
    method escape-statement ($/) { make $/.values[0].made }
    method escape-statement-call ($/) {
        my @decls := @<escape-statement-call-declaration>;
        make Upshift::Language::Upshift::Definition::Call.new:
            children => flat(
                $<name>.made,
                @decls».made.Slip
            ),
            defer => @decls.grep(*.<defer>.Bool)».made.flat;
    }
    method escape-statement-subcall ($/) {
        my @decls := @<escape-statement-call-declaration>;
        make Upshift::Language::Upshift::Definition::Call.new:
            :subcall,
            children => flat(
                @decls».made.Slip,
                $<body>.made
            ),
            direct => @decls.grep(*.<direct>.Bool)».made.flat,
            defer => @decls.grep(*.<defer>.Bool)».made.flat;
    }
    method escape-statement-call-declaration ($/) {
        make @($<name>.made, $<value>.made)
    }
    method escape-statement-conditional ($/) {
        my $if = $<escape-statement-conditional-if>.pairs.first({.key ne 'not'}).value;
        my @children = flat(
            $if<name>.made,
            $<escape-statement-conditional-if><not> ??
                ( $if<value>.made.defined ?? * ne $if<value>.made !! '') !!
                $if<value>.?made // * ne '',
            $if<literal>.made,
            @<escape-statement-conditional-elsif>.map({
                .<not> ??
                    ( .<value>.made.defined ?? * ne .<value>.made !! '') !!
                    .<value>.?made // * ne '',
                .<literal>.made
            }),
            $<escape-statement-conditional-else><literal>.?made // ()
        );
        
        make Upshift::Language::Upshift::Definition::Conditional.new: :@children;
    }
    method escape-literal ($/) {
        make @0 > 1 ??
            Upshift::Language::Upshift::Definition.new:
                children => @0.map: *.values[0].made !!
            @0[0].values[0].made;
    }
    method escape-literal-bare ($/) { make ~$/ }
    method escape-literal-quoted ($/) { make join '', $0».values».made }
    method escape-literal-quoted-literal ($/) { make ~$/ }
    method escape-literal-quoted-literal-escape ($/) { make '^' }
    method escape-literal-quoted-literal-quote ($/) { make "'" }
    method escape-literal-doublequoted ($/) { make join '', $0».values».made }
    method escape-literal-doublequoted-literal ($/) { make ~$/ }
    method escape-literal-doublequoted-literal-escape ($/) { make '^' }
    method escape-literal-doublequoted-literal-quote ($/) { make '"' }
    method escape-literal-upquoted ($/) { make $<uptop>.made }
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
