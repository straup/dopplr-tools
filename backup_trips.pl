#!/usr/bin/env perl
use strict;

use Getopt::Std;
use Config::Simple;

use Net::Dopplr;
use XML::XML2JSON;

use File::Path;
use File::Spec;
use FileHandle;

{
        &main();
        exit;
}

sub main {

        my %opts = ();
        getopts('c:', \%opts);

        my $cfg = Config::Simple->new($opts{'c'});

        my $cnv = XML::XML2JSON->new();       

        my $d = Net::Dopplr->new($cfg->param("dopplr.auth_token"));
        my $info = $d->trips_info();
        
        foreach my $trip (@{$info->{'trip'}}){

                my $start = $trip->{'start'};
                $start =~ s/-/\//g;
                
                my $id = $trip->{'id'};
                
                $trip->{'city'}->{'url'} =~ /place\/(.*)$/;
                my $city = $1;
                $city =~ s/\//-/g;

                # dirty hack...probably others out there

                if (exists($trip->{'tag'})){
                        $trip->{'tag'} = join(" ", @{$trip->{'tag'}});
                }

                my $backup = $cfg->param("dopplr.trips_backup_directory");

                my $root = File::Spec->catdir($backup, $start);
                my $fname = join("-", $id, $city) . ".xml";
                
                my $dump = File::Spec->catfile($root, $fname);               

                if (-f $dump){
                        next;
                }
                
                if (! -d $root){
                        mkpath([$root], 1, 0755);
                }
                
                print STDOUT "write $fname\n";

                my $fh = FileHandle->new();
                $fh->open(">$dump");
                binmode($fh, ':utf8');

                eval {                        
                        $fh->print($cnv->obj2xml({'trip' => $trip}));
                        $fh->close();
                };

                if ($@){
                        warn "failed to write $fname, $@";
                        unlink($dump);
                }
        }

        return 1;
}

exit;
