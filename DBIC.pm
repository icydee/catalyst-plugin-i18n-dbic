package Catalyst::Plugin::I18N::DBIC;

use strict;
use warnings;

use base 'Catalyst::Plugin::I18N';

our $VERSION = '0.03';

sub load_lexicon {
    my ($c, @paths) = @_;

    my $class = ref $c || $c;
    my $obj = "$class\::I18N"->get_handle(@{$c->languages});
    my $lang = $c->language;

    my $where = {
        language    => $lang,
        path        => [@paths],
    };

    my $lexicons_rc = $c->model('DBIC::Lexicon')->search($where);
    while (my $lex = $lexicons_rc->next) {
        my $message = $lex->message;
        my $value = $lex->value;

        eval <<"EOF";
            \$$class\::I18N::$lang\::Lexicon{\$message} = \$value;
EOF
        if ($@) {
            $c->log->error(qq/Couldn't write $class::I18N::$lang, "$@"/);
        }
    }
}

1;

=pod

=head1 NAME

Catalyst::Plugin::I18N::DBIC - Internationalization for Catalyst, data loaded
from database

=head1 SYNOPSIS

  use Catalyst qw(-Debug I18N::DBIC);

  $c->languages( ['de'] );
  $c->load_lexicon( qw(footer header user/list navigation) );
  print $c->localize('Hello Catalyst');

Or in your template

  [% c.load_lexicon('header', 'navigation') %]

  [% c.loc('Home Page') %]
  [% c.loc('Welcome to Catalyst') %]


=head1 DESCRIPTION

This module is based on L<Catalyst::Plugin::I18N> and L<I18N> and you should
refer to those modules for further information.

These modules hold their localization data in files (mo, po or pm files) and
for a very large application these files can become very large and difficult
to maintain.

L<Catalyst::Plugin::I18N::DBIC> however allows you to hold the localization
data in a database (using L<Catalyst::Model::DBIC::Schema> ) which has
several advantages.

=over 4

=item

The localization data can be split into several 'paths' which represent the
natural organization of the applicatio. e.g. 'footer', 'header', 'navigation',
'user/list'.

=item

You can write an application that directly modifies the database so that
your translators can do their stuff more easily and directly.

=item

If you have a client that requires custom text it is easier to do this by
making a database change than by releasing a new text file.

=back

=head1 EXTENDED METHODS

=head2 load_lexicon

Takes an array of 'paths' which should be searched to load the Lexicon data
from the database.

It is more efficient in database requests to request all paths that may be
used on a page in one go. It may however be more convenient to make several
requests if you include templates in other templates (such as header and
footer templates) and make separate calls in each template.

=head1 Database Schema

The module requires a table called C<lexicon> with the following structure

  CREATE TABLE lexicon (
    id          int(11) NOT NULL auto_increment,
    language    varchar(15)     default NULL,
    path        varchar(255)    default NULL,
    message     text,
    value       text,
    notes       text,
    PRIMARY KEY (id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

Actually you may want to change the index method and the 'notes' field is not
required but can be useful to hold information to help the translator put the
message in context.

The C<value> is the tranlated C<message>. The C<path> is the context where
the message is used. For example you may wish to group all the menu button
text and navigation text into the C<navigation> path. All the text for the
generic header template could be in the C<header> path etc.

=head1 SEE ALSO

Refer to L<Catalyst::Plugin::I18N> for information on the other methods used.

=head1 AUTHOR

Ian Docherty, C<cpan@iandocherty.com>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
