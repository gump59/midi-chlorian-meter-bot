module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here

      require 'firebase'
      require 'date'

      route(/^echo\s+(.+)/, :echo, command: true, help: {
        "echo TEXT" => "Replies back with TEXT."
      })

      route(/^points*\s*(.+)/, :points, command: true, help: {
        "points" => "prints points for given month"
      })

      route(/@(.+) did (.+)/, :event, command: true, help: {
        "@mention did task" => "Records that someone did a thing"
      })

      def echo(response)
        response.reply(response.matches)
      end

      def points(response)

        month = Date.parse(response.matches[0][0]) rescue Date.today.strftime("%Y-%m-01")

        if month != nil
          response.reply("for month: #{month}")
        end

        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        firebaseResponse = firebase.get("users")
        firebaseResponse.body.each do |key, array|
            points = firebase.get("events", "orderBy=\"user\"&equalTo=\"#{key}\"")
            score = 0
            points.body.each do |key, array|
              response.reply("date: #{array}")
              eventDate = Date.parse(array["date"]) rescue nil
              if eventDate > month
                score += array["value"]
              end
            end
            response.reply("#{key} = #{score}")
        end
      end

      def event(response)
	       response.reply("#{response.matches[0][0]} did #{response.matches[0][1]}")
         addEvent(response.matches[0][0], response.matches[0][1])
      end

      def addEvent(user, task_alias, note=nil, date=nil)
        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        taskresponse = firebase.get("tasks", "orderBy=\"alias\"&equalTo=\"#{task_alias}\"")
        puts(taskresponse.body.keys[0])
        task = taskresponse.body.values[0]
	      if note==nil
	          note = task["description"]
	      end
	      if date==nil
	         date = Date.today.to_s
	      end
	      firebaseResponse = firebase.push("events", { :user => user, :task => taskresponse.body.keys[0], :value => task["value"], :date => date, :note => note})
      end

      Lita.register_handler(self)
    end
  end
end
