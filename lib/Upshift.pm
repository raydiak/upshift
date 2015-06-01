unit module Upshift;

use Upshift::Project;

our proto sub build (|) {*}

multi sub build (IO(Any) $path, Bool :$force = False) {
    Upshift::Project.new(:$path).build: :$force
}

multi sub build (IO(Any) $path, IO(Any) $gen-path, Bool :$force = False) {
    Upshift::Project.new(:$path, :$gen-path).build: :$force
}

# vim: ft=perl6
