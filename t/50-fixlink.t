#!perl

use Test::More tests => 3;

use CommonMark::Massage;

-d "t" and chdir("t");

require "../examples/fixlink.pl";

my $doc = CommonMark->parse_document(<<EOD);
How about this [*link*](example.com)?
How about this [*link*](http://www.example.com)?
EOD
ok( $doc, "got a doc");

# Check standard HTML rendering.
is( $doc->render_html, <<EOD, "html" );
<p>How about this <a href="example.com"><em>link</em></a>?
How about this <a href="http://www.example.com"><em>link</em></a>?</p>
EOD

# Fix external links.
$doc->massage( { NODE_LINK => \&fixlink } );

# Verify.
is( $doc->render_html, <<EOD, "fixed" );
<p>How about this <a href="example.com"><em>link</em></a>?
How about this <a href="http://www.example.com" target="_blank" rel="noopener noreferrer"><em>link</em></a>?</p>
EOD

