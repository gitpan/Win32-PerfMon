use Win32::PerfMon;


my $xxx = undef;

$xxx = new Win32::PerfMon;


my $ret = $xxx->add_counter("System", "System Up Time", 0 || die "Error Adding Object [$!]\n";

if($ret == 0)
{
	print $xxx->{'ERRORMSG'};
}
else
{
	print "All done\n";
}






