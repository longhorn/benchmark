package metrics

import (
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"os"
	"path/filepath"
	"strings"

	"github.com/prometheus/client_golang/prometheus"

	"github.com/longhorn/kbench/metric-exporter/registry"
	"github.com/longhorn/kbench/metric-exporter/types"
)

const (
	KbenchName              = "kbench"
	MetricExporterSubsystem = "metric_exporter"

	volumeAccessModeLabel = "volume_access_mode" // rwo or rwx
	testModeLabel         = "test_mode"          // read-only, write-only, or read-write
	rateLimitTypeLabel    = "rate_limit_type"    // rate-limit or no-rate-limit
	ioPatternLabel        = "io_pattern"         // random or sequential
	ioTypeLabel           = "io_type"            // read or write
)

var (
	// used for liveness probe
	opsProcessed = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "myapp_processed_ops_total",
		Help: "The total number of processed events",
	})
)

type metricInfo struct {
	desc       *prometheus.Desc
	metricType prometheus.ValueType
}

type metricCollector struct {
	// Global values. These are set by ENV variables when running the metric exporter
	dataDir          string
	volumeAccessMode string
	testMode         string
	rateLimitType    string

	// metrics
	iopsMetric      metricInfo
	bandwidthMetric metricInfo
	latencyMetric   metricInfo
}

func newMetricCollector(dataDir, volumeAccessMode, testMode, rateLimitType string) *metricCollector {

	mc := &metricCollector{
		dataDir:          dataDir,
		volumeAccessMode: volumeAccessMode,
		testMode:         testMode,
		rateLimitType:    rateLimitType,
	}

	mc.iopsMetric = metricInfo{
		desc: prometheus.NewDesc(
			prometheus.BuildFQName(KbenchName, MetricExporterSubsystem, "iops"),
			"Number of IO operations per second",
			[]string{volumeAccessModeLabel, testModeLabel, rateLimitTypeLabel, ioPatternLabel, ioTypeLabel},
			nil,
		),
		metricType: prometheus.GaugeValue,
	}
	mc.bandwidthMetric = metricInfo{
		desc: prometheus.NewDesc(
			prometheus.BuildFQName(KbenchName, MetricExporterSubsystem, "bandwidth"),
			"Bandwidth in KiB/sec",
			[]string{volumeAccessModeLabel, testModeLabel, rateLimitTypeLabel, ioPatternLabel, ioTypeLabel},
			nil,
		),
		metricType: prometheus.GaugeValue,
	}
	mc.latencyMetric = metricInfo{
		desc: prometheus.NewDesc(
			prometheus.BuildFQName(KbenchName, MetricExporterSubsystem, "latency"),
			"Latency in ns",
			[]string{volumeAccessModeLabel, testModeLabel, rateLimitTypeLabel, ioPatternLabel, ioTypeLabel},
			nil,
		),
		metricType: prometheus.GaugeValue,
	}

	return mc
}

func (mc *metricCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- mc.iopsMetric.desc
}

func (mc *metricCollector) Collect(ch chan<- prometheus.Metric) {
	opsProcessed.Inc()

	fioJobsMap, err := readAllFioJobs(mc.dataDir)
	if err != nil {
		logrus.Errorf("Error during scrape: Failed to readAllFioJobs: %v", err)
		return
	}

	for _, job := range fioJobsMap {
		ioPattern, ioType, jobSuffix, err := parseJobName(job.Jobname)
		if err != nil {
			logrus.Errorf("Error during scrape: %v", err)
			continue
		}

		switch true {
		case jobSuffix == "iops":
			mc.collectIOPsMetric(ch, job, ioPattern, ioType)
		case jobSuffix == "bw":
			mc.collectBandwidthMetric(ch, job, ioPattern, ioType)
		case jobSuffix == "lat":
			mc.collectLatencyMetric(ch, job, ioPattern, ioType)
		default:
			logrus.Errorf("Error during scrape: unknown job: %v", job.Jobname)
		}
	}
}

func InitMetricCollectorSystem(dataDir, volumeAccessMode, testMode, rateLimitType string) {
	registry.Register(opsProcessed)
	metricCollector := newMetricCollector(dataDir, volumeAccessMode, testMode, rateLimitType)
	registry.Register(metricCollector)
}

func readAllFioJobs(dataDir string) (fioJobsMap map[string]*types.FioJob, err error) {
	fioJobsMap = make(map[string]*types.FioJob)
	defer func() {
		err = errors.Wrap(err, "failed to readAllFioJobs")
	}()

	files, err := os.ReadDir(dataDir)
	if err != nil {
		return nil, errors.Wrap(err, "error opening directory")
	}

	for _, file := range files {
		fileName := file.Name()
		filePath := filepath.Join(dataDir, fileName)

		logrus.Debugf("reading %v", fileName)

		jobs, err := readFioJobsFromFile(filePath)
		if err != nil {
			logrus.Errorf("readAllFioJobs: Failed to process file %v: %v", fileName, err)
			continue
		}

		for jobName, job := range jobs {
			fioJobsMap[jobName] = job
		}

	}
	return fioJobsMap, nil
}

func readFioJobsFromFile(filePath string) (fioJobsMap map[string]*types.FioJob, err error) {
	fioJobsMap = make(map[string]*types.FioJob)

	defer func() {
		err = errors.Wrap(err, "failed to readFioJobsFromFile")
	}()

	f, err := os.Open(filePath)
	if err != nil {
		return nil, errors.Wrap(err, "error opening file")
	}
	defer f.Close()

	var fioReport types.FioReport
	decoder := json.NewDecoder(f)
	if err = decoder.Decode(&fioReport); err != nil {
		return nil, errors.Wrap(err, "error decoding JSON")
	}

	for i := range fioReport.Jobs {
		fioJobsMap[fioReport.Jobs[i].Jobname] = &fioReport.Jobs[i]
	}

	return fioJobsMap, nil
}

func parseJobName(jobName string) (ioPattern, ioType, jobSuffix string, err error) {
	defer func() {
		err = errors.Wrap(err, "failed to parseJobName")
	}()

	strs := strings.Split(jobName, "-")
	if len(strs) != 3 {
		return "", "", "", fmt.Errorf("invalid job Name %v: must have format xxx-yyy-zzz", jobName)
	}

	if strs[0] == "seq" {
		ioPattern = types.IOPatternSequential
	} else if strs[0] == "rand" {
		ioPattern = types.IOPatternRandom
	} else {
		return "", "", "", fmt.Errorf("unknown ioPattern in job name: %v", jobName)
	}

	if strs[1] == "read" {
		ioType = types.IOTypeRead
	} else if strs[1] == "write" {
		ioType = types.IOTypeWrite
	} else {
		return "", "", "", fmt.Errorf("unknown ioType in job name: %v", jobName)
	}

	jobSuffix = strs[2]

	return ioPattern, ioType, jobSuffix, nil

}

func (mc *metricCollector) collectIOPsMetric(ch chan<- prometheus.Metric, job *types.FioJob, ioPattern, ioType string) {
	var value float64
	if ioType == types.IOTypeRead {
		value = job.Read.IopsMean
	} else {
		value = job.Write.IopsMean
	}

	ch <- prometheus.MustNewConstMetric(mc.iopsMetric.desc, mc.iopsMetric.metricType, value, mc.volumeAccessMode, mc.testMode, mc.rateLimitType, ioPattern, ioType)
	return
}

func (mc *metricCollector) collectBandwidthMetric(ch chan<- prometheus.Metric, job *types.FioJob, ioPattern, ioType string) {
	var value float64
	if ioType == types.IOTypeRead {
		value = job.Read.BwMean
	} else {
		value = job.Write.BwMean
	}

	ch <- prometheus.MustNewConstMetric(mc.bandwidthMetric.desc, mc.bandwidthMetric.metricType, value, mc.volumeAccessMode, mc.testMode, mc.rateLimitType, ioPattern, ioType)
	return
}

func (mc *metricCollector) collectLatencyMetric(ch chan<- prometheus.Metric, job *types.FioJob, ioPattern, ioType string) {
	var value float64

	if ioType == types.IOTypeRead {
		value = job.Read.LatNs.Mean
	} else {
		value = job.Write.LatNs.Mean
	}

	ch <- prometheus.MustNewConstMetric(mc.latencyMetric.desc, mc.latencyMetric.metricType, value, mc.volumeAccessMode, mc.testMode, mc.rateLimitType, ioPattern, ioType)
	return
}
