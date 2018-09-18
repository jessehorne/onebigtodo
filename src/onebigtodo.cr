require "kemal"
require "json"

SOCKETS = [] of HTTP::WebSocket

users_online = 0
items_created = 0
items_finished = 0
items = [] of Array(Int32 | JSON::Any)
item_counter = 0

last = Time.now()
now = Time.now()
limit = 1 # How many seconds must pass in between requests


def broadcast(msg)
    SOCKETS.each { |socket|
        socket.send msg
    }
end

ws "/onebigtodo" do |socket|
    SOCKETS << socket

    # Broadcast to all
    socket.on_message do |message|
        # Handle rate limiting
        now = Time.now()

        if now < (last+1.seconds)
            next
        end

        msg = JSON.parse(message)

        if msg["cmd"] == "join"
            users_online += 1
            broadcast({"cmd": "update_users_online", "data": users_online}.to_json)
            sleep(0.5)
            broadcast({"cmd": "update_todo", "data": items}.to_json)
        elsif msg["cmd"] == "leave"
            users_online -= 1
            broadcast({"cmd": "update_users_online", "data": users_online}.to_json)
            socket.close
        elsif msg["cmd"] == "msg"
            if msg["data"].as_s.size <= 60
                broadcast({"cmd": "msg", "data": msg["data"]}.to_json)
            end
        elsif msg["cmd"] == "todo"
            if msg["data"].as_s.size <= 60
                item_counter += 1
                items << [item_counter, msg["data"]]
                broadcast({"cmd": "todo", "data": {"todo": msg["data"], "id": item_counter}}.to_json)
            end
        elsif msg["cmd"] == "del"
            items.delete([msg["data"]["id"].as_i, msg["data"]["todo"]])
            broadcast({"cmd": "del", "data": msg["data"]["id"]}.to_json)
        end

        last = now
    end

    socket.on_close do
        users_online -= 1

        SOCKETS.delete socket

        SOCKETS.each { |socket|
            broadcast({"cmd": "update_users_online", "data": users_online}.to_json)
        }
    end
end

get "/" do
    render "src/views/home.ecr"
end

Kemal.run
