use Script::Require;

sub run {
	&shout();
	$SUPER->shout();
}

sub shout {
	warn "yahoooooooooooooo!\n";
}
