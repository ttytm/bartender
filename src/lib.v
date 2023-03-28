// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import term
import time

struct BarBase {
mut:
	state State
pub mut:
	width  u16 = 80
	label  [2]string // Pending, Finished
	border [2]string = ['', '']! // Start, End
}

struct State {
mut:
	pos     u16
	time    Time
	percent u8
}

struct Time {
	start i64
mut:
	last_change i64
}

struct BarError {
	Error
}

fn (err BarError) msg() string {
	return 'Failed to pos. Bar already finished.'
}

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.state.pos >= b.width {
		panic(IError(BarError{}))
	}
	if b.runes_[0].len == 0 {
		b.setup()
	}
	if b.state.pos == 0 {
		term.hide_cursor()
		b.state.time = Time{
			start: time.ticks()
		}
	}
	b.state.time.last_change = time.ticks()
	b.state.pos += 1

	b.draw()
}

pub fn (mut b Bar) colorize(color BarColorType) {
	b.setup()

	match color {
		BarColor {
			b.colorize_components(color as BarColor)
		}
		BarColors {
			b.colorize_fg_bg(color as BarColors)
		}
		// NOTE: Upstream issue.
		// Color {} // when used instead of else -> invalid memory access.
		else {
			b.colorize_all(color as Color)
		}
	}
}

pub fn (mut b Bar) reset() {
	b.setup()
}

// <== }

// { == SmoothBar ==> =========================================================

pub fn (mut b SmoothBar) progress() {
	if b.state.pos >= b.width {
		panic(IError(BarError{}))
	}
	if b.runes.s.len == 0 {
		b.setup()
	}

	// Time
	if b.state.pos == 0 {
		term.hide_cursor()
		b.state.time = Time{
			start: time.ticks()
		}
	}
	b.state.time.last_change = time.ticks()

	// Position
	b.rune_i += 1
	if b.rune_i == b.runes.s.len {
		b.rune_i = 0
		b.state.pos += 1
		if b.theme_ == .merge || b.theme_ == .expand || b.theme_ == .split {
			b.state.pos += 1
		}
	}

	// Draw
	term.erase_line('0')
	match b.theme_ {
		.push, .pull {
			b.draw_push_pull()
		}
		.merge {
			b.draw_merge()
		}
		.expand {
			b.draw_expand()
		}
		.split {
			b.draw_split()
		}
	}
}

pub fn (mut b SmoothBar) colorize(color SmoothBarColorType) {
	b.setup()

	// NOTE: Upstream issue.
	// if color is C -> invalid memory access
	if color !is SmoothBarColor {
		b.colorize_all(color as Color)
		return
	}
	b.colorize_components(color as SmoothBarColor)
}

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

// <== }

pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

pub fn (b BarBase) pct() u8 {
	return u8(b.state.pos * 100 / b.width)
}

pub fn (b BarBase) eta() f64 {
	div := if b.state.pos == 0 { 1 } else { b.state.pos }
	return (b.state.time.last_change - b.state.time.start) / div * (b.width - b.state.pos)
}

fn finish(res string) {
	term.erase_line('2')
	println('\r${res}')
	term.show_cursor()
}