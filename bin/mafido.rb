#!/usr/bin/env ruby

require_relative "../lib/mafido/mafido"

include Mafido

$stdout.sync

options = {
  jobs: 1,
  extension: nil,
  path: File.expand_path(File.dirname($0)),
  mock: false,
  remove: false,
  command: nil,
  verbose: false,
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--verbose", "verbosity of logging") do
    Mafido.verbose = true
    options[:verbose] = true
  end

  opts.on("-j NUM", "--jobs NUM", Integer, "Number of parallel jobs (CPUs)") do |j|
    options[:jobs] = j
  end

  opts.on("-e EXT", "--extension EXT", "File extension to process (e.g., flac)") do |ext|
    options[:extension] = ext
  end

  opts.on("-p PATH", "--path PATH", "Input path (default: current dir)") do |path|
    options[:path] = path
  end

  opts.on("-l", "--list", "list result") do
    f = Files.new(**options)
    collection = f.collect(**options)
    puts collection.files
    exit
  end


  opts.on("-c COMMAND", "--command COMMAND", "Command to be executed on every result entry - can also be STDIN") do |path|
    options[:command] = path
  end

  opts.on("-m", "--mock", "only mock - dont do anything") do
    Mafido.verbose = options[:verbose] = true
    options[:mock] = true
  end

  opts.on("-r", "--remove", "remove input after processing") do
    options[:remove] = true
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit
  end
end.parse!


command =
  if !STDIN.tty? && !STDIN.eof?
    STDIN.read.strip
  elsif options[:command]
    options[:command]
  else
    abort "No command provided via --command or STDIN"
  end


options[:command] = command
puts "options: #{options.inspect}"


f = Files.new(**options)
collection = f.collect(**options)

pr = Processor.new(collection, command)
pr.process!(**options)

