require "kemal"
require "json"

SOCKETS = [] of HTTP::WebSocket

users_online = 0
items_created = 0
items_finished = 0
items = [] of Array(Int32 | JSON::Any)
item_counter = 0


def broadcast(msg)
    SOCKETS.each { |socket|
        socket.send msg
    }
end

ws "/onebigtodo" do |socket|
    SOCKETS << socket

    # Broadcast to all
    socket.on_message do |message|
        msg = JSON.parse(message)

        if msg["cmd"] == "join"
            users_online += 1
            broadcast({"cmd": "update_users_online", "data": users_online}.to_json)
            broadcast({"cmd": "update_todo", "data": items}.to_json)
        elsif msg["cmd"] == "leave"
            users_online -= 1
            broadcast({"cmd": "update_users_online", "data": users_online}.to_json)
        elsif msg["cmd"] == "msg"
            broadcast({"cmd": "msg", "data": msg["data"]}.to_json)
        elsif msg["cmd"] == "todo"
            item_counter += 1
            items << [item_counter, msg["data"]]
            broadcast({"cmd": "todo", "data": {"msg": msg["data"], "id": item_counter}}.to_json)
        elsif msg["cmd"] == "del"
            items.delete([msg["data"]["id"].as_i, msg["data"]["todo"]])
            broadcast({"cmd": "del", "data": msg["data"]["id"]}.to_json)
        end
    end

    socket.on_close do
        SOCKETS.delete socket

        SOCKETS.each { |socket|
            socket.send "leave"
        }
    end
end

get "/" do
    render "src/views/home.ecr"
end

Kemal.run
