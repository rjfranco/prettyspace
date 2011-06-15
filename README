# "prettyspace"

Small projects by mboeh.

## s3fastsync.rb

### Description

A script to recursively copy the contents of one Amazon S3 bucket to another.
Spins off multiple worker threads to lessen the effect of S3's intense latency.
Excludes objects which have the same key and size on the destination bucket as
on the source bucket. This isn't as reliable as a checksum would be, but it
works just as well in many cases.

Works best in Ruby 1.9 or JRuby; presumably also works fine in Rubinius. Uses
s3cmd for the actual S3 work. You can find it here:

  http://s3tools.org/s3cmd

It's also available as the 's3cmd' package on Debian and probably as something
similar in other package systems. You'll also need to set up your authentication
in s3cmd before running this script.

Requires the 'thor' gem.

### Usage
  
  s3fastsync.rb sync [-w 10] frombucket tobucket

You can pass another value for -w to use more or fewer worker threads.

### Bugs/Caveats

* It doesn't check to see if s3cmd exists or is properly set up before running.
* It doesn't take any arguments for s3cmd.
* It assumes you want a public ACL for the destination files.
* Probably lots of other things.

If anybody cares to fix any of these, I'd love to see some pull requests.

### Credit

This script was developed while working at CrowdCompass, Inc.
(http://crowdcompass.com) and was released as free software with their permission.

Thanks!
