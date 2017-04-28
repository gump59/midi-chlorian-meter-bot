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

      route(/^@(.+) did ([^ ]+) (value [^ ]+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (value [^ ]+) (on [^ ]+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (value [^ ]+) (btw .+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (value [^ ]+) (on [^ ]+) (btw .+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (on [^ ]+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (on [^ ]+) (btw .+)$/, :event, command: true)
      route(/^@(.+) did ([^ ]+) (btw .+)$/, :event, command: true)

      route(/^@(.+) did ([^ ]+)$/, :event, command: true, help: {
        "@mention did task" => "Records that someone did a thing"
      })

      route(/^\s*list ([^ ]+)\s*$/, :list, command: true, help: {
        "list tasks" => "lists all available tasks"
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
        value = nil
        reply = "#{response.matches[0][0]} did #{response.matches[0][1]}"
        response.matches[0].each do |argu|
          if argu.match(/^value /)
            value = number_or_nil(argu[6..-1])
            reply = reply + " value #{value}"
          end
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
        addEvent(response.matches[0][0], response.matches[0][1], note, date, value)
      end

      def number_or_nil(string)
        num = string.to_i
        num if num.to_s == string
      end

      def addEvent(user, task_alias, note=nil, date=nil, value=nil)
        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        taskresponse = firebase.get("tasks", "orderBy=\"alias\"&equalTo=\"#{task_alias}\"")
        puts(taskresponse.body.keys[0])
        task = taskresponse.body.values[0]
	      if date==nil
	         date = Date.today.to_s
	      end
              if value==nil
                 customValue = false
                 value = task["value"]
              else
                 customValue = true
              end
	      firebaseResponse = firebase.push("events", { :user => user.strip, :task => taskresponse.body.keys[0], :value => value, :date => date, :note => note, :description => task["description"], :customValue => customValue, :timestamp => {:'.sv' => "timestamp"}})
      end

      def list(response)
        base_uri = 'https://midi-chlorian-meter.firebaseio.com/'
        firebase = Firebase::Client.new(base_uri)
        firebaseResponse = firebase.get("tasks")
        puts(firebaseResponse.body)
        firebaseResponse.body.each do |key, array|
          task_alias = array["alias"]
          value = array["value"]
          description = array["description"]
          response.reply("#{task_alias} = #{value} - #{description}")
        end
     end

      Lita.register_handler(self)
    end
  end
end
