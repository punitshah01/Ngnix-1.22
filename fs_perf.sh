MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
 
NAME=$1
RUN=$2
METRIC=$3
RUNS=$4
NUM_INST=$5
NAME="${NAME}_NUMINST${NUM_INST}"
 
# RAMP_STRING="after fixed_qps_exp"
RAMP_STRING="after warmup"
 
PERF_START_DELAY=30
PERF_DURATION=240
 
if [[ $METRIC == "emon" ]]; then
  NAME="${NAME}_WEMON"
elif [[ $METRIC == "perf" ]]; then
  NAME="${NAME}_WPERF"
fi
 
SESSION_NAME="feedsim_logs_${NAME}"
RAMP_FILE="/tmp/feedsim_log.txt"
 
LOGS_ROOT="${SESSION_NAME}_$(date +%m%d%Y%H%M%S)"
 
for((i=1;i<=RUNS;i++));
do
   LOGS_DIR="$LOGS_ROOT/run${i}"
   if [[ $RUN == "run" ]]; then
      mkdir -p $LOGS_DIR
   fi
  LOGS_FILE="$LOGS_DIR/fs_${NAME}_run${i}.txt"
  #cmd="./benchmarks/feedsim/run.sh 2>&1 | tee $LOGS_FILE"
  cmd="./run-feedsim-multi.sh ${NUM_INST} 2>&1 | tee $LOGS_FILE"
   data_cmd="$cmd"
   if [[ $METRIC == "emon" ]]; then
       #data_cmd="tmc -c \"$cmd\" -rl $RAMP_FILE -rs \"$RAMP_STRING\" -rt 2400 -n -u -x kumarpus -a ${SESSION_NAME}_RUN${i} -S 300 -E 2700 -w socket,core,uncore -Z metrics2"
       data_cmd="tmc -c \"$cmd\" -rl $RAMP_FILE -rs \"$RAMP_STRING\" -rt 1000 -n -u -x pshah -a ${SESSION_NAME}_RUN${i} -S 300 -E 900 -w socket,core,uncore -Z metrics2"
   elif [[ $METRIC == "perf" ]]; then
       cmd="bash $MY_PATH/collect_perf.sh $LOGS_DIR $RAMP_FILE \"$RAMP_STRING\" ${SESSION_NAME}_run${i} $PERF_DURATION $PERF_START_DELAY &"
       echo $cmd
 
       if [[ $RUN == "run" ]]; then
           eval $cmd
       fi
   fi
   echo $data_cmd
   if [[ $RUN == "run" ]]; then
     echo 1 | sudo tee /proc/sys/net/ipv4/tcp_tw_reuse
     echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
     echo 3 > /proc/sys/vm/drop_caches
     echo 1 > /proc/sys/vm/compact_memory
     ulimit -n 655350
     rm -rf benchmarks/feedsim/feedsim_results*.txt benchmarks/feedsim/feedsim-multi*.log
     eval $data_cmd
     cp benchmarks/feedsim/feedsim_results*.txt $LOGS_DIR
     cp benchmarks/feedsim/feedsim-multi*.log $LOGS_DIR
     cp $RAMP_FILE $LOGS_DIR
     sleep 30
   fi
done
