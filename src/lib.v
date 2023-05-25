// Source: https://github.com/tobealive/bartender
// License: MIT

// lib.v contains all public functions.
// Associated structs and private sub-functions are located in the corresponding files.
module bartender

import os
import io
import term
import time
import sync

const (
	buf_max_len   = 1024
	spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!
)

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.state.time.start == 0 {
		if b.runes_.progress == '' {
			b.setup()
		}
		b.state.time = Times{time.ticks(), 0}
		term.hide_cursor()
		os.signal_opt(.int, handle_interrupt) or { panic(err) }
	}
	if b.state.pos >= b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}

	b.set_vals()
	if b.multi {
		return
	}
	b.draw()
	if b.state.pos >= b.width_ {
		term.show_cursor()
	}
}

pub fn (bars []&Bar) watch(mut wg sync.WaitGroup) {
	bars.ensure_mutli() or {
		eprintln(err)
		exit(0)
	}
	time.sleep(time.millisecond * 15)
	for {
		if bars.draw() {
			term.show_cursor()
			break
		}
		// Redraw the bars every 15ms to reduce load and prevent flashing output.
		time.sleep(time.millisecond * 15)
	}
	wg.done()
}

pub fn (mut b Bar) colorize(color BarColorType) {
	b.setup()
	if color is BarColor {
		b.colorize_components(color)
	} else {
		b.colorize_uni(color as Color)
	}
}

pub fn (b Bar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return (b.state.pos + 1) * 100 / b.width_
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b Bar) eta(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.state.pos + 1
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time until now to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

pub fn (b Bar) spinner() string {
	if b.state.pos + 1 >= b.width_ {
		return ''
	}
	return bartender.spinner_runes[(b.state.pos - 1) % bartender.spinner_runes.len]
}

pub fn (mut b Bar) reset() {
	b.setup()
	b.state.time = Times{0, 0}
}

// <== }

// { == SmoothBar ==> =========================================================

pub fn (mut b SmoothBar) progress() {
	if b.state.time.start == 0 {
		if b.runes.s.len == 0 {
			b.setup()
		}
		b.state.time = Times{time.ticks(), 0}
		term.hide_cursor()
		os.signal_opt(.int, handle_interrupt) or { panic(err) }
	}
	if b.state.pos > b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}

	b.set_vals()
	if b.multi {
		return
	}

	b.draw()
	if b.state.pos >= b.width_ && b.rune_i == 0 {
		println('')
		term.show_cursor()
	}
}

pub fn (bars []&SmoothBar) watch(mut wg sync.WaitGroup) {
	// NOTE: Same function for Bars and SmoothBars. Re-check with Vlangs progression if this can be solved with a sumtype.
	bars.ensure_mutli() or {
		eprintln(err)
		exit(0)
	}
	for {
		if bars.draw() {
			term.show_cursor()
			break
		}
		// Slow redraw loop to reduce load.
		time.sleep(time.millisecond * 5)
	}
	wg.done()
}

pub fn (mut b SmoothBar) colorize(color Color) {
	b.setup()

	mut painted_runes := SmoothRunes{}

	for r in b.runes.f {
		painted_runes.f << color.paint(r, .fg)
	}
	for mut r in b.runes.s {
		painted_runes.s << color.paint(r, .fg)
	}
	if b.runes.sm.len > 0 {
		for mut r in b.runes.sm {
			painted_runes.sm << color.paint(r, .fg)
		}
	}

	b.runes = painted_runes
}

pub fn (b SmoothBar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.width_
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b SmoothBar) eta(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.next_pos()
	if b.width_ == b.state.pos {
		return ''
	}
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time until now to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

pub fn (b SmoothBar) spinner() string {
	next_pos := b.next_pos()
	if b.width_ == next_pos {
		return ''
	}
	return bartender.spinner_runes[(b.rune_i) % bartender.spinner_runes.len]
}

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

// <== }

// { == Reader ==> ============================================================

pub fn bar_reader(b BarType, bytes []u8) &io.BufferedReader {
	return match b {
		Bar {
			io.new_buffered_reader(
				reader: BarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
		SmoothBar {
			io.new_buffered_reader(
				reader: SmoothBarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
	}
}

fn get_buf_end(r BarReaderType) int {
	return if r.pos + bartender.buf_max_len >= r.size {
		r.size
	} else {
		r.pos + bartender.buf_max_len
	}
}

// <== }

// { == Misc ==> ==============================================================

pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

fn handle_interrupt(signal os.Signal) {
	term.show_cursor()
	exit(0)
}

// <== }
