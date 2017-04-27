module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here

      require 'firebase'

      def points(response)
        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        firebaseResponse = firebase.get("users")
        firebaseResponse.body.each do |key, array|
            points = firebase.get("events", "orderBy=\"user\"&equalTo=\"#{key}\"")
            score = 0
            points.body.each do |key, array|
              score += array["value"]
            end
            response.reply("#{key} = #{score}")
        end
      end

      route(/^echo\s+(.+)/, :echo, command: true, help: {
        "echo TEXT" => "Replies back with TEXT."
      })

      route(/^points\s+(.+)/, :points, command: true, help: {
        "points" => "Does some points stuff, I hope"
      }

      def echo(response)
        response.reply(response.matches)
      end

      Lita.register_handler(self)
    end
  end
end
