/*
Source: https://github.com/tobealive/bartender
License: MIT

Library structure (until improved module structure is implemented, the directory structure is flat
- awaited feature: https://discord.com/channels/592103645835821068/592294828432424960/1096096129990533181)
Intended structure:
bartender
├── src
│   ├── examples
│   │   ├── simple.v
│   │   └── <..>.v
│   ├── instructions
│   │   ├── affixations.v
│   │   ├── base.v
│   │   ├── colors.v
│   │   ├── reader.v
│   │   ├── simple.v
│   │   ├── simple_multi.v
│   │   ├── smooth.v
│   │   ├── smooth_multi.v
│   │   └── spinner.v
│   └── state
│   │   ├── affixations.v
│   │   ├── base.v
│   │   ├── colors.v
│   │   ├── simple.v
│   │   └── smooth.v
│   └── tests
│   │   ├── simple_test.v
│   │   └── smooth_test.v
│   ├── errors.v
│   └── lib.v
├── LICENSE
├── README.md
└── v.mod
*/

module bartender

import sync
import term
import os
import io

// == Bar =====================================================================

// Progresses the bar to its next position.
pub fn (mut b Bar) progress() {
	b.progress_()
}

// Colorizes the specified parts of the bar.
pub fn (mut b Bar) colorize(color BarColorType) {
	b.colorize_(color)
}

// Returns the bar's percentage of completion.
pub fn (b Bar) pct() u16 {
	return b.pct_()
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b Bar) eta(delay u8) string {
	return b.eta_(delay)
}

// Returns a snapshot of a spinner based on the bar's current position.
pub fn (b Bar) spinner() string {
	return b.spinner_()
}

// Resets the bar to its initial state.
pub fn (mut b Bar) reset() {
	b.reset_()
}

// Returns a `io.BufferedReader` that displays a progressing bar when used in a reader operation.
pub fn (mut b Bar) bar_reader(bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

// Monitors the progress of multiple bars until all of them are finished.
pub fn (bars []&Bar) watch(mut wg sync.WaitGroup) {
	bars.watch_(mut wg)
}

// == SmoothBar ===============================================================

// Progresses the bar to its next position.
pub fn (mut b SmoothBar) progress() {
	b.progress_()
}

// Colorizes the specified parts of the bar.
pub fn (mut b SmoothBar) colorize(color Color) {
	b.colorize_(color)
}

// Returns the bar's percentage of completion.
pub fn (b SmoothBar) pct() u16 {
	return b.pct()
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b SmoothBar) eta(delay u8) string {
	return b.eta(delay)
}

// Returns a snapshot of a spinner based on the bar's current position.
pub fn (b SmoothBar) spinner() string {
	return b.spinner_()
}

// Resets the bar to its initial state.
pub fn (mut b SmoothBar) reset() {
	b.setup()
}

// Returns a `io.BufferedReader` that displays a progressing bar when used in a reader operation.
pub fn (mut b SmoothBar) bar_reader(bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

// Monitors the progress of multiple bars until all of them are finished.
pub fn (bars []&SmoothBar) watch(mut wg sync.WaitGroup) {
	bars.watch_(mut wg)
}

// == Misc ====================================================================

pub fn bar_reader(b BarType, bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

// Returns the bar's current position.
pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

fn handle_interrupt(signal os.Signal) {
	term.show_cursor()
	exit(0)
}
