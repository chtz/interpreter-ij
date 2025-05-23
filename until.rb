#!/usr/bin/env ruby

while line = STDIN.gets
    break if line.include?(ARGV[0]) 
    STDOUT.puts line
end