package Pod::Weaver::Section::ClassMopper;

BEGIN { 
   $Pod::Weaver::Plugin::ClassMopper::AUTHORITY = 'cpan:DHOUSTON';
   $Pod::Weaver::Plugin::ClassMopper::VERSION = '0.01';
}

use Moose;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;
use Data::Dumper;

# ABSTRACT: Generate some stuff via introspection

with 'Pod::Weaver::Role::Section';

has '_attrs' => ( is => 'rw' );
has '_methods' => ( is => 'rw' );
has '_class' => ( is => 'rw' );

has '_method_skip' => ( 
   is => 'ro', 
   isa => 'HashRef',
   default => sub {{
      meta => 1,
      BUILDARGS => 1,
      BUILDALL => 1,
      DEMOLISHALL => 1,
      does => 1,
      DOES => 1,
      dump => 1,
      can => 1,
      VERSION => 1
   }}
);

sub weave_section { 
   my $self = shift;
   my( $document, $input ) = @_;

   my $class = $input->{mopper}->{class} || 
      $self->_get_classname( $input );

   unless( $input->{attributes}->{skip} ) { 
      $self->_build_attributes( );
      if( $self->_attrs ) { 
         push @{$document->children},  Pod::Elemental::Element::Nested->new({
            command => 'head1',
            content => 'ATTRIBUTES',
            children => $self->_attrs } 
          );
       }

  }

   unless( $input->{methods}->{skip} ) { 
      $self->_build_methods( );
      if( $self->_methods ) { 
         push @{$document->children}, Pod::Elemental::Element::Nested->new({ 
            command => 'head1',
            content => 'METHODS',
            children => $self->_methods }
          );
       }
  }

   print STDERR "Document: ", $document, "\nRef: ", ref $document, "\n";

   
}

sub _build_attributes { 
   my $self = shift;
   my $meta = $self->_class;
   return unless ref $meta;
   my @attributes = $meta->get_all_attributes;
   if( @attributes ) { 
      my @chunks = map { $self->_build_attribute_paragraph( $_ ) } @attributes;
      $self->_attrs( \@chunks );
   }

}


sub _build_methods { 
   my $self = shift;
   my $meta =  $self->_class;
   return unless ref $meta;
   my @methods = $meta->get_all_methods;
   if( @methods ) { 
      my @chunks = map { $self->_build_method_paragraph( $_ ) } @methods;
      $self->_methods( \@chunks );
   }
}

sub _build_method_paragraph { 
   # Generate a pod section for a method.  
   my $self = shift;
   my $method = shift;   
   return unless ref $method;
   my $name = $method->name;

   if( exists $self->_method_skip->{$name} ) { 
      return;  # Skip over some of the more .. UNIVERSAL methods..
   }

   if( $method->original_package_name =~ /^Moose::Object/ ) { 
      return;  # No one wants to see that shit
   }

   my $bits = [];
   if( $self->_class ne $method->original_package_name ) {
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Method originates in ' . $method->original_package_name . '.'
      });
   }

   push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({
      content => 'This documentation was automaticaly generated.'
   });

   my $meth = Pod::Elemental::Element::Nested->new( { 
      command => 'head2',
      content => $method->name,
      children => $bits
   } );
   return $meth;

}

sub _build_attribute_paragraph { 
   my $self = shift;
   my $attribute = shift;
   return unless ref $attribute;
   
   my $bits = [];
   
   if( $attribute->has_read_method ) { 
      my $reader = $attribute->get_read_method;
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Reader: ' . $reader
      });
   }

   if( $attribute->has_write_method ) { 
      my $writer = $attribute->get_write_method;
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Writer: ' . $writer
      });
   }
   
   # Moose has typecontraints, not Class::MOP.  
   if( $attribute->has_type_constraint ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({
         content => 'Type: ' . $attribute->type_constraint->name
      });
   }

   # Moose only, again.
   if( $attribute->is_required ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'This attribute is required.'
      });
   }

   # Moose's 'docmentation' option.
   if( $attribute->has_documentation ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Additional documentation: ' . $attribute->documentation
      });
   }

   push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({
      content => 'This documentation was automatically generated.'
   });

   my $a = Pod::Elemental::Element::Nested->new({ 
      command => 'head2',
      content => $attribute->name,
      children => $bits
   });
   return $a;

}

sub _get_classname { 
   my( $self, $input ) = @_;
   
   # Do some fiddling here, see what sort of crap we have, and 
   # try to return a package name.  
   my $classname;

   my $ppi = $input->{ppi_document};
   unless( ref $ppi eq 'PPI::Document'  ) { 
      return;
   }
   my $node = $ppi->find_first('PPI::Statement::Package');
   if( $node ) { 
      $classname = $node->namespace;
   } else { 
      # parsing comments.  WHAT COULD GO WRONG.  
      # Shamelessly stolen from Pod::Weaver::Section::Name.  Thanks rjbs!
      ($classname) = $ppi->serialize =~ /^\s*#+\s*PODNAME:\s*(.+)$/m;
   }
   my $meta = Class::MOP::Class->initialize( $classname );
   $self->_class( $meta );

   return $classname;
}



1;

__END__
=pod

=head1 NAME 

Pod::Weaver::Section::ClassMopper - Use Class::MOP introspection to make a couple sections.

=head1 OVERVIEW

This section plugin is able to generate two sections for you, B<ATTRIBUTES> and B<METHODS>.  By
default, only attributes are created.  


=cut
