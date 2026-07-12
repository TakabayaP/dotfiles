package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"
)

const (
	vid = "3434"
	pid = "0440"

	busUSB = 0x03

	evSyn = 0x00
	evKey = 0x01
	evRel = 0x02

	synReport = 0x00

	relX            = 0x00
	relY            = 0x01
	relHWheel       = 0x06
	relWheel        = 0x08
	relWheelHiRes   = 0x0b
	relHWheelHiRes  = 0x0c
	btnLeft         = 0x110
	btnRight        = 0x111
	btnMiddle       = 0x112
	btnSide         = 0x113
	btnExtra        = 0x114
	uiDevCreate     = 0x5501
	uiDevDestroy    = 0x5502
	uiSetEvBit      = 0x40045564
	uiSetKeyBit     = 0x40045565
	uiSetRelBit     = 0x40045566
	inputEventSize  = int(unsafe.Sizeof(inputEvent{}))
	uinputUserBytes = 80 + 8 + 4 + 4*256
)

type buttonMapping struct {
	mask byte
	code uint16
}

var buttons = []buttonMapping{
	{0x01, btnLeft},
	{0x02, btnRight},
	{0x04, btnMiddle},
	{0x08, btnSide},
	{0x10, btnExtra},
}

var errStopped = errors.New("stopped")

type inputEvent struct {
	Sec   int64
	Usec  int64
	Type  uint16
	Code  uint16
	Value int32
}

type mouseReport struct {
	source string
	mask   byte
	x      int16
	y      int16
	wheel  int16
	hwheel int16
}

func main() {
	debug := flag.Bool("debug", false, "print report counters once per second")
	invertScroll := flag.Bool("invert-scroll", false, "invert vertical and horizontal scroll direction")
	flag.Parse()

	if err := run(*debug, *invertScroll); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(debug bool, invertScroll bool) error {
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(stop)

	for {
		hidraws, err := findHidraws()
		if err != nil {
			fmt.Fprintf(os.Stderr, "%v; waiting for Nape Pro\n", err)
			if waitOrStop(stop, 2*time.Second) {
				return nil
			}
			continue
		}
		if len(hidraws) == 0 {
			if debug {
				fmt.Println("Nape Pro hidraw devices not found; waiting")
			}
			if waitOrStop(stop, 2*time.Second) {
				return nil
			}
			continue
		}

		err = runConnected(hidraws, debug, invertScroll, stop)
		if errors.Is(err, errStopped) {
			return nil
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "%v; waiting for Nape Pro reconnect\n", err)
		}
		if waitOrStop(stop, time.Second) {
			return nil
		}
	}
}

func runConnected(hidraws []string, debug bool, invertScroll bool, stop <-chan os.Signal) error {
	fmt.Println("Reading hidraw devices:")
	for _, path := range hidraws {
		fmt.Printf("  %s\n", path)
	}
	fmt.Println("Creating virtual mouse: Nape Pro userspace mouse")

	uinput, err := createUinput()
	if err != nil {
		return err
	}
	defer func() {
		_, _ = ioctl(uinput.Fd(), uiDevDestroy, 0)
		_ = uinput.Close()
	}()

	reports := make(chan mouseReport, 512)
	done := make(chan struct{})
	var wg sync.WaitGroup
	var totalReports uint64
	counts := make(map[string]*uint64, len(hidraws))

	for _, path := range hidraws {
		var n uint64
		counts[filepath.Base(path)] = &n
		wg.Add(1)
		go func(path string, count *uint64) {
			defer wg.Done()
			readHidraw(path, reports, done, &totalReports, count)
		}(path, &n)
	}

	go func() {
		wg.Wait()
		close(reports)
	}()

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	var prevButtons byte
	var emitted uint64
	var last mouseReport
	var haveLast bool

	for {
		select {
		case <-stop:
			close(done)
			return errStopped
		case report, ok := <-reports:
			if !ok {
				return errors.New("all hidraw readers stopped")
			}
			last = report
			haveLast = true
			if invertScroll {
				report.wheel = -report.wheel
				report.hwheel = -report.hwheel
			}
			changed, err := emitReport(uinput, prevButtons, report)
			if err != nil {
				close(done)
				return err
			}
			if changed {
				emitted++
			}
			prevButtons = report.mask
		case <-ticker.C:
			if debug {
				printDebug(totalReports, emitted, counts, last, haveLast)
			}
		}
	}
}

func waitOrStop(stop <-chan os.Signal, duration time.Duration) bool {
	timer := time.NewTimer(duration)
	defer timer.Stop()

	select {
	case <-stop:
		return true
	case <-timer.C:
		return false
	}
}

func findHidraws() ([]string, error) {
	paths := map[string]struct{}{}

	byID, _ := filepath.Glob("/dev/input/by-id/*Nape*hidraw")
	for _, path := range byID {
		resolved, err := filepath.EvalSymlinks(path)
		if err == nil {
			paths[resolved] = struct{}{}
		}
	}

	entries, err := os.ReadDir("/sys/class/hidraw")
	if err == nil {
		for _, entry := range entries {
			sysdev, err := filepath.EvalSymlinks(filepath.Join("/sys/class/hidraw", entry.Name(), "device"))
			if err != nil {
				continue
			}
			modaliasBytes, err := os.ReadFile(filepath.Join(sysdev, "modalias"))
			if err != nil {
				continue
			}
			modalias := strings.ToLower(string(modaliasBytes))
			if strings.Contains(modalias, "v0000"+vid) && strings.Contains(modalias, "p0000"+pid) {
				paths[filepath.Join("/dev", entry.Name())] = struct{}{}
			}
		}
	}

	out := make([]string, 0, len(paths))
	for path := range paths {
		out = append(out, path)
	}
	sort.Strings(out)
	return out, nil
}

func readHidraw(path string, reports chan<- mouseReport, done <-chan struct{}, total *uint64, count *uint64) {
	file, err := os.OpenFile(path, os.O_RDONLY|syscall.O_NONBLOCK, 0)
	if err != nil {
		fmt.Fprintf(os.Stderr, "open %s: %v\n", path, err)
		return
	}
	defer file.Close()

	buf := make([]byte, 64)
	for {
		select {
		case <-done:
			return
		default:
		}

		n, err := file.Read(buf)
		if err != nil {
			if errors.Is(err, syscall.EAGAIN) {
				time.Sleep(time.Millisecond)
				continue
			}
			if errors.Is(err, io.EOF) {
				time.Sleep(time.Millisecond)
				continue
			}
			fmt.Fprintf(os.Stderr, "read %s: %v\n", path, err)
			return
		}
		if n < 10 || buf[0] != 0x03 {
			continue
		}

		atomic.AddUint64(total, 1)
		atomic.AddUint64(count, 1)

		report := mouseReport{
			source: filepath.Base(path),
			mask:   buf[1],
			x:      int16(binary.LittleEndian.Uint16(buf[2:4])),
			y:      int16(binary.LittleEndian.Uint16(buf[4:6])),
			wheel:  int16(binary.LittleEndian.Uint16(buf[6:8])),
			hwheel: int16(binary.LittleEndian.Uint16(buf[8:10])),
		}

		select {
		case reports <- report:
		case <-done:
			return
		}
	}
}

func createUinput() (*os.File, error) {
	file, err := os.OpenFile("/dev/uinput", os.O_WRONLY|syscall.O_NONBLOCK, 0)
	if err != nil {
		return nil, err
	}

	closeOnErr := true
	defer func() {
		if closeOnErr {
			_ = file.Close()
		}
	}()

	for _, ev := range []uint16{evKey, evRel} {
		if _, err := ioctl(file.Fd(), uiSetEvBit, uintptr(ev)); err != nil {
			return nil, err
		}
	}
	for _, button := range buttons {
		if _, err := ioctl(file.Fd(), uiSetKeyBit, uintptr(button.code)); err != nil {
			return nil, err
		}
	}
	for _, rel := range []uint16{relX, relY, relWheel, relHWheel, relWheelHiRes, relHWheelHiRes} {
		if _, err := ioctl(file.Fd(), uiSetRelBit, uintptr(rel)); err != nil {
			return nil, err
		}
	}

	uidev := make([]byte, uinputUserBytes)
	copy(uidev[0:80], []byte("Nape Pro userspace mouse"))
	binary.LittleEndian.PutUint16(uidev[80:82], busUSB)
	binary.LittleEndian.PutUint16(uidev[82:84], 0x3434)
	binary.LittleEndian.PutUint16(uidev[84:86], 0x0440)
	binary.LittleEndian.PutUint16(uidev[86:88], 0x0111)

	if _, err := file.Write(uidev); err != nil {
		return nil, err
	}
	if _, err := ioctl(file.Fd(), uiDevCreate, 0); err != nil {
		return nil, err
	}

	time.Sleep(200 * time.Millisecond)
	closeOnErr = false
	return file, nil
}

func emitReport(file *os.File, prevButtons byte, report mouseReport) (bool, error) {
	changed := false
	for _, button := range buttons {
		oldValue := int32(0)
		if prevButtons&button.mask != 0 {
			oldValue = 1
		}
		newValue := int32(0)
		if report.mask&button.mask != 0 {
			newValue = 1
		}
		if oldValue != newValue {
			if err := emit(file, evKey, button.code, newValue); err != nil {
				return false, err
			}
			changed = true
		}
	}

	if report.x != 0 {
		if err := emit(file, evRel, relX, int32(report.x)); err != nil {
			return false, err
		}
		changed = true
	}
	if report.y != 0 {
		if err := emit(file, evRel, relY, int32(report.y)); err != nil {
			return false, err
		}
		changed = true
	}
	if report.wheel != 0 {
		if err := emit(file, evRel, relWheel, int32(report.wheel)); err != nil {
			return false, err
		}
		if err := emit(file, evRel, relWheelHiRes, int32(report.wheel)*120); err != nil {
			return false, err
		}
		changed = true
	}
	if report.hwheel != 0 {
		if err := emit(file, evRel, relHWheel, int32(report.hwheel)); err != nil {
			return false, err
		}
		if err := emit(file, evRel, relHWheelHiRes, int32(report.hwheel)*120); err != nil {
			return false, err
		}
		changed = true
	}

	if changed {
		if err := emit(file, evSyn, synReport, 0); err != nil {
			return false, err
		}
	}
	return changed, nil
}

func emit(file *os.File, eventType uint16, code uint16, value int32) error {
	now := time.Now()
	event := inputEvent{
		Sec:   now.Unix(),
		Usec:  int64(now.Nanosecond() / 1000),
		Type:  eventType,
		Code:  code,
		Value: value,
	}

	buf := make([]byte, inputEventSize)
	binary.LittleEndian.PutUint64(buf[0:8], uint64(event.Sec))
	binary.LittleEndian.PutUint64(buf[8:16], uint64(event.Usec))
	binary.LittleEndian.PutUint16(buf[16:18], event.Type)
	binary.LittleEndian.PutUint16(buf[18:20], event.Code)
	binary.LittleEndian.PutUint32(buf[20:24], uint32(event.Value))

	_, err := file.Write(buf)
	return err
}

func ioctl(fd uintptr, request uintptr, arg uintptr) (uintptr, error) {
	ret, _, errno := syscall.Syscall(syscall.SYS_IOCTL, fd, request, arg)
	if errno != 0 {
		return ret, errno
	}
	return ret, nil
}

func printDebug(total uint64, emitted uint64, counts map[string]*uint64, last mouseReport, haveLast bool) {
	names := make([]string, 0, len(counts))
	for name := range counts {
		names = append(names, name)
	}
	sort.Strings(names)

	parts := make([]string, 0, len(names))
	for _, name := range names {
		parts = append(parts, fmt.Sprintf("%s:%d", name, atomic.LoadUint64(counts[name])))
	}

	if haveLast {
		fmt.Printf(
			"reports=%d emitted=%d by_fd=[%s] last=%s buttons=0x%02x x=%d y=%d wheel=%d hwheel=%d\n",
			atomic.LoadUint64(&total),
			emitted,
			strings.Join(parts, " "),
			last.source,
			last.mask,
			last.x,
			last.y,
			last.wheel,
			last.hwheel,
		)
		return
	}

	fmt.Printf(
		"reports=%d emitted=%d by_fd=[%s]\n",
		atomic.LoadUint64(&total),
		emitted,
		strings.Join(parts, " "),
	)
}
