module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here

      puts "Hello World!"
      require 'firebase'
      base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
      firebase = Firebase::Client.new(base_uri)
      response = firebase.get("users")
      response.body.each do |key, array|
        puts "#{key}"
      end

      Lita.register_handler(self)
    end
  end
end
