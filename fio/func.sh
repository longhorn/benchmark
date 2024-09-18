#!/bin/bash

parse_read_iops() {
        local OUTPUT_IOPS=$1
	RAND_READ_IOPS=`cat $OUTPUT_IOPS | jq '.jobs[0].read.iops_mean'| cut -f1 -d.`
        CPU_IDLE_PCT_IOPS=`cat $OUTPUT_IOPS | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_write_iops() {
        local OUTPUT_IOPS=$1
        RAND_WRITE_IOPS=`cat $OUTPUT_IOPS | jq '.jobs[0].write.iops_mean'| cut -f1 -d.`
        CPU_IDLE_PCT_IOPS=`cat $OUTPUT_IOPS | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_read_bw() {
        local OUTPUT_BW=$1
        SEQ_READ_BW=`cat $OUTPUT_BW | jq '.jobs[0].read.bw_mean'| cut -f1 -d.`
        CPU_IDLE_PCT_BW=`cat $OUTPUT_BW| jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_write_bw() {
        local OUTPUT_BW=$1
	SEQ_WRITE_BW=`cat $OUTPUT_BW | jq '.jobs[0].write.bw_mean'| cut -f1 -d.`
        CPU_IDLE_PCT_BW=`cat $OUTPUT_BW| jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_read_lat() {
        local OUTPUT_LAT=$1
	RAND_READ_LAT=`cat $OUTPUT_LAT | jq '.jobs[0].read.lat_ns.mean'| cut -f1 -d.`
        CPU_IDLE_PCT_LAT=`cat $OUTPUT_LAT| jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_write_lat() {
        local OUTPUT_LAT=$1
        RAND_WRITE_LAT=`cat $OUTPUT_LAT | jq '.jobs[0].write.lat_ns.mean'| cut -f1 -d.`
        CPU_IDLE_PCT_LAT=`cat $OUTPUT_LAT| jq '.cpu_idleness.system' | cut -f1 -d.`
}

FMT="%15s%25s\n"
CMP_FMT="%15s%25s%5s%25s%5s%20s\n"

commaize() {
	echo $1 | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

calc_cmp_iops() {
	DELTA_RAND_READ_IOPS=$(($SECOND_RAND_READ_IOPS-$FIRST_RAND_READ_IOPS))
	CMP_RAND_READ_IOPS=`awk "BEGIN {printf \"%.2f\",
		$DELTA_RAND_READ_IOPS*100/$FIRST_RAND_READ_IOPS}"`"%"
	DELTA_RAND_WRITE_IOPS=$(($SECOND_RAND_WRITE_IOPS-$FIRST_RAND_WRITE_IOPS))
	CMP_RAND_WRITE_IOPS=`awk "BEGIN {printf \"%.2f\",
		$DELTA_RAND_WRITE_IOPS*100/$FIRST_RAND_WRITE_IOPS}"`"%"
	CMP_CPU_IDLE_PCT_IOPS=$(($SECOND_CPU_IDLE_PCT_IOPS - $FIRST_CPU_IDLE_PCT_IOPS))
}

calc_cmp_bw() {
	DELTA_SEQ_READ_BW=$(($SECOND_SEQ_READ_BW-$FIRST_SEQ_READ_BW))
	CMP_SEQ_READ_BW=`awk "BEGIN {printf \"%.2f\",
		$DELTA_SEQ_READ_BW*100/$FIRST_SEQ_READ_BW}"`"%"
	DELTA_SEQ_WRITE_BW=$(($SECOND_SEQ_WRITE_BW-$FIRST_SEQ_WRITE_BW))
	CMP_SEQ_WRITE_BW=`awk "BEGIN {printf \"%.2f\",
		$DELTA_SEQ_WRITE_BW*100/$FIRST_SEQ_WRITE_BW}"`"%"
	CMP_CPU_IDLE_PCT_BW=$(($SECOND_CPU_IDLE_PCT_BW - $FIRST_CPU_IDLE_PCT_BW))
}

calc_cmp_lat() {
	DELTA_RAND_READ_LAT=$(($SECOND_RAND_READ_LAT-$FIRST_RAND_READ_LAT))
	CMP_RAND_READ_LAT=`awk "BEGIN {printf \"%.2f\",
		$DELTA_RAND_READ_LAT*100/$FIRST_RAND_READ_LAT}"`"%"
	DELTA_RAND_WRITE_LAT=$(($SECOND_RAND_WRITE_LAT-$FIRST_RAND_WRITE_LAT))
	CMP_RAND_WRITE_LAT=`awk "BEGIN {printf \"%.2f\",
		$DELTA_RAND_WRITE_LAT*100/$FIRST_RAND_WRITE_LAT}"`"%"
	CMP_CPU_IDLE_PCT_LAT=$(($SECOND_CPU_IDLE_PCT_LAT - $FIRST_CPU_IDLE_PCT_LAT))
}
