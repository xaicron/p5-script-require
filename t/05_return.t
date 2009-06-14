use Script::Require;
use Test::More tests => 2;
use Test::Output;

is __PACKAGE__->load('t/hook_files/e.pl'), 'ok';
is_deeply [ __PACKAGE__->load('t/hook_files/e.pl') ], [ qw/array ok/ ];

