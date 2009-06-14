use Script::Require;

$Script::Require::EXPORT = 1;

__PACKAGE__->load('b.pl');

sub shout {
	warn "Gooooooooooooogle!\n";
};
