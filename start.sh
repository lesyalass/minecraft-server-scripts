#!/bin/bash

SESSION="mc"
JAR="server.jar"
MEM="2G"
MINECRAFT_DIR="/opt/minecraft/paper"

cd "$MINECRAFT_DIR" || exit 1

tmux has-session -t "$SESSION" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "Stopping the running Minecraft server"
  tmux send-keys -t "$SESSION" "stop" C-m
  sleep 10
  tmux kill-session -t "$SESSION" 2>/dev/null
fi

echo "Starting Minecraft server in tmux session '$SESSION'"
tmux new-session -d -s "$SESSION" "java -Xmx$MEM -Xms$MEM -jar $JAR nogui"

