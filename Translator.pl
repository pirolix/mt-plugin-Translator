package MT::Plugin::OMV::Translator;

use strict;
use MT 3;
use MT::Template::Context;

use vars qw( $MYNAME $VERSION );
$MYNAME = 'Translator';
$VERSION = '0.01';

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
    id => $MYNAME,
    key => $MYNAME,
    name => $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
    doc_link => 'http://www.magicvox.net/archive/2010/03101929/',
    description => <<HTMLHEREDOC,
Translate the phrase with the user dictionary.
HTMLHEREDOC
    config_template => sub {
        <<HTMLHEREDOC;
<mtapp:setting
    id="dictionary"
    label="User Dictionary">
<textarea name="dictionary"><TMPL_VAR NAME=DICTIONARY ESCAPE=HTML></textarea>
</mtapp:setting>
HTMLHEREDOC
    },
    settings => new MT::PluginSettings([
        [ 'dictionary', { Default => undef } ],
    ]),
});
MT->add_plugin( $plugin );



MT::Template::Context->add_global_filter (lc $MYNAME => sub {
    my ($text, $args, $ctx) = @_;

    my $blog = $ctx->stash('blog');
    if (defined (my $dictionary = $plugin->get_config_value ('dictionary', $blog ? 'blog:'. $blog->id : 'system'))) {
        foreach (split /[\r\n]/, $dictionary) {
            my ($src, $dst) = split /\|/;
            $src =~ s/^\s+|\s+$//g; next if $src !~ /.+/;
            $dst =~ s/^\s+|\s+$//g;
            $text =~ s/\Q$src\E/$dst/g;
        }
    }

    $text;
});

1;