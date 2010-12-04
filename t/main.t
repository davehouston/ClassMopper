use Test::More;
use PPI;
use Data::Dumper;
use Pod::Weaver;



# Make some 'test' documents..
my $doc = PPI::Document->new('/home/dave/perl5/lib/perl5/Pod/Weaver.pm');

my $weaver = Pod::Weaver->new_from_config({ root => 't'});


my $document = $weaver->weave_document({
   ppi_document => $doc
});

note $document->as_pod_string;
done_testing;
