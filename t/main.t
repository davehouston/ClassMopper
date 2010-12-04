use Test::More;
use PPI;
use Data::Dumper;
use Pod::Weaver;
use lib qw(t/inc);

# Make some 'test' documents..
my $doc = PPI::Document->new('t/inc/Tester.pm');
my $weaver = Pod::Weaver->new_from_config({ root => 't'});


my $document = $weaver->weave_document({
   ppi_document => $doc,
   mopper => { 
      no_tagline => 1
   },
   authors => ['Bob MctestAthor']
});

note $document->as_pod_string;
done_testing;
