package main

import (
	"fmt"
	"github.com/longhorn/kbench/metric-exporter/types"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/sirupsen/logrus"
	"github.com/urfave/cli"

	"github.com/longhorn/kbench/metric-exporter/metrics"
	"github.com/longhorn/kbench/metric-exporter/registry"
)

const (
	FlagDataDir          = "data-dir"
	EnvDataDir           = "DATA_DIR"
	FlagVolumeAccessMode = "volume-access-mode"
	EnvVolumeAccessMode  = "VOLUME_ACCESS_MODE"
	FlagTestMode         = "test-mode"
	EnvTestMode          = "TEST_MODE"
	FlagRateLimitType    = "rate-limit-type"
	EnvRateLimitType     = "RATE_LIMIT_TYPE"
	FlagPort             = "port"
	EnvPort              = "PORT"

	VERSION = "v0.0.0-dev"
)

func main() {
	app := cli.NewApp()
	app.Name = "metric-exporter"
	app.Version = VERSION
	app.Flags = []cli.Flag{
		cli.BoolFlag{
			Name:   "debug, d",
			Usage:  "enable debug logging level",
			EnvVar: "DEBUG",
		},
	}
	app.Before = func(c *cli.Context) error {
		if c.GlobalBool("debug") {
			logrus.SetLevel(logrus.DebugLevel)
		}
		return nil
	}

	app.Commands = []cli.Command{
		MetricExporterCmd(),
	}

	if err := app.Run(os.Args); err != nil {
		logrus.Fatal(err)
	}
}

func MetricExporterCmd() cli.Command {
	return cli.Command{
		Name: "start",
		Flags: []cli.Flag{
			cli.StringFlag{
				Name:   FlagDataDir,
				EnvVar: EnvDataDir,
				Value:  "/test-result",
				Usage:  "Specify the location of the data directory",
			},
			cli.StringFlag{
				Name:   FlagVolumeAccessMode,
				EnvVar: EnvVolumeAccessMode,
				Value:  types.VolumeAccessModeRWO,
				Usage:  fmt.Sprintf("Specify the volume access mode: [%v, %v]", types.VolumeAccessModeRWO, types.VolumeAccessModeRWX),
			},
			cli.StringFlag{
				Name:   FlagTestMode,
				EnvVar: EnvTestMode,
				Value:  types.TestModeReadWrite,
				Usage:  fmt.Sprintf("Specify the test mode: [%v, %v, %v]", types.TestModeReadWrite, types.TestModeReadOnly, types.TestModeWriteOnly),
			},
			cli.StringFlag{
				Name:   FlagRateLimitType,
				EnvVar: EnvRateLimitType,
				Value:  types.RateLimitTypeNoRateLimit,
				Usage:  fmt.Sprintf("Specify the test mode: [%v, %v]", types.RateLimitTypeNoRateLimit, types.RateLimitTypeRateLimit),
			},
			cli.IntFlag{
				Name:   FlagPort,
				EnvVar: EnvPort,
				Value:  8080,
				Usage:  "Specify the port number",
			},
		},
		Action: func(c *cli.Context) error {
			return startMetricExporter(c)
		},
	}
}

func startMetricExporter(c *cli.Context) error {
	if err := validateCommandLineArguments(c); err != nil {
		return err
	}

	dataDir := c.String(FlagDataDir)
	volumeAccessMode := c.String(FlagVolumeAccessMode)
	testMode := c.String(FlagTestMode)
	rateLimitType := c.String(FlagRateLimitType)
	port := c.Int(FlagPort)

	done := make(chan struct{})

	metrics.InitMetricCollectorSystem(dataDir, volumeAccessMode, testMode, rateLimitType)

	listeningAddress := fmt.Sprintf(":%v", port)
	http.Handle("/metrics", registry.Handler())
	go func() {
		logrus.Infof("Metric exporter is listening at %v", listeningAddress)
		// always returns error. ErrServerClosed on graceful close
		if err := http.ListenAndServe(listeningAddress, nil); err != http.ErrServerClosed {
			logrus.Fatalf("%v", err)
		}
	}()

	RegisterShutdownChannel(done)
	<-done
	return nil
}

func validateCommandLineArguments(c *cli.Context) error {
	volumeAccessMode := c.String(FlagVolumeAccessMode)
	if volumeAccessMode != types.VolumeAccessModeRWO &&
		volumeAccessMode != types.VolumeAccessModeRWX {
		return fmt.Errorf("invalid volume-access-mode %v. Valid values are [%v, %v]", volumeAccessMode, types.VolumeAccessModeRWO, types.VolumeAccessModeRWX)
	}

	testMode := c.String(FlagTestMode)
	if testMode != types.TestModeReadWrite &&
		testMode != types.TestModeReadOnly &&
		testMode != types.TestModeWriteOnly {
		return fmt.Errorf("invalid test-mode %v. Valid values are [%v, %v, %v]", testMode, types.TestModeReadWrite, types.TestModeReadOnly, types.TestModeWriteOnly)

	}
	rateLimitType := c.String(FlagRateLimitType)
	if rateLimitType != types.RateLimitTypeNoRateLimit &&
		rateLimitType != types.RateLimitTypeRateLimit {
		return fmt.Errorf("invalid rate-limit-type %v. Valid values are [%v, %v]", rateLimitType, types.RateLimitTypeNoRateLimit, types.RateLimitTypeRateLimit)

	}

	return nil
}

func RegisterShutdownChannel(done chan struct{}) {
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigs
		logrus.Infof("Receive %v to exit", sig)
		close(done)
	}()
}
