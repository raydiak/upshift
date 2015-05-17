unit module Upshift;

use Upshift::Project;

our proto sub build (|) {*}

multi sub build (IO(Any) $path) {
    Upshift::Project.new(:$path).build
}

multi sub build (IO(Any) $path, IO(Any) $gen-path) {
    Upshift::Project.new(:$path, :$gen-path).build
}

# vim: ft=perl6
