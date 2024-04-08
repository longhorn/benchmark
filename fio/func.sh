#!/bin/bash

# IOPS
parse_seqread_iops() {
    local OUTPUT=${1}
    SEQREAD_IOPS=`cat $OUTPUT | jq '.jobs[0].read.iops_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQREAD_IOPS=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_seqwrite_iops() {
    local OUTPUT=${1}
    SEQWRITE_IOPS=`cat $OUTPUT | jq '.jobs[0].write.iops_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQWRITE_IOPS=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randread_iops() {
    local OUTPUT=${1}
    RANDREAD_IOPS=`cat $OUTPUT | jq '.jobs[0].read.iops_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDREAD_IOPS=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randwrite_iops() {
    local OUTPUT=${1}
    RANDWRITE_IOPS=`cat $OUTPUT | jq '.jobs[0].write.iops_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDWRITE_IOPS=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

# Bandwidth
parse_seqread_bandwidth() {
    local OUTPUT=${1}
    SEQREAD_BANDWIDTH=`cat $OUTPUT | jq '.jobs[0].read.bw_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQREAD_BANDWIDTH=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_seqwrite_bandwidth() {
    local OUTPUT=${1}
    SEQWRITE_BANDWIDTH=`cat $OUTPUT | jq '.jobs[0].write.bw_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQWRITE_BANDWIDTH=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randread_bandwidth() {
    local OUTPUT=${1}
    RANDREAD_BANDWIDTH=`cat $OUTPUT | jq '.jobs[0].read.bw_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDREAD_BANDWIDTH=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randwrite_bandwidth() {
    local OUTPUT=${1}
    RANDWRITE_BANDWIDTH=`cat $OUTPUT | jq '.jobs[0].write.bw_mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDWRITE_BANDWIDTH=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

# Latency
parse_seqread_latency() {
    local OUTPUT=${1}
    SEQREAD_LATENCY=`cat $OUTPUT | jq '.jobs[0].read.lat_ns.mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQREAD_LATENCY=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_seqwrite_latency() {
    local OUTPUT=${1}
    SEQWRITE_LATENCY=`cat $OUTPUT | jq '.jobs[0].write.lat_ns.mean'| cut -f1 -d.`
    CPU_IDLE_PCT_SEQWRITE_LATENCY=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randread_latency() {
    local OUTPUT=${1}
    RANDREAD_LATENCY=`cat $OUTPUT | jq '.jobs[0].read.lat_ns.mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDREAD_LATENCY=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

parse_randwrite_latency() {
    local OUTPUT=${1}
    RANDWRITE_LATENCY=`cat $OUTPUT | jq '.jobs[0].write.lat_ns.mean'| cut -f1 -d.`
    CPU_IDLE_PCT_RANDWRITE_LATENCY=`cat $OUTPUT | jq '.cpu_idleness.system' | cut -f1 -d.`
}

# Latency 99th percentile
parse_seqread_latency_p99() {
    local OUTPUT=${1}
    SEQREAD_LATENCY=`cat $OUTPUT | jq '.jobs[0].read.clat_ns.percentile["99.000000"]'| cut -f1 -d.`
}

parse_seqwrite_latency_p99() {
    local OUTPUT=${1}
    SEQWRITE_LATENCY=`cat $OUTPUT | jq '.jobs[0].write.clat_ns.percentile["99.000000"]'| cut -f1 -d.`
}

parse_randread_latency_p99() {
    local OUTPUT=${1}
    RANDREAD_LATENCY=`cat $OUTPUT | jq '.jobs[0].read.clat_ns.percentile["99.000000"]'| cut -f1 -d.`
}

parse_randwrite_latency_p99() {
    local OUTPUT=${1}
    RANDWRITE_LATENCY=`cat $OUTPUT | jq '.jobs[0].write.clat_ns.percentile["99.000000"]'| cut -f1 -d.`
}


FMT="%30s%30s\n"
CMP_FMT="%20s%30s%10s%30s%10s%25s\n"

commaize() {
    echo $1 | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

calc_cmp_iops() {
    DELTA_RANDREAD_IOPS=$((${SECOND_RANDREAD_IOPS:-0}-${FIRST_RANDREAD_IOPS:-0}))
    CMP_RANDREAD_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDREAD_IOPS:-0}*100/${FIRST_RANDREAD_IOPS:-0}}"`"%"
    DELTA_RANDWRITE_IOPS=$((${SECOND_RANDWRITE_IOPS:-0}-${FIRST_RANDWRITE_IOPS:-0}))
    CMP_RANDWRITE_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDWRITE_IOPS:-0}*100/${FIRST_RANDWRITE_IOPS:-0}}"`"%"
    DELTA_SEQREAD_IOPS=$((${SECOND_SEQREAD_IOPS:-0}-${FIRST_SEQREAD_IOPS:-0}))
    CMP_SEQREAD_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQREAD_IOPS:-0}*100/${FIRST_SEQREAD_IOPS:-0}}"`"%"
    DELTA_SEQWRITE_IOPS=$((${SECOND_SEQWRITE_IOPS:-0}-${FIRST_SEQWRITE_IOPS:-0}))
    CMP_SEQWRITE_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQWRITE_IOPS:-0}*100/${FIRST_SEQWRITE_IOPS:-0}}"`"%"

    DELTA_CPU_IDLE_PCT_RANDREAD_IOPS=$((${SECOND_CPU_IDLE_PCT_RANDREAD_IOPS:-0}-${FIRST_CPU_IDLE_PCT_RANDREAD_IOPS:-0}))
    CMP_CPU_IDLE_PCT_RANDREAD_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDREAD_IOPS:-0}*100/${FIRST_CPU_IDLE_PCT_RANDREAD_IOPS:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_RANDWRITE_IOPS=$((${SECOND_CPU_IDLE_PCT_RANDWRITE_IOPS:-0}-${FIRST_CPU_IDLE_PCT_RANDWRITE_IOPS:-0}))
    CMP_CPU_IDLE_PCT_RANDWRITE_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDWRITE_IOPS:-0}*100/${FIRST_CPU_IDLE_PCT_RANDWRITE_IOPS:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQREAD_IOPS=$((${SECOND_CPU_IDLE_PCT_SEQREAD_IOPS:-0}-${FIRST_CPU_IDLE_PCT_SEQREAD_IOPS:-0}))
    CMP_CPU_IDLE_PCT_SEQREAD_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQREAD_IOPS:-0}*100/${FIRST_CPU_IDLE_PCT_SEQREAD_IOPS:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQWRITE_IOPS=$((${SECOND_CPU_IDLE_PCT_SEQWRITE_IOPS:-0}-${FIRST_CPU_IDLE_PCT_SEQWRITE_IOPS:-0}))
    CMP_CPU_IDLE_PCT_SEQWRITE_IOPS=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQWRITE_IOPS:-0}*100/${FIRST_CPU_IDLE_PCT_SEQWRITE_IOPS:-0}}"`"%"
}

calc_cmp_bandwidth() {
    DELTA_RANDREAD_BANDWIDTH=$((${SECOND_RANDREAD_BANDWIDTH:-0}-${FIRST_RANDREAD_BANDWIDTH:-0}))
    CMP_RANDREAD_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDREAD_BANDWIDTH:-0}*100/${FIRST_RANDREAD_BANDWIDTH:-0}}"`"%"
    DELTA_RANDWRITE_BANDWIDTH=$((${SECOND_RANDWRITE_BANDWIDTH:-0}-${FIRST_RANDWRITE_BANDWIDTH:-0}))
    CMP_RANDWRITE_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDWRITE_BANDWIDTH:-0}*100/${FIRST_RANDWRITE_BANDWIDTH:-0}}"`"%"
    DELTA_SEQREAD_BANDWIDTH=$((${SECOND_SEQREAD_BANDWIDTH:-0}-${FIRST_SEQREAD_BANDWIDTH:-0}))
    CMP_SEQREAD_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQREAD_BANDWIDTH:-0}*100/${FIRST_SEQREAD_BANDWIDTH:-0}}"`"%"
    DELTA_SEQWRITE_BANDWIDTH=$((${SECOND_SEQWRITE_BANDWIDTH:-0}-${FIRST_SEQWRITE_BANDWIDTH:-0}))
    CMP_SEQWRITE_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQWRITE_BANDWIDTH:-0}*100/${FIRST_SEQWRITE_BANDWIDTH:-0}}"`"%"

    DELTA_CPU_IDLE_PCT_RANDREAD_BANDWIDTH=$((${SECOND_CPU_IDLE_PCT_RANDREAD_BANDWIDTH:-0}-${FIRST_CPU_IDLE_PCT_RANDREAD_BANDWIDTH:-0}))
    CMP_CPU_IDLE_PCT_RANDREAD_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDREAD_BANDWIDTH:-0}*100/${FIRST_CPU_IDLE_PCT_RANDREAD_BANDWIDTH:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH=$((${SECOND_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH:-0}-${FIRST_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH:-0}))
    CMP_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH:-0}*100/${FIRST_CPU_IDLE_PCT_RANDWRITE_BANDWIDTH:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQREAD_BANDWIDTH=$((${SECOND_CPU_IDLE_PCT_SEQREAD_BANDWIDTH:-0}-${FIRST_CPU_IDLE_PCT_SEQREAD_BANDWIDTH:-0}))
    CMP_CPU_IDLE_PCT_SEQREAD_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQREAD_BANDWIDTH:-0}*100/${FIRST_CPU_IDLE_PCT_SEQREAD_BANDWIDTH:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH=$((${SECOND_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH:-0}-${FIRST_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH:-0}))
    CMP_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH:-0}*100/${FIRST_CPU_IDLE_PCT_SEQWRITE_BANDWIDTH:-0}}"`"%"
}

calc_cmp_latency() {
    DELTA_RANDREAD_LATENCY=$((${SECOND_RANDREAD_LATENCY:-0}-${FIRST_RANDREAD_LATENCY:-0}))
    CMP_RANDREAD_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDREAD_LATENCY:-0}*100/${FIRST_RANDREAD_LATENCY:-0}}"`"%"
    DELTA_RANDWRITE_LATENCY=$((${SECOND_RANDWRITE_LATENCY:-0}-${FIRST_RANDWRITE_LATENCY:-0}))
    CMP_RANDWRITE_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_RANDWRITE_LATENCY:-0}*100/${FIRST_RANDWRITE_LATENCY:-0}}"`"%"
    DELTA_SEQREAD_LATENCY=$((${SECOND_SEQREAD_LATENCY:-0}-${FIRST_SEQREAD_LATENCY:-0}))
    CMP_SEQREAD_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQREAD_LATENCY:-0}*100/${FIRST_SEQREAD_LATENCY:-0}}"`"%"
    DELTA_SEQWRITE_LATENCY=$((${SECOND_SEQWRITE_LATENCY:-0}-${FIRST_SEQWRITE_LATENCY:-0}))
    CMP_SEQWRITE_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_SEQWRITE_LATENCY:-0}*100/${FIRST_SEQWRITE_LATENCY:-0}}"`"%"

    DELTA_CPU_IDLE_PCT_RANDREAD_LATENCY=$((${SECOND_CPU_IDLE_PCT_RANDREAD_LATENCY:-0}-${FIRST_CPU_IDLE_PCT_RANDREAD_LATENCY:-0}))
    CMP_CPU_IDLE_PCT_RANDREAD_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDREAD_LATENCY:-0}*100/${FIRST_CPU_IDLE_PCT_RANDREAD_LATENCY:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_RANDWRITE_LATENCY=$((${SECOND_CPU_IDLE_PCT_RANDWRITE_LATENCY:-0}-${FIRST_CPU_IDLE_PCT_RANDWRITE_LATENCY:-0}))
    CMP_CPU_IDLE_PCT_RANDWRITE_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_RANDWRITE_LATENCY:-0}*100/${FIRST_CPU_IDLE_PCT_RANDWRITE_LATENCY:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQREAD_LATENCY=$((${SECOND_CPU_IDLE_PCT_SEQREAD_LATENCY:-0}-${FIRST_CPU_IDLE_PCT_SEQREAD_LATENCY:-0}))
    CMP_CPU_IDLE_PCT_SEQREAD_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQREAD_LATENCY:-0}*100/${FIRST_CPU_IDLE_PCT_SEQREAD_LATENCY:-0}}"`"%"
    DELTA_CPU_IDLE_PCT_SEQWRITE_LATENCY=$((${SECOND_CPU_IDLE_PCT_SEQWRITE_LATENCY:-0}-${FIRST_CPU_IDLE_PCT_SEQWRITE_LATENCY:-0}))
    CMP_CPU_IDLE_PCT_SEQWRITE_LATENCY=`awk "BEGIN {printf \"%.2f\",
        ${DELTA_CPU_IDLE_PCT_SEQWRITE_LATENCY:-0}*100/${FIRST_CPU_IDLE_PCT_SEQWRITE_LATENCY:-0}}"`"%"
}
