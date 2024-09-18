#!/bin/bash

set -e

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"

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
    "random-write-iops")
        IOPS_FIO="iops-random-write.fio"
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
OUTPUT_READ_IOPS=${TEST_OUTPUT}-read-iops.json
OUTPUT_WRITE_IOPS=${TEST_OUTPUT}-write-iops.json
OUTPUT_READ_BW=${TEST_OUTPUT}-read-bandwidth.json
OUTPUT_WRITE_BW=${TEST_OUTPUT}-write-bandwidth.json
OUTPUT_READ_LAT=${TEST_OUTPUT}-read-latency.json
OUTPUT_WRITE_LAT=${TEST_OUTPUT}-write-latency.json

keep_running="true"
while [ "$keep_running" == "true" ]; do
    if [ -n "$IOPS_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking random read iops
        fio $CURRENT_DIR/$IOPS_FIO $IDLE_PROF --section=rand-read-iops --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_IOPS $rate_iops_flag $rate_flag

        echo Benchmarking random write iops
        fio $CURRENT_DIR/$IOPS_FIO $IDLE_PROF --section=rand-write-iops --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_IOPS $rate_iops_flag $rate_flag
    fi

    if [ -n "$BW_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking sequential read bandwidth
        fio $CURRENT_DIR/$BW_FIO $IDLE_PROF --section=seq-read-bandwidth --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_BW $rate_iops_flag $rate_flag
 
        echo Benchmarking sequential write bandwidth
        fio $CURRENT_DIR/$BW_FIO $IDLE_PROF --section=seq-write-bandwidth --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_BW $rate_iops_flag $rate_flag
    fi

    if [ -n "$LAT_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking random read latency
        fio $CURRENT_DIR/$LAT_FIO $IDLE_PROF --section=rand-read-lat --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_LAT $rate_iops_flag $rate_flag

        echo Benchmarking random write latency
        fio $CURRENT_DIR/$LAT_FIO $IDLE_PROF --section=rand-write-lat --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_LAT $rate_iops_flag $rate_flag
    fi

    if [ -z "$SKIP_PARSE" ]; then
            $CURRENT_DIR/parse.sh $TEST_OUTPUT
    fi

    sleep 1

    if [ "$LONG_RUN" != "true" ]; then
        keep_running="false"
    fi
done

