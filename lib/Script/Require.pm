package Script::Require;

use strict;
use warnings;
use 5.008001;
use Carp ();
use Filter::Util::Call ();
use Cwd ();
use Hook::LexWrap ();

our $VERSION = '0.02';

our $DEBUG     = 0;
our $EXPORT    = 0;
our $RECURSIVE = 0;

my $PAKAGE = __PACKAGE__;

my %REQUIRED;

# ソースフィルター (MENTA::Controllerのパクリ)
# use strict, warnings, utf8する
# $SUPERに呼び出し元のパッケージ名を入れる
#
sub import {
	strict->import;
	warnings->import;
	utf8->import;
	
	my $current = Cwd::getcwd;
	Filter::Util::Call::filter_add(sub {
		my $status;
		my $data = '';
		my $count = 0;
		while ($status = Filter::Util::Call::filter_read()) {
			return $status if $status < 0;
			$data .= $_;
			$count++;
			$_ = "";
		}
		return $count unless $count;
		
		my $file;
		my $pkg = do {
			local $_ = (caller(0))[1];
			s#\\+#/#g;
			s#^$current/*##g;
			$file = $_;
			s#\.pl|\.cgi$##g;
			s#/+#::#g;
			s#\.#_#g;
			"$PAKAGE\::$_";
		};
		
		$_ = qq|;package $pkg;our \$SUPER;sub load { &$PAKAGE\::load(\@_) }$data;\nno warnings;\n"$pkg";|;
		
		$REQUIRED{$file} = $pkg;
		return $count;
	});
}

sub load {
	my $class = shift;
	my $hook_file = shift || Carp::croak "Usage: __PACKAGE__->load('script.pl')";
	my ($caller, $load_file) = caller;
	
	my $current = Cwd::getcwd;
	$load_file =~ s#\\+#/#g;
	$load_file =~ s#$current/*##;
	
	Carp::croak "No such file $hook_file" unless $hook_file and -f $hook_file;
	print STDERR "DEBUG(Lv.1): [$load_file] -> [$hook_file]\n" if $DEBUG;
	
	unless ($RECURSIVE) {
		Carp::croak "can't call myself at the __PACKAGE__->load()." if $hook_file =~ /$load_file/;
	}
	
	my $pkg = &_require_once($hook_file);
	print STDERR "DEBUG(Lv.1): package = $pkg\n" if $DEBUG;
	
	my $exists = {};
	local $EXPORT = $EXPORT;
	
	Hook::LexWrap::wrap(
		"$pkg\::run",
		pre  => sub { &_method_hogehoge($pkg, $caller, $exists, 0); },
		post => sub { &_method_hogehoge($pkg, $caller, $exists, 1); }
	);
	
	return $pkg->run(@_);
}

sub _require_once {
	my $file = shift;
	unless (exists $REQUIRED{$file}) {
		my $result = eval { require $file };
		Carp::croak "$file require error $@" if $@;
		Carp::croak "require $file ??" if $result and $result eq 1;
		$REQUIRED{$file} = $result;
	}
	
	return $REQUIRED{$file};
}

# 呼び出し元の関数をエクスポートしたり、使えなくしたりする
sub _method_hogehoge {
	my $pkg = shift;
	my $caller = shift;
	my $exists = shift;
	my $destroy = shift;
	
	no strict 'refs';
	if ($EXPORT) {
		for my $method (keys %{"$caller\::"}) {
			if ($caller->can($method)) {
				next if $method =~ /^(?:run|load|can)$/;
				
				unless ($destroy) {
					# 定義済みの関数は上書きしない
					if ($pkg->can($method)) {
						$exists->{$method} = 1;
						next;
					}
					
					# 関数のインポート
					*{"$pkg\::$method"} = *{"$caller\::$method"};
					print STDERR "  DEBUG(Lv.2): INSTALL $pkg\::$method\t=>\t$caller\::$method\n" if $DEBUG >= 2;
				}
				
				else {
					# 定義済みの関数は削除しない
					next if exists $exists->{$method};
					
					# インポートした関数を呼び出せないようにする
					*{"$pkg\::$method"} = *{"$pkg\::$method\ is DESTROY"};
					print STDERR "  DEBUG(Lv.2): DESTROY $pkg\::$method\n" if $DEBUG >= 2;
				}
			}
		}
	}
	
	# $SUPERに呼び出し元を定義
	${"$pkg\::SUPER"} = $destroy ? undef : $caller;
}

1;
__END__

=head1 NAME

Script::Require is to hook the script file.

=head1 SYNOPSIS

  # main.pl
  use Script::Require;
  
  __PACKAGE__->load('shout.pl', @args); # shout.pl at run method to call
  
  # shout.pl
  use Script::Require;
  
  sub run {
      my $self = shift; # this package name (probably 'Script::Require::shout')
      print "loaaaaaaaaaaaaaaaaaaaaaaaaaaaaad !! @_";
  }

=head1 DESCRIPTION

Script::Require is to hook the script file.
use several modules to enable additional features of Perl.
Roughly as follows:

  # test.pl saved
  use Script::Require;
  print __PACKAGE__;
  
  # console
  > perl -MO=Deparse test.pl
  use Script::Require;
  package Script::Require::test;
  use warnings;
  use strict 'refs';
  our $SUPER;
  sub load {
      &Script::Require::load(@_);
  }
  print 'Script::Require::test';
  no warnings;
  '???';
  test.pl syntax OK

=head1 METHODS

=over

=item load

run the script file after load.

  # main.pl
  use Script::Require;
  
  my $content = __PACKAGE__->load('get_html.pl', 'http://www.example.com');
  
  # get_html.pl
  use Script::Require;
  use LWP::Simple;
  
  sub run {
      my $self = shift; # this package name (probably 'Script::Require::get_html_pl')
      my $uri = shift;
      return get $uri;
  }

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
