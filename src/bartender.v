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

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
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
	if b.runes.s.len == 0 {
		b.setup()
	}
	if b.state == 0 {
		term.hide_cursor()
	}

	b.sub_state += 1
	if b.sub_state == b.runes.s.len {
		b.sub_state = 0
		b.state += 1
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
	eprint('\r')
	term.erase_line('2')
	term.show_cursor()
	println(res)
}
