use 5.010001;
use strict;
use warnings;
use XSLoader ();

package Type::Tiny::XS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

__PACKAGE__->XSLoader::load($VERSION);

use Scalar::Util qw(refaddr);

my %names = (map +( $_ => __PACKAGE__ . "::$_" ), qw/
	Any ArrayRef Bool ClassName CodeRef Defined
	FileHandle GlobRef HashRef Int Num Object
	Ref RegexpRef ScalarRef Str Undef Value
/);
$names{Item} = $names{Any};

my %coderefs;
sub _know {
	my ($coderef, $type) = @_;
	$coderefs{refaddr($coderef)} = $type;
}

sub is_known {
	my $coderef = shift;
	$coderefs{refaddr($coderef)};
}

for (reverse sort keys %names) {
	no strict qw(refs);
	_know \&{$names{$_}}, $_;
}

my $id = 0;

sub get_coderef_for {
	my $type = $_[0];
	
	return do {
		no strict qw(refs);
		\&{ $names{$type} }
	} if exists $names{$type};
	
	my $made;
	
	if ($type =~ /^ArrayRef\[(.+)\]$/) {
		my $child = get_coderef_for($1) or return;
		$made = _parameterize_ArrayRef_for($child);
	}
	
	elsif ($type =~ /^HashRef\[(.+)\]$/) {
		my $child = get_coderef_for($1) or return;
		$made = _parameterize_HashRef_for($child);
	}
	
	elsif ($type =~ /^Maybe\[(.+)\]$/) {
		my $child = get_coderef_for($1) or return;
		$made = _parameterize_Maybe_for($child);
	}
	
	elsif ($type =~ /^InstanceOf\[(.+)\]$/) {
		my $class = $1;
		return unless Type::Tiny::XS::Util::is_valid_class_name($class);
		$made = Type::Tiny::XS::Util::generate_isa_predicate_for($class);
	}
	
	elsif ($type =~ /^HasMethods\[(.+)\]$/) {
		my $methods = [ sort(split /,/, $1) ];
		/^[^\W0-9]\w*$/ or return for @$methods;
		$made = Type::Tiny::XS::Util::generate_can_predicate_for($methods);
	}
	
	if ($made) {
		no strict qw(refs);
		my $slot = sprintf('%s::AUTO::TC%d', __PACKAGE__, ++$id);
		$names{$type} = $slot;
		_know($made, $type);
		*$slot = $made;
		return $made;
	}
	
	return;
}

sub get_subname_for {
	my $type = $_[0];
	get_coderef_for($type) unless exists $names{$type};
	$names{$type};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::XS - provides an XS boost for some of Type::Tiny's built-in type constraints

=head1 SYNOPSIS

   use Types::Standard qw(Int);

=head1 DESCRIPTION

Current releases of Type::Tiny do not make use of Type::Tiny::XS. This
distribution is just an experimental space for making stuff faster.

Only the following two functions should be considered part of the
supported API:

=over

=item C<< Type::Tiny::XS::get_coderef_for($type) >>

Given a supported type constraint name, such as C<< "Int" >>, returns
a coderef that can be used to validate a parameter against this
constraint.

=item C<< Type::Tiny::XS::get_subname_for($type) >>

Like C<get_coderef_for> but returns the name of such a sub as a string.

=item C<< Type::Tiny::XS::is_known($coderef) >>

Returns true if the coderef was provided by Type::Tiny::XS.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny-XS>.

=head1 SEE ALSO

L<Type::Tiny>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt> forked all this from
L<Mouse::Util::TypeConstraints>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

