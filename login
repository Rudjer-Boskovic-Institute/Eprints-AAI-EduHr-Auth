use EPrints;
use strict;

my $session = EPrints::Session->new();
my $url = $session->param( "target" );
$url = $session->get_repository->get_conf( "userhome" ) unless EPrints::Utils::is_set( $url );

# Get pre-authenticated username and "profile" information
my $username  = $ENV{'REMOTE_USER'};

# If all you have is REMOTE_USER you could look up more information (name,
# email, etc.) from an LDAP directory or database and continue below.
# Cf. http://search.cpan.org/perldoc?Net::LDAP
# Cf. http://search.cpan.org/perldoc?DBI
my $sn        = $ENV{'MCAC_ATTR_sn'};
my $givenName = $ENV{'MCAC_ATTR_givenName'};
my $mail      = $ENV{'MCAC_ATTR_mail'};

my $user;
if( EPrints::Utils::is_set( $username ) )
{
    $user = EPrints::DataObj::User::user_with_username( $session, $username );
}

if( !defined $user )
{
        # redirect to error page
        #$session->redirect( $session->get_repository->get_conf( "base_dir" ) . "/account_required.html" );

        $user = EPrints::DataObj::User::create( $session, "user" );
        $user->set_value( "username", $username );
}

# update user metadata
my $name = {};
$name->{family} = $sn;
$name->{given}  = $givenName;
$user->set_value( "name",  $name );
$user->set_value( "email", $mail );
$user->commit();

# generate login ticket
my @a = ();
srand;
for(1..16) { push @a, sprintf( "%02X",int rand 256 ); }
my $code = join( "", @a );

# add ticket to DB
my $ip = $ENV{REMOTE_ADDR};
my $userid = $user->get_id;
my $sql = "REPLACE INTO loginticket VALUES( '".EPrints::Database::prep_value($code)."', null, $userid, '".EPrints::Database::prep_value($ip)."', ".time.", ".(time+60*60*24*7)." )";
my $sth = $session->{database}->do( $sql );

# make cookie
my $cookie = $session->get_query->cookie(
        -name    => "eprints_session",
        -path    => "/",
        -value   => $code,
        -domain  => $session->get_repository->get_conf("cookie_domain"),
        -expires => "+6h",
);

# send cookie in error headers
my $r = $session->{request};
$r->err_headers_out->{"Set-Cookie"} = $cookie;

# redirect
EPrints::Apache::AnApache::send_status_line( $r, 302, "Moved" );
# fix up urlencoded $url or default to userhome otherwise
$url = _url_decode($url) || $session->get_repository->get_conf( "userhome" );
EPrints::Apache::AnApache::header_out( $r, "Location", $url );
EPrints::Apache::AnApache::send_http_header( $r );

# From CGI::Util
sub _url_decode {
    my $str = shift;
    $str =~ tr/+/ /;
    $str =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/eg;
    return $str;
}

$session->terminate;
