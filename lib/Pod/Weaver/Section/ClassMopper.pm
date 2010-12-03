package Pod::Weaver::Section::ClassMopper;

BEGIN { 
   $Pod::Weaver::Plugin::ClassMopper::AUTHORITY = 'cpan:DHOUSTON';
   $Pod::Weaver::Plugin::ClassMopper::VERSION = '0.01';
}

use Moose;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;

# ABSTRACT: Generate some stuff via introspection

with 'Pod::Weaver::Role::Section';

has '_attrs' => ( is => 'rw' );
has '_methods' => ( is => 'rw' );
has '_class' => ( is => 'rw' );

sub weave_section { 
   my $self = shift;
   my( $document, $input ) = @_;

   my $class = $input->{mopper}->{class} || 
      $self->_get_classname( $input );

   unless( $input->{attributes}->{skip} ) { 
      $self->_build_attributes( );
   }

   unless( $input->{methods}->{skip} ) { 
      $self->_build_methods( ); 
   }

}

sub _build_attributes { 
   my $self = shift;
   my $meta = Class::MOP::Class->initialize( $self->_class );
   return unless ref $meta;
   my @chunks = map { $self->_build_attribute_paragraph( $_ ) } @{$meta->get_all_attributes};

}


sub _build_methods { 
   my $self = shift;
   my $meta = Class::MOP::Class->initialize( $self->_class );
   return unless ref $meta;
   my @chunks = map { $self->_build_method_paragraph( $_ ) } @{$meta->get_all_methods};
   $self->_methods( \@chunks );
}

sub _build_method_paragraph { 
   # Generate a pod section for a method.  
   my $self = shift;
   my $method = shift;   
   return unless ref $method;

   my $bits = [];
   if( $self->_class ne $method->original_package_name ) { 
      push @$bits, Pod::Elemental::Element::Pod5::Ordinary->new({ 
         content => 'Method originates in ' . $method->original_package_name . '.'
      });
   }

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
      push @$bits, Pod::Elemental::ElementPod5::Ordinary->new({ 
         content => 'Reader: ' . $reader
      });
   }

   if( $attribute->has_write_method ) { 
      my $writer = $attribute->get_write_method;
      push @$bits, Pod::Elemental::ElementPod5::Ordinary->new({ 
         content => 'Writer: ' . $writer
      });
   }
   
   # Moose has typecontraints, not Class::MOP.  
   if( my $type = $attribute->can( 'type_constraint' ) ) { 
      push @$bits, Pod::Elemental::ElementPod5::Ordinary->new({
         content => 'Type: ' . $type->()->name
      });
   }

   # Moose only, again.
   if( my $req = $attribute->can('is_required') ) { 
      push @$bits, Pod::Elemental::ElementPod5::Ordinary->new({ 
         content => 'Required : ' . $req->() ? 'Yes' : 'No'
      });
   }

   # Moose's 'docmentation' option.
   if( my $doc = $attribute->can('documentation') ) { 
      push @$bits, Pod::Elemental::ElementPod5::Ordinary->new({ 
         content => $doc->()
      });
   }

   my $a = Pod::Elemental::ElementPod5::Nested->new({ 
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

   return unless $ppi;
   
   if( my $obj = $ppi->can('find_first') ) { 
      # neat, easy way, using PPI.
      my $node = $ppi->('PPI::Statement::Package');
      $classname = $node->namespace;
   } else { 
      # parsing comments.  WHAT COULD GO WRONG.  
      # Shamelessly stolen from Pod::Weaver::Section::Name.  Thanks rjbs!
      ($classname) = $ppi->serialize =~ /^\s*#+\s*PODNAME:\s*(.+)$/m;
   }
   $self->_class( $classname );
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
