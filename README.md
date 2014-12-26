Bash Websocket Client
=====================

A simple websocket client written in bash. It sets up a websocket connection, performs a compliant handshake, and sends messages of up to 126 bytes (I'll work on longer messages eventually). I think it does proper masking and framing per [RFC 6455](https://tools.ietf.org/html/rfc6455).

There's a few constants in the script because running it will all the correct parameters via CLI would be too long. I've included an example that's configured to talk to a publically-availble websocket server.

##Included Files

  * `send_to_websocket.sh` - This will open up a connection and send its CLI argument to the server defined in the script.
    * usage: `./send_to_websocket.sh "MY AWESOME MESSAGE"`
  * `websocket_echo_example.sh` - This is an interactive script that will open a connection to the [WebSocket.org Echo Server](http://www.websocket.org/echo.html) and will send any user input to it. It displays the server responses. The responses have have some leading special characters that are the header frame bytes that I didn't bother to remove.
    * usage: `./websocket_echo_example.sh`

##TODO

 * Send longer messages. Websocket framing is tricky in bash.
 * Prettify the interactive script.
