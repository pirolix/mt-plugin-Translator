package MT::Plugin::OMV::Translator;

use strict;
use MT 3;
use MT::Template::Context;
use MT::Request;
use MT::Util;

use vars qw( $MYNAME $VERSION );
$MYNAME = (split /::/, __PACKAGE__)[-1];
$VERSION = '0.12';

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new ({
    id => $MYNAME,
    key => $MYNAME,
    name => $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
    doc_link => 'http://www.magicvox.net/archive/2010/03101929/',
    description => <<HTMLHEREDOC,
<__trans phrase="Translate the phrase with the user dictionary.">
HTMLHEREDOC
    config_template => \&_cb_config_template,
    settings => new MT::PluginSettings([
        [ 'name_alias', { Default => undef } ],
        [ 'dictionary', { Default => undef } ],
    ]),
});
MT->add_plugin( $plugin );

### Configuration template
sub _cb_config_template {
    my ($plugin, $param, $scope) = @_;

    my $tmpl;
    if ($scope eq 'system') {
        $tmpl .= <<HTMLHEREDOC;
<mtapp:setting
    id="name_alias"
    label="<__trans phrase="Name aliases">"
    hint="<__trans phrase="separate with '|' (a vertical bar)">"
    show_hint="1">
<input type="text" name="name_alias" value="<TMPL_VAR NAME=NAME_ALIAS ESCAPE=HTML>" class="full-width" />
</mtapp:setting>
HTMLHEREDOC
    }

    $tmpl .= <<HTMLHEREDOC;
<mtapp:setting
    id="dictionary"
    label="<__trans phrase="Dictionary">"
    hint="<__trans phrase="separate with '|' (a vertical bar) or tab">"
    show_hint="1">
<textarea name="dictionary" rows="10" class="full-width"><TMPL_VAR NAME=DICTIONARY ESCAPE=HTML></textarea>
</mtapp:setting>
HTMLHEREDOC
    $tmpl;
}

### Global filter - translator
MT::Template::Context->add_global_filter (lc $MYNAME => sub {
    my ($text, $args, $ctx) = @_;

    # Name alias
    my $name_alias = $plugin->get_config_value ('name_alias') || '';
    my @name_alias = split /\s*[\|\t]\s*/, $name_alias;
    for (0..$#name_alias) {
        if ($args eq $name_alias[$_]) {
            $args = $_ + 1; last;
        }
    }

    # Translate
    if (1 < $args) {
        my $dictionary = $plugin->get_config_value ('dictionary') || '';
        # Override with blog's dictionary
        if (defined (my $blog = $ctx->stash ('blog'))) {
            $dictionary .= "\n".
                $plugin->get_config_value ('dictionary', 'blog:'. $blog->id) || '';
        }

        # Generate dictionary
        my $req = MT::Request->instance;
        my $dic;
        my $cache_key = __PACKAGE__. '::dictionary_'. MT::Util::perl_sha1_digest_hex ($dictionary);
        if (!defined ($dic = $req->cache ($cache_key))) {
            foreach (split /[\r\n]/, $dictionary) {
                my @words = split /\s*[\|\t]\s*/;
                $dic->{$words[0]} = $words[$args-1]
                    if defined $words[$args-1];
            }
            $req->cache ($cache_key, $dic);
        }

        my $regex = join ('|', map { quotemeta } keys %$dic);
        $text =~ s!($regex)!$dic->{$1}!g;
    }
    $text;
});

1;