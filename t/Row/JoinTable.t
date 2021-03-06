#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Deep;

use TestSchema;
my $schema = TestSchema->deploy_or_connect();
$schema->prepopulate;

{
   my $bar_rs = TestSchema->resultset('Foo_Bar');

   is $bar_rs->result_source->from, 'Foo_Bar', 'set table works';

   relationships: {
      my $bar_info = $bar_rs->result_source->relationship_info('bar');
      is $bar_info->{class}, 'TestSchema::Result::Bar',
         'namespace correctly defaulted';

      my $foo_info = $bar_rs->result_source->relationship_info('foo');
      is $foo_info->{class}, 'TestSchema::Result::Foo',
         'namespace and method name correctly defaulted';
   }

   cmp_deeply [ $bar_rs->result_source->primary_columns ], [qw{foo_id bar_id}],
      'set primary keys works';

   cmp_deeply $bar_rs->result_source->column_info('bar_id'), {
      data_type => 'integer',
      size => 12,
   }, 'bar_id infers column info correctly';

}

{
   relationships: {
      my $g_rs = $schema->resultset('Gnarly');
      my $s_rs = $schema->resultset('Station');
      my $g_s_rs = $schema->resultset('Gnarly_Station');

      cmp_deeply $g_s_rs->result_source->column_info('gnarly_id'), {
         data_type => 'int',
      }, 'gnarly_id defaults column info correctly';

      is $s_rs->result_source->relationship_info('gnarly_stations')->{class},
         'TestSchema::Result::Gnarly_Station',
         'Left has_many defaulted correctly';

      is $g_rs->result_source->relationship_info('gnarly_stations')->{class},
         'TestSchema::Result::Gnarly_Station',
         'Right has_many defaulted correctly';

      cmp_deeply [ map $_->id, $s_rs->find(1)->gnarlies ],
         [ 1, 2, 3 ],
         'Left many_to_many defaulted correctly';

      cmp_deeply [ map $_->id, $g_rs->find(1)->stations ],
         [ 1, 3 ],
         'Right many_to_many defaulted correctly';

   }
}

done_testing;
