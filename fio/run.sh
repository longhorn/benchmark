#!/bin/bash

set -e

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="/etc/fio-custom-config"

if [ -d "$CONFIG_DIR" ]; then
    echo "Use fio custom config in: $CONFIG_DIR"
else
    CONFIG_DIR="$CURRENT_DIR"
    echo "No custom config found, CONFIG_DIR is now set to default: $CONFIG_DIR"
fi

TEST_FILE=$1

# cmdline overrides the environment variable
if [ -z "$TEST_FILE" ]; then
	TEST_FILE=$FILE_NAME
fi

if [ -z "$TEST_FILE" ]; then
        echo Require test file name
        exit 1
fi

if [ x"$CPU_IDLE_PROF" = x"enabled" ]; then
	IDLE_PROF="--idle-prof=percpu"
fi

echo TEST_FILE: $TEST_FILE

TEST_OUTPUT=$2
if [ -z "$TEST_OUTPUT" ]; then
       TEST_OUTPUT=$OUTPUT
fi
if [ -z $TEST_OUTPUT ]; then
	TEST_OUTPUT="./test_device"
fi
echo TEST_OUTPUT_PREFIX: $TEST_OUTPUT

TEST_SIZE=$3
if [ -z "$TEST_SIZE" ]; then
       TEST_SIZE=$SIZE
fi
if [ -z "$TEST_SIZE" ]; then
       TEST_SIZE="10g"
fi
echo TEST_SIZE: $TEST_SIZE

if [ -n "$QUICK_MODE" ]; then
    echo "WARN: QUICK_MODE is being deprecated. Use MODE=\"quick\" instead"
    MODE="quick"
fi
if [ -z "$MODE" ]; then
    MODE="full"
fi
echo MODE: $MODE

case $MODE in

  "quick")
    IOPS_FIO="iops-quick.fio"
    BW_FIO="bandwidth-quick.fio"
    LAT_FIO="latency-quick.fio"
    ;;
  "random-read-iops")
    IOPS_FIO="iops-random-read.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "sequential-read-iops")
    IOPS_FIO="iops-sequential-read.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "random-read-bandwidth")
    IOPS_FIO=""
    BW_FIO="bandwidth-random-read.fio"
    LAT_FIO=""
    ;;
  "sequential-read-bandwidth")
    IOPS_FIO=""
    BW_FIO="bandwidth-sequential-read.fio"
    LAT_FIO=""
    ;;
  "random-read-latency")
    IOPS_FIO=""
    BW_FIO="latency-random-read.fio"
    LAT_FIO=""
    ;;
  "sequential-read-latency")
    IOPS_FIO=""
    BW_FIO="latency-sequential-read.fio"
    LAT_FIO=""
    ;;
  "random-write-iops")
    IOPS_FIO="iops-random-write.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "sequential-write-iops")
    IOPS_FIO="iops-sequential-write.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "random-write-bandwidth")
    IOPS_FIO="bandwidth-random-write.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "sequential-write-bandwidth")
    IOPS_FIO="bandwidth-sequential-write.fio"
    BW_FIO=""
    LAT_FIO=""
    ;;
  "random-write-latency")
    IOPS_FIO=""
    BW_FIO="latency-random-write.fio"
    LAT_FIO=""
    ;;
  "sequential-write-latency")
    IOPS_FIO=""
    BW_FIO="latency-sequential-write.fio"
    LAT_FIO=""
    ;;
  "full" | "")
    IOPS_FIO="iops.fio"
    BW_FIO="bandwidth.fio"
    LAT_FIO="latency.fio"
    ;;

  *)
    echo "ERROR: unknown mode"
    exit 1
    ;;
esac

if [ -n "$RATE_IOPS" ]; then
    rate_iops_flag="--rate_iops=$RATE_IOPS"
else
    rate_iops_flag=""
fi

if [ -n "$RATE" ]; then
    rate_flag="--rate=$RATE"
else
    rate_flag=""
fi


TEMP=./temp
OUTPUT_IOPS=${TEST_OUTPUT}-iops.json
OUTPUT_BW=${TEST_OUTPUT}-bandwidth.json
OUTPUT_LAT=${TEST_OUTPUT}-latency.json

keep_running="true"
while [ "$keep_running" == "true" ]; do
    if [ -n "$IOPS_FIO" ]; then
        echo Benchmarking $IOPS_FIO into $OUTPUT_IOPS
        fio $CONFIG_DIR/$IOPS_FIO $IDLE_PROF --filename=$TEST_FILE --size=$TEST_SIZE \
          --output-format=json --output=$TEMP $rate_iops_flag $rate_flag
        mv $TEMP $OUTPUT_IOPS
    fi
    if [ -n "$BW_FIO" ]; then
        echo Benchmarking $BW_FIO into $OUTPUT_BW
        fio $CONFIG_DIR/$BW_FIO $IDLE_PROF --filename=$TEST_FILE --size=$TEST_SIZE \
          --output-format=json --output=$TEMP $rate_iops_flag $rate_flag
        mv $TEMP $OUTPUT_BW
    fi
    if [ -n "$LAT_FIO" ]; then
        echo Benchmarking $LAT_FIO into $OUTPUT_LAT
        fio $CONFIG_DIR/$LAT_FIO $IDLE_PROF --filename=$TEST_FILE --size=$TEST_SIZE \
          --output-format=json --output=$TEMP $rate_iops_flag $rate_flag
        mv $TEMP $OUTPUT_LAT
    fi

    if [ -z "$SKIP_PARSE" ]; then
            $CURRENT_DIR/parse.sh $TEST_OUTPUT
    fi

    sleep 1

    if [ "$LONG_RUN" != "true" ]; then
        keep_running="false"
    fi
done

