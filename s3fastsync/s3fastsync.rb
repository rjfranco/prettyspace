#!/usr/bin/env ruby

if RUBY_VERSION =~ /^1\.8/ and not defined? JRUBY_VERSION
  raise "This script uses threads heavily and doesn't work well in Ruby 1.8. Use Ruby 1.9 or JRuby."
end

require 'rubygems'
require 'thread'
require 'thor'

class S3FastSync

  attr_reader :frombucket, :tobucket, :workers

  def initialize(from, to, options = {})
    @frombucket = from
    @tobucket = to
    @workers = options[:workers] || 10
    @worker_list = []
    @queue = Queue.new
    build_workers
  end

  def sync
    from = object_list(frombucket) 
    to = object_list(tobucket)
    to_copy = from - to
    report "#{to.length}/#{from.length} objects skipped, copying #{to_copy.length} objects"
    to_copy.each do |pair|
      size, src = *pair
      dest = src.gsub("s3://#{frombucket}", "s3://#{tobucket}")
      @queue.push "s3cmd cp --acl-public s3://#{frombucket}/#{src} s3://#{tobucket}/#{dest}"
    end
    workers.times do
      @queue.push :stop
    end
    self
  end

  def join
    abort_abort = proc {
      deadpid = $?
      if deadpid and (deadpid != @lspid)
        @worker_list.each do |worker|
          worker.kill
        end
      end
    }
    trap("INT", &abort_abort)
    trap("CLD", &abort_abort)
    @worker_list.each do |worker|
      worker.join
    end
  end

  private

  def object_list(bucket)
    objs = []
    list_objects(bucket).each do |line|
      group = line.split(/\s+/, 4)
      group[3] = group[3].chomp.gsub(%r{^s3://#{bucket}/}, '')
      objs << [group[2], group[3]] unless group[3] =~ %r{/$}
    end
    objs
  end

  def list_objects(bucket)
    report "Listing objects in #{bucket}"
    io = IO.popen("s3cmd ls -r s3://#{bucket}")
    @lspid = io.pid
    io
  end

  def build_workers
    queue = @queue
    workers.times do |widx|
      @worker_list << Thread.new do
        loop do
          job = queue.pop
          break if job == :stop
          unless system(job)
            raise "job #{job} failed with #$?"
          end
        end
      end
    end
  end

  def report(message)
    $stderr.puts "-- #{message}"
  end

end

class S3FastSyncCommand < Thor

  desc "sync FROM TO", "Fast-sync from one S3 bucket to another"
  method_option :workers, :aliases => '-w', :default => 10
  def sync(from, to)
    S3FastSync.new(from, to, options).sync.join
  end

end

if $0 == __FILE__
  S3FastSyncCommand.start
end
