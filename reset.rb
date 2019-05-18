if ARGV[0] == "--reset"
  system "rm db/*; rm -r material/*; rm -r user/*"
else
  puts "use ruby reset.rb --reset"
end
