#!/usr/bin/perl -w
#
# Quick perl hack to save docker logs for inspection during build.
# Why perl?  Because...I suppose I'm used to it and it's faster than 
# shell for me.
use strict;

my $scenario = shift(@ARGV) || "default";
my $data = `docker ps`;
print `mkdir -p logs`;

LINE:
foreach my $line (split(/\n/, $data)) {   
   $line =~ m/(.+?)\s+([^\s]+?)\s+/;
   my $containerId = $1;
   my $image = $2;

   next LINE if($containerId eq "CONTAINER");

   $image =~ s/[^A-Za-z0-9]/-/g;
   my $logfile = "$scenario-$image-$containerId.log";
   print "Dumping logs for container $containerId image $image to $logfile\n";

   `docker logs $containerId > logs/$logfile 2>&1`;
}
