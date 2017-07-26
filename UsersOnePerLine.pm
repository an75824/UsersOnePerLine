
package EPrints::Plugin::Import::UsersOnePerLine;

use EPrints::Plugin::Import::TextFile;
use strict;

our @ISA = qw/ EPrints::Plugin::Import::TextFile /;

# import users as:

# username:usertype:email:password:given_name:family_name

# password should not be crypted

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Users (one per line)";
	$self->{visible} = "";
	$self->{produce} = [ 'list/user' ];

	return $self;
}

sub input_fh
{
	my( $plugin, %opts ) = @_;

	my $fh = $opts{fh};

	my @ids = ();
	my $input_data;
	while( defined($input_data = <$fh>) ) 
	{
		my $epdata = $plugin->convert_input( $input_data );

		next unless( defined $epdata );
		
		my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}
	
	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );
}

sub convert_input 
{
	my ( $plugin, $input_data ) = @_;

	return if $input_data =~ m/^\s*(#|$)/;
	chomp $input_data;
	my @vals = split /:/ , $input_data;

	my $epdata = {
			username   => $vals[0],
			usertype   => $vals[1],
			email      => $vals[2],
			password   => EPrints::Utils::crypt_password( $vals[3], $plugin->{session} ),
			name	   => { given=>$vals[4], family=>$vals[5] },
		 };
	return $epdata;
}

1;
