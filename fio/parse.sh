#!/bin/bash

set -e

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"
source $CURRENT_DIR/func.sh

if [ -z $1 ];
then
        echo Require FIO output prefix
        exit 1
fi

PREFIX=${1}
OUTPUT_READ_IOPS=${PREFIX}-read-iops.json
OUTPUT_WRITE_IOPS=${PREFIX}-write-iops.json
OUTPUT_READ_BW=${PREFIX}-read-bandwidth.json
OUTPUT_WRITE_BW=${PREFIX}-write-bandwidth.json
OUTPUT_READ_LAT=${PREFIX}-read-latency.json
OUTPUT_WRITE_LAT=${PREFIX}-write-latency.json

if [ -f "$OUTPUT_READ_IOPS" ]; then
        parse_read_iops $OUTPUT_READ_IOPS
fi

if [ -f "$OUTPUT_WRITE_IOPS" ]; then
        parse_write_iops $OUTPUT_WRITE_IOPS
fi

if [ -f "$OUTPUT_READ_BW" ]; then
        parse_read_bw $OUTPUT_READ_BW
fi

if [ -f "$OUTPUT_WRITE_BW" ]; then
        parse_write_bw $OUTPUT_WRITE_BW
fi

if [ -f "$OUTPUT_READ_LAT" ]; then
        parse_read_lat $OUTPUT_READ_LAT
fi

if [ -f "$OUTPUT_WRITE_LAT" ]; then
        parse_write_lat $OUTPUT_WRITE_LAT
fi

RESULT=${1}.summary

if [ -n "$QUICK_MODE" ]; then
    MODE="quick"
fi
if [ -z "$MODE" ]; then
    MODE="full"
fi
MODE_TEXT="Mode: $MODE"

SIZE_TEXT="Size: 10g"
if [ -n "$SIZE" ]; then
	SIZE_TEXT="Size: $SIZE"
fi

SUMMARY="
=========================
FIO Benchmark Summary
For: $PREFIX
CPU Idleness Profiling: $CPU_IDLE_PROF
$SIZE_TEXT
$MODE_TEXT
=========================
"

if [ x"$CPU_IDLE_PROF" = x"enabled" ]; then
	printf -v cxt "IOPS (Read/Write)\n$FMT$FMT$FMT\n"\
		"Random:" \
		"$(commaize $RAND_READ_IOPS) / $(commaize $RAND_WRITE_IOPS)" \
		"Sequential:" \
		"$(commaize $SEQ_READ_IOPS) / $(commaize $SEQ_WRITE_IOPS)" \
		"CPU Idleness:" \
		"$CPU_IDLE_PCT_IOPS%"
	SUMMARY+=$cxt

	printf -v cxt "Bandwidth in KiB/sec (Read/Write)\n$FMT$FMT$FMT\n"\
		"Random:" \
		"$(commaize $RAND_READ_BW) / $(commaize $RAND_WRITE_BW)" \
		"Sequential:" \
		"$(commaize $SEQ_READ_BW) / $(commaize $SEQ_WRITE_BW)" \
		"CPU Idleness:" \
		"$CPU_IDLE_PCT_BW%"
	SUMMARY+=$cxt

	printf -v cxt "Latency in ns (Read/Write)\n$FMT$FMT\n"\
		"Random:" \
		"$(commaize $RAND_READ_LAT) / $(commaize $RAND_WRITE_LAT)" \
		"Sequential:" \
		"$(commaize $SEQ_READ_LAT) / $(commaize $SEQ_WRITE_LAT)" \
		"CPU Idleness:" \
		"$CPU_IDLE_PCT_LAT%"
	SUMMARY+=$cxt
else
        printf -v cxt "IOPS (Read/Write)\n$FMT\n" \
                "Random:" \
                "$(commaize $RAND_READ_IOPS) / $(commaize $RAND_WRITE_IOPS)"
        SUMMARY+=$cxt

        printf -v cxt "Bandwidth in KiB/sec (Read/Write)\n$FMT\n"\
                "Sequential:" \
                "$(commaize $SEQ_READ_BW) / $(commaize $SEQ_WRITE_BW)"
        SUMMARY+=$cxt

        printf -v cxt "Latency in ns (Read/Write)\n$FMT\n"\
                "Random:" \
                "$(commaize $RAND_READ_LAT) / $(commaize $RAND_WRITE_LAT)"
        SUMMARY+=$cxt
fi

echo "$SUMMARY" > $RESULT
cat $RESULT
