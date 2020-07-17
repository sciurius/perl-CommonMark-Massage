#! perl

package CommonMark::Massage;

use warnings;
use strict;
use CommonMark qw( :node :event );

our $VERSION = '0.01';

=head1 NAME

CommonMark::Massage - Manipulate CommonMark AST

=head1 SYNOPSIS

    use CommonMark qw(:node :event);
    use CommonMark::Massage;

    my $parser = CommonMark::Parser->new;
    $parser->feed("Hello world");
    my $doc = $parser->finish;

    # Apply function to exit event of text nodes.
    my $doc->massage ( { NODE_TEXT =>
                         { EVENT_EXIT => sub { ... } } } );
    $doc->render_html;

=head1 DESCRIPTION

The massage function can be used to manipulate the AST as produced by
the CommonMark parsers.

=head1 METHODS

The methods are defined in the CommonMark::Node namespace, so they can
be applied to the result of parsing.

=head2 massage

One argument: a hash ref of node names, each containing a hashref of
events that point to a subroutine. For example:

    { NODE_TEXT => { EVENT_EXIT => \&fixit } }

The subroutine is called with two arguments, the doc tree and the node.

It is free to do whatever it wants, but caveat emptor.

See L<EXAMPLES> for some example routines.

=cut

sub CommonMark::Node::massage {
    my ( $doc, $ctl ) = @_;

    my $fixmap;
    $fixmap = sub {
	my $c = $_[0];
	no strict 'refs';
	return { map { my $k = $_;
		       ( ( /^\d+$/ ? $_ : $_->() ) =>
			 { map {
			     ( ( /^\d+$/ ? $_ : $_->() ) => $c->{$k}->{$_} )
			   } keys(%{$c->{$k}}) }
		     ) } keys(%$c) };
    };
    $ctl = $fixmap->($ctl);
    my $iter = $doc->iterator;

    while (my ($ev_type, $node) = $iter->next) {
	my $node_type = $node->get_type;

	if ( $ctl->{$node_type} ) {
	    next unless my $code = $ctl->{$node_type}->{$ev_type};
	    $code->( $doc, $node );
	}
    }
}

=head2 reveal

This method dumps the AST nodes/events for entertainment and debugging.

The result is returned as a string.

=cut

my $node_names;
my $event_types;

sub CommonMark::Node::reveal {
    my ( $doc, $fh ) = @_;

    _constants() unless $node_names;

    my $iter = $doc->iterator;
    my $res = "";
    while (my ($ev_type, $node) = $iter->next) {
	my $node_type = $node->get_type;
	$res .= "$event_types->[$ev_type] $node_names->[$node_type]\n";
    }
    $res;
}

sub _constants {
    my @names = qw(
        NODE_NONE
        NODE_DOCUMENT
        NODE_BLOCK_QUOTE
        NODE_LIST
        NODE_ITEM
        NODE_CODE_BLOCK
        NODE_HTML
        NODE_PARAGRAPH
        NODE_HEADER
        NODE_HRULE
        NODE_TEXT
        NODE_SOFTBREAK
        NODE_LINEBREAK
        NODE_CODE
        NODE_INLINE_HTML
        NODE_EMPH
        NODE_STRONG
        NODE_LINK
        NODE_IMAGE
        NODE_CUSTOM_BLOCK
        NODE_CUSTOM_INLINE
        NODE_HTML_BLOCK
        NODE_HEADING
        NODE_THEMATIC_BREAK
        NODE_HTML_INLINE
     );
    my @values = (
        NODE_NONE,
        NODE_DOCUMENT,
        NODE_BLOCK_QUOTE,
        NODE_LIST,
        NODE_ITEM,
        NODE_CODE_BLOCK,
        NODE_HTML,
        NODE_PARAGRAPH,
        NODE_HEADER,
        NODE_HRULE,
        NODE_TEXT,
        NODE_SOFTBREAK,
        NODE_LINEBREAK,
        NODE_CODE,
        NODE_INLINE_HTML,
        NODE_EMPH,
        NODE_STRONG,
        NODE_LINK,
        NODE_IMAGE,
        NODE_CUSTOM_BLOCK,
        NODE_CUSTOM_INLINE,
        NODE_HTML_BLOCK,
        NODE_HEADING,
        NODE_THEMATIC_BREAK,
        NODE_HTML_INLINE,
     );
    for ( @names ) {
	$node_names->[shift(@values)] = $_;
    }
    $event_types = [ qw( NONE DONE ENTR EXIT ) ];
}

=head1 EXAMPLES

This example manipulates links. Normally a link is rendered as

    <a href="uri">text</a>

After massaging with

    $doc->massage( { NODE_LINK => { EVENT_EXIT => \&fixlink } } )

this will become for non-local links:

    <a href="http://www.example.com" target="_blank">text</a>

This is the subroutine

    sub fixlink {
	my ( $doc, $node ) = @_;
        # Get the link and title.
	my $link = $node->get_url // "";
	my $title = $node->get_title // "";

	# Create a new custom node.
	my $n = CommonMark::Node->new(NODE_CUSTOM_INLINE);

	# The replacement 'enter' text.
	my $enter = "<a href=\"$link\"";
	$enter .= " title=\"$title\"" if $title;
	$enter .= " target=\"_blank\"" if $link =~ /^\w+:\/\//;
	$enter .= ">";
	$n->set_on_enter($enter);

	# The 'exit' text.
	$n->set_on_exit("</a>" );

	# NODE_LINK has a single child, copy it to the new node.
	my $t = $node->first_child;
	$n->append_child($t);
	$t->unlink;

	# Replace the LINK node by the CUSTOM node.
	$node->replace($n);
    }

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-CommonMark-Massage.

You can find documentation for this module with the perldoc command.

    perldoc CommonMark::Massage

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 SEE ALSO

L<CommonMark>

=head1 COPYRIGHT & LICENSE

Copyright 2020 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
