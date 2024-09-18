FROM registry.suse.com/bci/bci-base:15.6

RUN zypper -n ref && zypper update -y


RUN zypper -n addrepo --refresh https://download.opensuse.org/repositories/benchmark/SLE_15_SP5/benchmark.repo && \
    zypper --gpg-auto-import-keys ref

RUN zypper -n install jq fio procps awk

ADD ./fio/ /fio/
ADD ./bin/metric-exporter /usr/local/sbin/
WORKDIR "/fio/"
ENTRYPOINT ["bash", "/fio/run.sh"]
