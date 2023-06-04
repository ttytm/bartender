// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import sync
import term
import os
import io

// == Bar =====================================================================

pub fn (mut b Bar) progress() {
	b.progress_()
}

pub fn (mut b Bar) colorize(color BarColorType) {
	b.colorize_(color)
}

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

pub fn (b Bar) spinner() string {
	return b.spinner_()
}

pub fn (mut b Bar) reset() {
	b.reset_()
}

pub fn (mut b Bar) bar_reader(bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

pub fn (bars []&Bar) watch(mut wg sync.WaitGroup) {
	bars.watch_(mut wg)
}

// == SmoothBar ===============================================================

pub fn (mut b SmoothBar) progress() {
	b.progress_()
}

pub fn (mut b SmoothBar) colorize(color Color) {
	b.colorize_(color)
}

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

pub fn (b SmoothBar) spinner() string {
	return b.spinner_()
}

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

pub fn (mut b SmoothBar) bar_reader(bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

pub fn (bars []&SmoothBar) watch(mut wg sync.WaitGroup) {
	bars.watch_(mut wg)
}

// == Misc ====================================================================

pub fn bar_reader(b BarType, bytes []u8) &io.BufferedReader {
	return bar_reader_(b, bytes)
}

pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

fn handle_interrupt(signal os.Signal) {
	term.show_cursor()
	exit(0)
}
