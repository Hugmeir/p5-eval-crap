use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('eval::compile');
    eval::compile->import();
}


sub with_proto_ok ($;$) {
    my @got = @_;
    is_deeply(\@got, [1], "same with proto")
}

sub with_proto_not_ok ($;$) {
    my @got = @_;
    is_deeply(\@got, [''], "same with proto")
}

for my $good_code (
    '() = 1',
    'my $x = 1; $x++',
    '$::x++',
    '$::x++; $::x++; undef;',
    'BEGIN { $::x++; }',
    'BEGIN { $::x++; $::x++; }',
) {
    subtest $good_code => sub {
        ok(compile($good_code), "$good_code compiled fine");

        my @in_list_context = compile($good_code);
        is_deeply(\@in_list_context, [1], "not leaving code in the stack");
        sub {
            my @got = @_;
            is_deeply(\@got, [1], "same with sub")
        }->(compile($good_code));

        with_proto_ok(compile($good_code));
    }
}
is($::x, 12, "begin blocks ran as expected, but the rest of the code did not");

for my $bad_code (
    '1 = 1',
    'my *x = 1;',
    '$::x++; }',
    '$::x++; { $::x++; undef;',
    'BEGIN { $::x++; } { 1;',
    '} BEGIN { $::x++; $::x++; }',
) {
    subtest $bad_code => sub {
        my $ret = compile($bad_code);
        my $e   = $@ || 'zombie error';
        ok(!$ret, "$bad_code failed to compile");
        ok($e, "...and \$@ was set");

        my @in_list_context = compile($bad_code);
        is_deeply(\@in_list_context, [''], "not leaving code in the stack");
        sub {
            my @got = @_;
            is_deeply(\@got, [''], "same with sub")
        }->(compile($bad_code));

        with_proto_not_ok(compile($bad_code));
    }
}
is($::x, 16, "...and code in BEGIN blocks before the syntax errors ran");

my @blocks;
{
    no warnings;
    compile("$_ {push \@blocks, qq{$_}};") for qw/BEGIN CHECK INIT UNITCHECK/;
}
is_deeply(\@blocks, [qw/BEGIN UNITCHECK/]);

done_testing;
