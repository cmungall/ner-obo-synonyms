#!/usr/bin/perl
use Data::Stag qw(:all);
use strict;

foreach my $file (@ARGV) {
    my $ont;
    if ($file =~ m@xml/(\w+)/\d+@) {
        $ont = $1;
    }
    my $doc_id = "?";
    my @spans = ();
    my $span = {};
    my $mid;
    my $mentionh = {};
    open(F,$file);
    while(<F>) {
        if (m@<annotations textSource="(\S+)\.txt"@) {
            $doc_id = $1;
        }
        if (m@<mention id="(\S+)"@) {
            $span->{inst} = $1;
        }
        if (m@<span start="(\d+)" end="(\d+)"@) {
            $span->{start} = $1;
            $span->{end} = $2;
        }
        if (m@<spannedText>(.*)</spannedText>@) {
            $span->{text} = $1;
        }
        if (m@</annotation>@) {
            push(@spans, $span);
            $span = {};
        }
 
        if (m@classMention id="(\S+)"@) {
            $mid = $1;
        }
        if (m@mentionClass id="(\S+)">(.*)</mentionClass>@) {
            $mentionh->{$mid} = { id=> $1, name=> $2};
        }

    }
    close(F);
    foreach my $span (@spans) {
        my $mention = $mentionh->{$span->{inst}};
        my @vals = ($doc_id, $span->{start}, $span->{end}, $span->{text}, $ont, $mention->{id}, $mention->{name});
        print join("\t", @vals)."\n";
    }
}
