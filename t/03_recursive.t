use Script::Require;
use Test::More tests => 1;
use Test::Output;

$Script::Require::RECURSIVE = 1;

stdout_is { __PACKAGE__->load('t/hook_files/c.pl') } 'child parent ' x 10;

my $count;
sub run {
	print 'parent ';
	return if ++$count == 10;
	__PACKAGE__->load('t/hook_files/c.pl');
}
