use Win32::PerfMon;
use strict;

my $ServerName = "<server name goes here>";
my $ret = undef;
my $err = undef;

my $xxx = Win32::PerfMon->new("\\\\$ServerName");

if($xxx != undef)
{
	$ret = $xxx->AddCounter("System", "System Up Time", -1);

	if($ret != 0)
	{
		$ret = $xxx->CollectData();

		if($ret  != 0)
		{
			my $secs = $xxx->GetCounterValue("System", "System Up Time", -1);

			if($secs > -1)
			{
				print "Seconds of Up Time = [$secs]\n";
			}
			else
			{
				$err = $xxx->GetErrorText();

				print "Failed to get the counter data ", $err, "\n";
			}
		}
		else
		{
			$err = $xxx->GetErrorText();

			print "Failed to collect the perf data ", $err, "\n";
		}
	}
	else
	{
		$err = $xxx->GetErrorText();

		print "Failed to add the counter ", $err, "\n";
	}
    
}
else
{				
	print "Failed to greate the perf object\n";
}