use inc::Module::Install;
name 'Script-Require';
all_from 'lib/Script/Require.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
