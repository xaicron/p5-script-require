use Script::Require;
use Test::More tests => 1;
use Test::Output;

stdout_is { __PACKAGE__->load('t/hook_files/a.pl') } 'ok';
