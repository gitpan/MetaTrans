=head1 NAME

MetaTrans::UltralinguaNet - MetaTrans plug-in for L<http://ultralingua.net/>

=cut

package MetaTrans::UltralinguaNet;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base;

use Encode;
use HTTP::Request;
use URI::Escape;

$VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base); # we derrive from MetaTrans::Base

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::UltralinguaNet->new(%options)

This method constructs a new MetaTrans::UltralinguaNet object and returns
it. All C<%options> are passed to C<< MetaTrans::Base->new >>. The method
also sets supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    # set the host_server option ...
    $options{host_server} = "ultralingua.net"
        unless (defined $options{host_server});

    # ... and pass all the options to MetaTrans::Base constructor
    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    # set supported languages
    $self->set_languages("eng", "fre", "spa", "ger", "ita", "por", "lat", "epo");

    # ulralingua.net enables translating from English to any of supported
    # languages...
    $self->set_dir_1_to_all("eng");

    # ... and reversely
    $self->set_dir_all_to_1("eng");

    # it also supports:
    # French <-> Spanish
    # French <-> German
    # French <-> Italian
    $self->set_dir_1_to_spec("fre", "spa", "ger", "ita");
    $self->set_dir_spec_to_1("fre", "spa", "ger", "ita");

    # ...
    # Spanish <-> German
    # Spanish <-> Portuguese
    $self->set_dir_1_to_spec("spa", "ger", "por");
    $self->set_dir_spec_to_1("spa", "ger", "por");

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

    # language codes translation table
    my %table = (
        eng => "english",
        fre => "french",
        spa => "spanish",
        ger => "german",
        ita => "italian",
        por => "portuguese",
        lat => "latin",
        epo => "esperanto",
    );

    # we may need to escape some characters to be able to pass the expression
    # as a part of URL without causing any trouble
    $expression = uri_escape($expression);

    # translation direction in the format that server understands
    my $direction  = $table{$src_lang_code} . "2" . $table{$dest_lang_code};

    my $query = "http://ultralingua.net/index.html" .  # script name
        "?action=define&sub=1&searchtype=stemmed" .    # `static' options
        "&text=" . uri_escape($expression) .           # expr. to be translated
        "&service=". $expression;                      # translation direction

    # construct the HTTP::Request object
    my $request = new HTTP::Request("GET", $query);

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

    # The response is of course in HTML, we need to parse it.
    # In ultralingua.net's case it's a bit complicated as some expressions are
    # divided into multiple tags and also there are two hierarchical levels of
    # the out. See other plug-ins source codes for simpler
    # (try MetaTrans::SlovnikCz).

    my @result;
    while ($contents =~ m:
        <p\s+class="(main|expression)"\s*>
        (.*?)
        <span\s+class="number"\s*>\s*1\.\s*</span>(.*?)
        (</p>|\z)
    :gsix)
    {
        my $expr_part  = $2;
        my $trans_part = $3;
        my $expr;

        while ($expr_part =~ m:<span\s+class="(headword|word)"\s*>(.*?)</span>([^<]*):gsi)
        { 
            my $expression = $2 . $3;
            $expression =~ s/<[^>]*>//gs;
            $expr .= $expression;
        }

        if ($expr_part =~ m|<span\s+class="partofspeech"\s*>\s*([^>]*?)\s*</span>|si)
            { $expr .= " ($1)"; }

        $expr =~ s/\s+/ /g;
        $expr =~ s/^ //;

        foreach my $trans_block (split m|<span\s+class="number"\s*>\s*[0-9]\.\s*</span>|si, $trans_part)
        {
            my $trans;
            
            while ($trans_block =~ m|<span\s+class="transword"\s*>(.*?)</span>([^<]*)|gsi)
            { 
                my $expression = $1 . $2;
                $expression =~ s/<[^>]*>//gs;
                $trans .= $expression;
            }

            if ($trans_block =~ m|<span\s+class="partofspeech"\s*>\s*([^>]*?)\s*</span>|si)
                { $trans .= " ($1)"; }

            $trans =~ s/\s+/ /g;
            $trans =~ s/^ //;

            push @result, ($expr, $trans);
        }
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
