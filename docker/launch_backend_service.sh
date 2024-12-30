#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e # 使脚本在遇到任何命令返回非零退出状态时立即终止。

export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/ # 设置动态链接库路径

# Activate the specified Conda environment
source /usr/local/miniconda/bin/activate gptflow || exit
# Set the Python interpreter from the activated environment
PY=/usr/local/miniconda/envs/gptflow/bin/python3
# PY=python3


# Unset HTTP proxies that might be set by Docker daemon # 清除所有可能影响网络请求的代理设置
# export http_proxy=""; export https_proxy=""; export no_proxy=""; export HTTP_PROXY=""; export HTTPS_PROXY=""; export NO_PROXY=""


# Set default number of workers if WS is not set or less than 1 工作进程数和最大重试次数
if [[ -z "$WS" || $WS -lt 1 ]]; then
  WS=1
fi
MAX_RETRIES=5 # Maximum number of retries for each task executor and server

# Flag to control termination 初始化一个布尔值 STOP 为 false，用于控制脚本是否应停止运行
STOP=false

# Array to keep track of child PIDs 初始化一个空数组 PIDS，用于存储后台启动的子进程的 PID（进程 ID）
PIDS=()

# Function to handle termination signals | cleanup 函数：当接收到终止信号时，将 STOP 标志设为 true，然后遍历 PIDS 数组中的每个 PID，检查其是否存在并终止这些进程
cleanup() {
  echo "Termination signal received. Shutting down..."
  STOP=true
  # Terminate all child processes
  for pid in "${PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      echo "Killing process $pid"
      kill "$pid"
    fi
  done
  exit 0
}

# Trap SIGINT and SIGTERM to invoke cleanup 捕获 SIGINT 和 SIGTERM 信号，并调用 cleanup 函数进行清理工作
trap cleanup SIGINT SIGTERM




# Function to execute task_executor with retry logic 启动任务执行器的函数
task_exe(){
    local task_id=$1
    local retry_count=0
    while ! $STOP && [ $retry_count -lt $MAX_RETRIES ]; do
        echo "Starting task_executor.py for task $task_id (Attempt $((retry_count+1)))"
        $PY rag/svr/task_executor.py "$task_id"
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            echo "task_executor.py for task $task_id exited successfully."
            break
        else
            echo "task_executor.py for task $task_id failed with exit code $EXIT_CODE. Retrying..." >&2
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done

    if [ $retry_count -ge $MAX_RETRIES ]; then
        echo "task_executor.py for task $task_id failed after $MAX_RETRIES attempts. Exiting..." >&2
        cleanup
    fi
}





# Function to execute ragflow_server with retry logic 启动服务器的函数
run_server(){
    local retry_count=0
    while ! $STOP && [ $retry_count -lt $MAX_RETRIES ]; do
        echo "Starting ragflow_server.py (Attempt $((retry_count+1)))"
        $PY api/ragflow_server.py
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            echo "ragflow_server.py exited successfully."
            break
        else
            echo "ragflow_server.py failed with exit code $EXIT_CODE. Retrying..." >&2
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done

    if [ $retry_count -ge $MAX_RETRIES ]; then
        echo "ragflow_server.py failed after $MAX_RETRIES attempts. Exiting..." >&2
        cleanup
    fi
}

# Start task executors
for ((i=0;i<WS;i++))
do
  task_exe "$i" &
  PIDS+=($!)
done

# Start the main server
run_server &
PIDS+=($!)

# Wait for all background processes to finish
wait