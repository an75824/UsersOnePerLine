
package EPrints::Plugin::Import::UsersOnePerLine;

use EPrints::Plugin::Import::TextFile;
use strict;

use Data::Dumper;
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
	my $a = $plugin->{session};
	my @ids = ();
	my $input_data;
	while( defined($input_data = <$fh>) ) 
	{
		my $epdata = $plugin->convert_input($input_data );

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


	my $session = $plugin->{session};
	my $user_dataset = $session->get_archive()->get_dataset( "user" );
	my $list = $user_dataset->search(search_fields =>  [ { meta_fields => [qw(username )], value => $vals[0], }]);
	my $searchexp1 = $user_dataset->prepare_search();
	$searchexp1->add_field(
			fields => [
			$user_dataset->field('username')
    			],
		value => $vals[0],
  	);
	$list = $searchexp1->perform_search;
	my $count = $list->count;
	my $epdata = {
                        username   => $vals[0],
                        usertype   => $vals[1],
                        email      => $vals[2],
                        name       => { given=>$vals[3], family=>$vals[4] },
                        dept => $vals[5],
                 };

	if ($count gt 0)
	{
		print STDERR "*User already exists in the DB: $vals[0], times: $count\n";
		return undef;
	} else {
		print STDERR "__User $vals[0] imported in the DB\n";
		return $epdata;
	}
}

1;

