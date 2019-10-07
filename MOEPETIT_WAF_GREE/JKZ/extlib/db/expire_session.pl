#!/usr/bin/perl -I /home/vhosts/JKZ

use JKZ::UsrWebDB;
use JKZ::Session;

my $permanent = 0;		# number of records with no expiration value set
my $expired = 0;		# number of records that have expired and were deleted
my $count = 0;

my $dbh = JKZ::UsrWebDB::connect ();
$dbh->do ('USE ApacheSession');
=pod
my $sth = $dbh->prepare ("SELECT id FROM sessions");
$sth->execute ();
while (my $id = $sth->fetchrow_array ())
{
	++$count;
	next unless defined ($sess_ref = JKZ::Session->open ($dbh, $id));
	if (!defined ($sess_ref->expires ()))	# session never expires
	{
		++$permanent;
	}
	elsif ($sess_ref->expires () < $sess_ref->now ())
	{
		$sess_ref->delete ();
		undef $sess_ref;
		++$expired;
	}
	$sess_ref->close () if defined ($sess_ref);
}
$sth->finish ();
=cut
my ($chunk_size, $count, $offset);
#@ FRAG
$chunk_size = 100;
$count = $dbh->selectrow_array ("SELECT COUNT(*) FROM sessions");
$offset = $count;
while ($offset > 0)
{
	$offset -= $chunk_size;
	if ($offset < 0)	# final chunk is only partial
	{
		$chunk_size += $offset;
		$offset = 0;
	}
	$offset = 0 if $offset < 0;
	my $sth = $dbh->prepare (
				"SELECT id FROM sessions LIMIT $offset, $chunk_size");
	$sth->execute ();
	my $sess_ref;
	while (my $id = $sth->fetchrow_array ())
	{
		$sess_ref = JKZ::Session->open_with_expiration ($dbh, $id);
		if (!defined ($sess_ref))
		{
			++$expired;		# session has expired
			next;
		}
		# session never expires if there's no expiration value
		++$permanent if !defined ($sess_ref->expires ());
		$sess_ref->delete ();
		$sess_ref->close ();
	}
	$sth->finish ();
}


#@ FRAG
$dbh->disconnect ();
print "$count sessions, $permanent permanent, $expired expired\n";
exit (0);
