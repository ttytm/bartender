module bartender

import term
import time
import io
import os

fn (mut b Bar) setup() {
	b.state.pos = 0
	b.width_ = b.width
	b.iters = b.width
	b.runes_ = BarRunes_{
		progress: b.runes.progress.str()
		remaining: b.runes.remaining.str()
		indicator: b.runes.indicator or { b.runes.progress }.str()
	}
}

// Set bar values on progress
fn (mut b Bar) set_vals() {
	b.state.time.last_change = time.ticks()

	// Pre- and Postfix
	prefix, postfix := resolve_affixations(b)
	b.pre_ = prefix
	b.post_ = postfix

	// Width - adjust to potential term size change
	last_width := b.width_
	b.set_fit_width()
	if last_width != b.width_ {
		b.iters = b.width_
	}

	b.state.pos++
}

fn (b Bar) draw() {
	if b.state.pos == 1 && !b.multi {
		println('')
	}
	term.clear_previous_line()
	println(b.format())
}

fn (b Bar) format() string {
	left := b.pre_ + b.runes_.progress.repeat(b.state.pos - 1)
	indicator := if b.state.pos < b.width_ { b.runes_.indicator } else { b.runes_.progress }
	right := b.runes_.remaining.repeat(b.width_ - b.state.pos) + b.post_
	return left + indicator + right
}

fn (mut r BarReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}

	n := copy(mut buf, r.bytes[r.pos..get_buf_end(r)])
	r.pos += n

	if (f64(r.pos) / r.size * r.bar.width) > r.bar.pos() {
		r.bar.progress()
	}

	return n
}

fn (mut b Bar) colorize_uni(color Color) {
	b.runes_ = BarRunes_{
		progress: color.paint(b.runes_.progress, .fg)
		indicator: color.paint(b.runes_.indicator, .fg)
		remaining: color.paint(b.runes_.remaining, .fg)
	}
}

fn (mut b Bar) colorize_components(color BarColor) {
	b.runes_ = BarRunes_{
		progress: color.progress.paint_component(b.runes_.progress)
		indicator: color.indicator.paint_component(b.runes_.indicator)
		remaining: color.remaining.paint_component(b.runes_.remaining)
	}
}

// Functions for exposure.

fn (mut b Bar) progress_() {
	if b.state.time.start == 0 {
		if b.runes_.progress == '' {
			b.setup()
		}
		b.state.time = struct {time.ticks(), 0}
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

fn (mut b Bar) colorize_(color BarColorType) {
	b.setup()
	if color is BarColor {
		b.colorize_components(color)
	} else {
		b.colorize_uni(color as Color)
	}
}

fn (b Bar) eta_(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.state.pos + 1
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time(until current position) to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

fn (b Bar) pct_() u16 {
	if b.width_ == 0 {
		return 0
	}
	return (b.state.pos + 1) * 100 / b.width_
}

fn (mut b Bar) reset_() {
	b.setup()
	b.state.time = struct {0, 0}
}
