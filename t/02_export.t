use Script::Require;
use Test::More tests => 1;
use Test::Output;

$Script::Require::EXPORT = 1;

stdout_is { __PACKAGE__->load('t/hook_files/b.pl') } 'parent';

sub parent {
	print 'parent';
}
