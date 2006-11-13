package Catalyst::Plugin::I18N::DBIC;

use strict;
use warnings;

use base 'Catalyst::Plugin::I18N';

our $VERSION = '0.01';

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
