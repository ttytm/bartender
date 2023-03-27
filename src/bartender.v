// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import term

struct BarBase {
pub mut:
	width  u16 = 80
	label  [2]string // Pending, Finished
	border [2]string = ['', '']! // Start, End
	state  u16
}

struct BarError {
	Error
}

fn (err BarError) msg() string {
	return 'Failed to progress. Bar already finished.'
}

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.state >= b.width {
		panic(IError(BarError{}))
	}
	if b.runes_[0].len == 0 {
		b.setup()
	}
	if b.state == 0 {
		term.hide_cursor()
	}

	b.state += 1
	b.draw()
}

pub fn (mut b Bar) reset() {
	b.setup()
}

// <== }

// { == SmoothBar ==> =========================================================

pub fn (mut b SmoothBar) progress() {
	if b.state >= b.width {
		panic(IError(BarError{}))
	}
	if b.runes.s.len == 0 {
		b.setup()
	}
	if b.state == 0 {
		term.hide_cursor()
	}

	b.rune_i += 1
	if b.rune_i == b.runes.s.len {
		b.rune_i = 0
		b.state += 1
		if b.theme_ == .merge || b.theme_ == .expand || b.theme_ == .split {
			b.state += 1
		}
	}

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

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

// <== }

fn finish(res string) {
	term.erase_line('2')
	println('\r${res}')
	term.show_cursor()
}
