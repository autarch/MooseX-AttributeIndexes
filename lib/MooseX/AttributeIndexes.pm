use strict;
use warnings;

package MooseX::AttributeIndexes;

# ABSTRACT: Advertise metadata about your Model-Representing Classes to Any Database tool.
use Moose 0.94 ();

use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::AttributeIndexes::Provider;
use MooseX::AttributeIndexes::Provider::FromAttributes;
use MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed;

=head1 SYNOPSIS

=head2 Implementing Indexes

  package My::Package;
  use Moose;
  use MooseX::AttributeIndexes;
  use MooseX::Types::Moose qw( :all );

  has 'id' => (
    isa => Str,
    is  => 'rw',
    primary_index => 1,
  );

  has 'name' => (
    isa => Str,
    is  => 'rw',
    indexed => 1,
  );

  has 'foo' => (
    isa => Str,
    is  => 'rw',
  );

=head2 Accessing Indexed Data

  package TestScript;

  use My::Package;

  my $foo = My::Package->new(
    id => "Bob",
    name => "Smith",
    foo  => "Bar",
  );

  $foo->attribute_indexes
  # { id => 'Bob', name => 'Smith' }

=head2 Using With Search::GIN::Extract::Callback

  Search::GIN::Extract::Callback(
    extract => sub {
      my ( $obj, $callback, $args ) = @_;
      if( $obj->does( 'MooseX::AttributeIndexes::Provider') ){
        return $obj->attribute_indexes;
      }
    }
  );

=cut

=head2 CODERef

Since 0.01001007, the following notation is also supported:

  has 'name' => (
    ...
    indexed => sub {
      my ( $attribute_meta, $object, $value ) = @_;
      return "$_" ; # $_ == $value
    }
  );

Noting of course, $value is populated by the meta-accessor.

This is a simple way to add exceptions for weird cases for things you want to index that
don't behave like they should.

=head3 SEE ALSO

L<Search::GIN::Extract::AttributeIndexes>

=cut

Moose::Exporter->setup_import_methods();

=head1 METHODS

=head2 init_meta

Injects the traits for Indexed as default traits on all new attributes,
and glues the 2 magical roles into your package.

=cut

sub init_meta {
  my ( $class, %options ) = @_;
  Moose->init_meta( for_class => $options{'for_class'} )
    unless $options{'for_class'}->can('meta');

  Moose::Util::MetaRole::apply_metaroles(
    for             => $options{'for_class'},
    class_metaroles => { attribute => ['MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed'], },
  );
  Moose::Util::MetaRole::apply_base_class_roles(
    for   => $options{'for_class'},
    roles => [ 'MooseX::AttributeIndexes::Provider', 'MooseX::AttributeIndexes::Provider::FromAttributes', ],
  );
}

1;

