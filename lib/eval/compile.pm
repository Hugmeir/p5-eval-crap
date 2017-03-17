package eval::compile;
use strict;
use warnings;

our $VERSION = '0.001';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Exporter 'import';
our @EXPORT    = our @EXPORT_OK = qw/compile/;

1;

__END__
=encoding UTF-8

=head1 NAME

eval::compile -- compile code, but do not run it. Like perl -c!

=head1 SYNOPSIS

    use eval::compile;
    compile("() = 1") or do {
        my $e = $@ || 'zombie error';
        die "Code did not compile! Error: $e";
    };

=head1 DESCRIPTION

This module provides one very simple function: C<compile>.

You pass it a string containing perl code, and it'll compile it.
However, unlike normal eval, it will not B<run> the code after
compiling it.  It's somewhat similar to C<perl -c>.

C<BEGIN>, C<UNITCHECK> and C<END> blocks will still be run, as
will C<use> statements.  Note that C<END> blocks will be run
at the end of execution like normal, which might be surprising;
see below for a workaround.

=head1 EXPORTS

=over 4

=item C<compile( $code )>

Compiles the given code.  Returns true if the code compiled, false
otherwise;  if the code failed to compile, the compilation error
will be found in C<$@>.

=back

=head1 A NOTE ON END BLOCKS

C<END> blocks compiled using this module will still
run at global destruction.  Since that might be undesirable,
the code below is a way to get rid of new C<END> blocks:

    use B ();
    my @original_end_blocks = map $_->object_2svref,
                                B::end_av()->isa("B::AV")
                                    ? B::end_av->ARRAY
                                    : ();
    
    compile("code that should not run end blocks");
    
    @{ B::end_av()->isa("B::AV") ? B::end_av()->object_2svref : [] }
        = @original_end_blocks;

=back
