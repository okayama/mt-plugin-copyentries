package MT::Plugin::CopyEntries;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

use MT::Util qw( offset_time_list );

our $PLUGIN_NAME = 'CopyEntries';
our $PLUGIN_VERSION = '1.0';

my $plugin = new MT::Plugin::CopyEntries( {
    id => $PLUGIN_NAME,
    key => lc $PLUGIN_NAME,
    name => $PLUGIN_NAME,
    version => $PLUGIN_VERSION,
    description => '<MT_TRANS phrase=\'Copy selected entries from list of entries.\'>',
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    l10n_class => 'MT::' . $PLUGIN_NAME . '::L10N',
} );
MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        applications => {
            cms => {
                list_actions => {
                    entry => {
                        copy_entries => {
                            label => 'Copy',
                            order => 100,
                            code => \&_copy_entries,
                            permission => 'edit_all_posts',
                        },
                    },
                    page => {
                        copy_entries => {
                            label => 'Copy',
                            order => 100,
                            code => \&_copy_entries,
                            permission => 'edit_all_posts',
                        },
                    },
                },
            },
        },
   } );
}

sub _copy_entries {
    my $app = shift;
    my $blog = $app->blog;
    my @tl = &offset_time_list( time, $blog );
    my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    my $class = $app->param( '_type' );
    my @entry_ids = $app->param( 'id' );
    for my $entry_id ( @entry_ids ) {
        my $entry = MT->model( $class )->load( { id => $entry_id } );
        if ( $entry ) {
            my $clone = $entry->clone;
            $clone->title( '(' . $plugin->translate( 'Copy' ) . ') ' . $entry->title );
            $clone->status( MT::Entry::HOLD() );
            $clone->basename( undef );
            $clone->id( undef );
            $clone->authored_on( $ts );
            $clone->created_on( $ts );
            $clone->modified_on( $ts );
            $clone->save or die $clone->errstr;
        }
    }
    my $redirect_url = $app->base . $app->uri( mode => 'list_' . $class,
                                               args => {
                                                  blog_id => $blog->id,
                                                  saved => 1,
                                               }
                                             );
    $app->redirect( $redirect_url );
}

sub _debug {
    my ( $data ) = @_;
    use Data::Dumper;
    MT->log( Dumper( $data ) );
}

1;
