# ABSTRACT: Javascript Object Rendering for Validation::Class

package Validation::Class::Plugin::JavascriptObjects;

use strict;
use warnings;

use JSON -convert_blessed_universally;

use Validation::Class::Util;

our $VERSION = '0.04'; # VERSION


sub new {

    my $class     = shift;
    my $prototype = shift;

    my $self = {prototype => $prototype};

    return bless $self, $class;

}

sub proto {

    goto &prototype;

}

sub prototype {

    my ($self) = @_;

    return $self->{prototype};

}


sub render {

    my ($self, %options)  = @_;

    my $model     = $self->prototype;
    my $namespace = $options{namespace} || $model->package || 'object';
    my $next      = my $root = {};

    $next = $next->{$_} = {} for split /\W+/, $namespace;

    my @fields = isa_arrayref($options{fields}) ?
        map { $model->fields->get($_) || () } @{$options{fields}} :
        $model->fields->values
    ;

    foreach my $field (@fields) {

        my %data = map {
            # automatically excludes validation, etc
            isa_coderef($field->{$_}) ? () : ($_ => $field->{$_})
        }   $field->keys;

        my $name = $field->name;

        if (isa_arrayref $options{include}) {
            %data = map { $_ => $data{$_} } @{$options{include}};
        }

        if (isa_arrayref $options{exclude}) {
            delete $data{$_} for @{$options{exclude}};
        }

        $next->{$name} ||= {%data};

    }

    # generate the JS object
    my @data = each(%{$root});
    my $data = sprintf 'var %s = %s;', $data[0], JSON->new

        ->allow_nonref
        ->allow_blessed
        ->convert_blessed
        ->utf8->pretty
        ->encode($data[1])

    ;

    return $data;

}

1;

__END__
=pod

=head1 NAME

Validation::Class::Plugin::JavascriptObjects - Javascript Object Rendering for Validation::Class

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    # THIS PLUGIN IS UNTESTED AND MAY BE SUBJECT TO DESIGN CHANGES!!!

    use Validation::Class::Simple;

    # given

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => { required => 1 },
            password => { required => 1 },
        }
    );

    # when

    my $objects = $rules->plugin('javascript_objects');

    print $objects->render(namespace => 'form.signup', include => [qw/errors/]);

    # should output

    var form.signup = {
        "password": {
            "errors": ["password is required"]
        },
        "username": {
            "errors": ["username is required"]
        }
    };

=head1 DESCRIPTION

Validation::Class::Plugin::JavascriptObjects is a plugin for L<Validation::Class>
which can leverage your validation class field definitions to render JavaScript
objects for the purpose of introspection.

=head1 METHODS

=head2 render

The render method converts the attached validation class into a javascript
object for introspection purposes. This method accepts a list of key/value pairs
as options.

    $self->render;

    # or

    $self->render(
        namespace => 'Foo.Bar',
        exclude   => [qw/pattern/]
    );

    # or

    $self->render(
        namespace => 'Foo.Baz',
        include   => [qw/minlength maxlength required/]
    );

    # or, to also limit the fields output

    $self->render(
        namespace => 'Foo.Baz',
        fields    => [qw/this that/],
        include   => [qw/minlength maxlength required/]
    );

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

