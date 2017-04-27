module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here

      require 'firebase'

      route(/^echo\s+(.+)/, :echo, command: true, help: {
        "echo TEXT" => "Replies back with TEXT."
      })

      route(/^points/, :points, command: true, help: {
        "points" => "prints all points"
      })

      route(/^points\s+(.+)/, :points, command: true, help: {
        "points" => "prints points for given month"
      })

      def echo(response)
        response.reply(response.matches)
      end

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

      Lita.register_handler(self)
    end
  end
end
