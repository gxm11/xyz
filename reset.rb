if ARGV[0] == "-y"
  system "rm db/*; rm -r material/*; rm -r user/*"
else
  puts "use ruby reset.rb -y"
end
