use Script::Require;

sub run {
	print 'child ';
	__PACKAGE__->load('t/03_recursive.t');
}
