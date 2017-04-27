module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here

      require 'firebase'
      base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
      firebase = Firebase::Client.new(base_uri)
      response = firebase.get("users")
      response.body.each do |key, array|
        points = firebase.get("events", "orderBy=\"user\"&equalTo=\"#{key}\"")
        score = 0
        points.body.each do |key, array|
          score += array["value"]
        end
        puts "#{key} = #{score}"
      end

      route(/^echo\s+(.+)/, :echo, command: true, help: {
        "echo TEXT" => "Replies back with TEXT."
      })

      Lita.register_handler(self)
    end
  end
end
