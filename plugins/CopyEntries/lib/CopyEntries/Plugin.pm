package CopyEntries::Plugin;
use strict;

use MT::Util qw( offset_time_list );

sub copy_entries {
    my $app = shift;
    my $plugin = MT->component( 'CopyEntries' );
    my $blog = $app->blog;
    my @tl = offset_time_list( time, $blog );
    my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    my $class = $app->param( '_type' );
    my $can_copy_entries = $class eq 'entry'
                                ? $app->can_do( 'create_new_entry' )
                                : $app->can_do( 'create_new_page' );
    unless ( $can_copy_entries ) {
        return $app->trans_error( 'Permission denied.' );
    }
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
            if ( my @tags = $entry->tags ) {
                $clone->set_tags( @tags );
            }
            $clone->save or die $clone->errstr;
            my @placements = MT->model( 'placement' )->load( { entry_id => $entry->id } );
            for my $placement ( @placements ) {
                my $clone_placement = $placement->clone;
                $clone_placement->id( undef );
                $clone_placement->entry_id( $clone->id );
                $clone_placement->save or die $clone->errstr;
            }
        }
    }
    my $redirect_url = $app->base . $app->uri( mode => 'list',
                                               args => {
                                                  _type => $class,
                                                  blog_id => $blog->id,
                                                  saved => 1,
                                               }
                                             );
    $app->redirect( $redirect_url );
}

1;
