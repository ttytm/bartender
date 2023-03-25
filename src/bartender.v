// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import term

struct Bar_ {
mut:
	state u16
pub mut:
	width  u16 = 80
	label  [2]string // Pending, Finished
	border [2]string = ['', '']! // Start, End
}

pub struct Bar {
	Bar_
pub mut:
	runes     [2]rune = [`#`, ` `]!
	indicator ?rune
}

pub fn (mut b Bar) progress() {
	if b.state == 0 {
		term.hide_cursor()
	}
	b.state += 1
	b.draw()
}

pub fn (mut b SmoothBar) progress() {
	if b.runes.s.len == 0 {
		b.setup()
	}
	if b.state == 0 {
		term.hide_cursor()
	}

	b.state += 1

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

fn finish(res string) {
	eprint('\r')
	term.erase_line('2')
	term.show_cursor()
	println(res)
}
