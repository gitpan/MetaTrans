=head1 NAME

MetaTrans::WordbookCz - MetaTrans plug-in for L<http://www.wordbook.cz/>

=cut

package MetaTrans::WordbookCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base;

use Encode;
use HTTP::Request;

$VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::WordbookCz->new(%options)

This method constructs a new MetaTrans::WordbookCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "www.wordbook.cz"
        unless (defined $options{host_server});

    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    $self->set_languages("cze", "eng");

    $self->set_dir_1_to_1("cze", "eng");
    $self->set_dir_1_to_1("eng", "cze");

    return $self;
}

=head1 METHODS

Methods are inherited from C<MetaTrans::Base>. Following methods are overriden:

=cut

=over 4

=item $plugin->create_request($expression, $src_lang_code, $dest_lang_code)

Create and return a C<HTTP::Request> object to be used for retrieving
translation of the C<$expression> from C<$src_lang_code> language to
C<$dest_lang_code> language.

=cut

sub create_request
{
    my $self           = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my %table = (
        cze => "c",
        eng => "a",
    );

    my $request = HTTP::Request->new(POST => "http://www.wordbook.cz/slovnik.php?fjazyk=cz");
    $request->content_type('application/x-www-form-urlencoded');

    # convert to Perl's internal UTF-8 format
    $expression = Encode::decode_utf8($expression)
        unless Encode::is_utf8($expression);
    
    # convert to iso-8859-2 character encoding (that's what server expects)
    $expression = encode("iso-8859-2", $expression);

    my $query = 
        "jeform=1" .
        "&frozs=1" .
        "&fslovo=$expression" .
        "&fsmer=" . $table{$src_lang_code} . $table{$dest_lang_code};
    $request->content($query);

    return $request;
}

=item $plugin->process_response($contents, $src_lang_code, $dest_lang_code)

Process the server response contents. Return the result of the translation in
an array of following form:

    (expression_1, translation_1, expression_2, translation_2, ...)

=back

=cut

sub process_response
{
    my $self           = shift;
    my $contents       = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my @result;
    while ($contents =~ m|
        <td\s+class="vyslb"\s*>\s*
        ([^<]*?)\s*</td>\s*
        <td\s+class="vyslb"\s*>\s*
        ([^<]*?)\s*</td>\s*
    |gsix)
    {
        my $expr  = $1;
        my $trans = $2;

        next if $expr =~ /^\s*$/ || $trans =~ /^\s*$/;

        # the output is in iso-8859-2 character encoding
        # let's convert it to UTF-8
        Encode::from_to($expr,  "iso-8859-2", "utf8");
        Encode::from_to($trans, "iso-8859-2", "utf8");

        push @result, ($expr, $trans);
    }

    return @result;
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metatrans@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jan Pomikalek, C<< <xpomikal@fi.muni.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jan Pomikalek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MetaTrans>, L<MetaTrans::Base>, L<MetaTrans::Languages>,
L<HTTP::Request>, L<URI::Escape>
