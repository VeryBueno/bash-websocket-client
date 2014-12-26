#!/bin/bash
# This script sends a message of up to 127 bytes to a websocket server.
# It works by initiating a connection with netcat, doing the websocket
# handshake, then framing/masking the message to send to the sever.
# Usage: send_to_websocket.sh "My awesome message"


# ====== Set the constants below =======

# The websocket server and port
WS_SERVER="localhost"
WS_PORT=8888

# The header values to use when performing a websocket handshake.
HS_GET="/"
HS_ORIGIN="http://localhost"
HS_HOST="localhost"

# This script uses a local netcat server to forward messages to the remote server.
WS_LOCAL_PORT=9999

# ===== Do not edit below this line =====

# generate a random Sec-WebSocket-Key
random_bytes="$(dd if=/dev/urandom bs=16 count=1 2> /dev/null)"
HS_KEY=`echo "$random_bytes" | base64`

handshake="\
GET $HS_GET HTTP/1.1\r
Origin: $HS_ORIGIN\r
Connection: Upgrade\r
Host: $HS_HOST\r
Sec-WebSocket-Key: $HS_KEY\r
Upgrade: websocket\r
Sec-WebSocket-Version: 13\r\n\r\n"

function dec_to_hex {
   num=`echo 'obase=16; ibase=10; '"$1"| bc`
   if [ ${#num} -eq 1 ]
   then
      num=0"$num"
   fi
   printf "%s" $num
}

# translate a char or byte to an int
function ord {
   echo -n "$1" | hexdump -v -e '"%d"'
}

# mask a message ($1) with a masking key ($2).
function mask_msg {
   msg=$1; msg_len=${#msg}
   mk=$2; mk_len=${#mk}

   masked=""

   for (( i=0; i<$msg_len; i++ ))
   do
      mk_i=`expr $i % $mk_len`

      msg_chr=${msg:$i:1}
      mk_chr=${mk:$mk_i:1}

      msg_int=`ord "$msg_chr"`
      mk_int=`ord "$mk_chr"`

      let "msg_int ^= $mk_int"

      chr_val="\x`dec_to_hex $msg_int`"
      masked+=$chr_val
   done
   echo -n -e $masked
}

# generate the opcode and message length for the message
function make_header {
   msg_size=${#1}
   first_byte="\x81"
   second_byte=128
   let "second_byte ^= $msg_size"
   second_byte=$(dec_to_hex $second_byte)
   echo -n -e "$first_byte\x$second_byte"
}

# start a local nc server to forward the handshake
# and message to the websocket server
# redirect to something other than /dev/null to see responses
nc -l -k -p $WS_LOCAL_PORT | nc $WS_SERVER $WS_PORT > /dev/null &
nc1_pid=$!
nc2_pid=`jobs -p`
echo -ne "$handshake" | nc localhost $WS_LOCAL_PORT

# message to send
msg="$1"

# generate a random 4-byte masking key
masking_key="$(dd if=/dev/urandom bs=4 count=1 2> /dev/null)"

# generate the header and mask the message
header=$(make_header "$msg")
masked_msg=$(mask_msg "$msg" "$masking_key")
to_send="$header$masking_key$masked_msg"

echo -n "$to_send" | nc localhost $WS_LOCAL_PORT

# kill the spawned netcats
kill $nc1_pid $nc2_pid
