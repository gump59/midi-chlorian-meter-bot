module Lita
  module Handlers
    class Jedipoints < Handler
      # insert handler code here
      require 'firebase'
      require 'date'

      on(:connected) do
        robot.join "81759_points_tracking_testing@conf.hipchat.com"
      end

      route(/^echo\s+(.+)/, :echo, command: true, help: {
        "echo TEXT" => "Replies back with TEXT."
      })

      route(/^points\s?(.*)/, :points, command: true, help: {
        "points" => "prints points for given month"
      })

      route(/^@(.+) did ([^ ]+) (on [^ ]+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (on [^ ]+) (btw .+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (btw .+)$/, :event, command: true)

      route(/^@(.+) did ([^ ]+)$/, :event, command: true, help: {
        "@mention did task" => "Records that someone did a thing"
      })

      def echo(response)
        response.reply(response.matches)
      end

      def points(response)

        month = Date.parse(response.matches[0][0]) rescue Date.parse(Date.today.strftime("%Y-%m-01"))

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
              eventDate = Date.parse(array["date"]) rescue nil
              if eventDate >= month && eventDate < month.next_month
                score += array["value"]
              end
            end
            response.reply("#{key} = #{score}")
        end
      end

      def event(response)
        date = nil
        note = nil
        reply = "#{response.matches[0][0]} did #{response.matches[0][1]}"
        response.matches[0].each do |argu|
          if argu.match(/^on /)
            date = Date.parse(argu[3..-1]) rescue Date.parse(Date.today.strftime("%Y-%m-%d"))
            reply = reply + " on #{date}"
          end
          
          if argu.match(/^btw /)
            note = argu[4..-1]
            reply = reply + " btw #{note}"
          end
        end
        response.reply(reply)
        addEvent(response.matches[0][0], response.matches[0][1], note, date)
      end

      def addEvent(user, task_alias, note=nil, date=nil)
        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        taskresponse = firebase.get("tasks", "orderBy=\"alias\"&equalTo=\"#{task_alias}\"")
        puts(taskresponse.body.keys[0])
        task = taskresponse.body.values[0]
	      if date==nil
	         date = Date.today.to_s
	      end
	      firebaseResponse = firebase.push("events", { :user => user.strip, :task => taskresponse.body.keys[0], :value => task["value"], :date => date, :note => note, :description => task["description"], :timestamp => {:'.sv' => "timestamp"}})
      end

      Lita.register_handler(self)
    end
  end
end
