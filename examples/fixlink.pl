#!/usr/bin/perl

use strict;
use warnings;
use CommonMark qw( :node );
use CommonMark::Massage;

# Usage:
#    $doc = CommonMark->parse...
#    $doc->massage( { NODE_LINK => \&fixlink } );
#    $doc->render_html;

sub fixlink {
    my ( $doc, $node, $entering ) = @_;
    return if $entering;		# EXIT processing only

    # Get the link and title.
    my $link  = $node->get_url   // "";
    my $title = $node->get_title // "";

    # Create a new custom node.
    my $n = CommonMark::Node->new(NODE_CUSTOM_INLINE);

    # The replacement 'enter' text.
    # Add target="_blank" rel="noopener noreferrer" when the link
    # is external.
    my $enter = qq{<a href="$link"};
    $enter .= qq{" title="$title"} if $title;
    $enter .= q{ target="_blank" rel="noopener noreferrer"}
      if $link =~ /^\w+:\/\//;
    $enter .= ">";
    $n->set_on_enter($enter);

    # The 'exit' text.
    $n->set_on_exit("</a>" );

    # NODE_LINK has a single child, copy it to the new node.
    my $t = $node->first_child;
    $n->append_child($t);

    # Replace the LINK node by the CUSTOM node.
    $node->replace($n);
}

1;
