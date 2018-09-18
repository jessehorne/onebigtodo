function obt_ready() {
    var socket = new WebSocket("ws://localhost:3000/onebigtodo");

    var users_online = document.getElementById("obt_users_online");
    var items_created = document.getElementById("obt_items_created");
    var items_finished = document.getElementById("obt_items_finished");
    var todo_input = document.getElementById("obt_todo_input");
    var todo_list = document.getElementById("obt_todo_list");
    var message_input = document.getElementById("obt_message_input");
    var message_list = document.getElementById("obt_messages");


    var users_online_value = 0;
    var items_created_value = 0;
    var items_finished_value = 0;


    function update_stats() {
        users_online.innerHTML = users_online_value;
        items_created.innerHTML = items_created_value;
        items_finished.innerHTML = items_finished_value;
    }

    function make_msg(command, data) {
        var message = {
            "cmd": command,
            "data": data
        };

        return JSON.stringify(message);
    }

    function create_todo(data) {
        var div = document.createElement("div");
        div.setAttribute("class", "list-group-item");
        div.setAttribute("id", "todo_" + data[0]);
        div.setAttribute("obt_id", data[0]);

        var i = document.createElement("i");
        i.setAttribute("class", "fas fa-times");
        i.onclick = function() {
            var new_data = {
                "id": data[0],
                "todo": data[1]
            };
            socket.send(make_msg("del", new_data));
        }

        div.appendChild(i);

        var text = document.createTextNode(data[1]);
        div.appendChild(text);

        todo_list.appendChild(div);
    }

    message_input.onkeydown = function(e) {
        if (e.keyCode == 13) {
            if (message_input.value.length == 0) {
                return false;
            }

            if (message_input.value.length >= 200) {
                return false;
            }

            socket.send(make_msg("msg", message_input.value));
            message_input.value = "";

            return false;
        }
    }

    todo_input.onkeydown = function(e) {
        if (e.keyCode == 13) {
            if (todo_input.value.length == 0) {
                return false;
            }

            if (todo_input.value.length > 60) {
                return false;
            }

            socket.send(make_msg("todo", todo_input.value));
            todo_input.value = "";

            return false;
        }
    }

    socket.addEventListener("open", function(event) {
        socket.send(make_msg("join"));
    });

    socket.addEventListener("message", function(event) {
        var data = JSON.parse(event.data);

        if (data.cmd == "update_users_online") {
            users_online_value = data.data;
        } else if (data.cmd == "msg") {
            var div = document.createElement("div");
            div.setAttribute("class", "list-group-item");
            div.innerText = data.data;
            message_list.appendChild(div);
        } else if (data.cmd == "todo") {
            create_todo([data.data["id"], data.data["todo"]])
        } else if (data.cmd == "update_todo") {
            for (var i in data.data) {
                console.log(data.data[i]);
                if (!document.getElementById("todo_"+data.data[i][0])) {
                    create_todo(data.data[i])
                }
            }
        } else if (data.cmd == "del") {
            var div = document.getElementById("todo_" + data.data);
            todo_list.removeChild(div);
        }

        update_stats();
    });

    console.log("OBT is ready.");
}

document.body.onload = obt_ready();
