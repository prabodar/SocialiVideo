require 'socket'               # Get sockets from stdlib

server = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
  client = server.accept       # Wait for a client to connect

  client.puts(Time.now.ctime)  # Send the time to the client

  msg = client.gets.chomp
   puts "#{msg}"

  client.puts "Closing the connection. Bye!"
first = "#{msg}".split(/~/).first
last = "#{msg}".split(/~/).last
puts first
puts last
if first.eql?("local_video_filename")
system (" bash /var/www/viddl-rb/copylocalfiles.sh #{last}") 

elsif first.eql?("Remove_local_video")
system (" rm /var/www/html/#{last}") 

else
system ("ruby viddl-rb #{msg} --save-dir /var/www/html")
end


system ( "rename 's/ /_/g' /var/www/html/*")
system ( "chmod 755 /var/www/html/*")
  client.close                 # Disconnect from the client
}
