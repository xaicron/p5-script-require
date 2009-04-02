use Script::Require;
use Test::More tests => 1;
use Test::Output;

stdout_is { __PACKAGE__->load('t/hook_files/d.pl') } 'Nooooooooooooooooo!';

sub shout {
	print 'Nooooooooooooooooo!';
}
