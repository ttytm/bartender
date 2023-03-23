// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

pub struct Bar {
mut:
	state u8
	kind  Kind // Compare enums instead of type_names after the bar was preped.
pub mut:
	label [2]string // Pending, Finished
	theme Theme = Push{.fill}
	width u16   = 79
	runes Runes
}

pub struct Runes {
	f []rune // fillers
	d []rune // delimeters
}

// In rust it'd be an enum with it's push & pull variants having values. The current solution can probably be improved.
type Theme = Pull | Push

pub struct Push {
	stream Stream
}

pub struct Pull {
	stream Stream
}

pub struct Merge {}

pub struct Expand {}

pub struct Split {}

enum Kind {
	push
	pull
	merge
	expand
	split
}

pub enum Stream {
	fill
	drain
}

const (
	smooth_ltr = [` `, `▏`, `▎`, `▍`, `▌`, `▋`, `▊`, `▉`, `█`]
	smooth_rtl = [`█`, `🮋`, `🮊`, `🮉`, `▐`, `🮈`, `🮇`, `▕`, ` `]
	delimeters = [`█`, ` `] // used for progress until current value and remaining space
	timeout_ms = 2
)

// { == Themes ==> ============================================================

pub fn (mut b Bar) prep() {
	b.state = 0
	match b.theme.type_name() {
		'bartender.Push' {
			b.prep_push(b.theme.stream)
			b.kind = .push
		}
		'bartender.Pull' {
			b.prep_pull(b.theme.stream)
			b.kind = .pull
		}
		else {}
	}
}

fn (mut b Bar) prep_push(stream Stream) {
	b.runes = Runes{
		f: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		d: if stream == .fill { bartender.delimeters } else { bartender.delimeters.reverse() }
	}
}

fn (mut b Bar) prep_pull(stream Stream) {
	b.runes = Runes{
		f: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		d: if stream == .fill { bartender.delimeters.reverse() } else { bartender.delimeters }
	}
}

// <== }

// { == Progress ==> ==========================================================

fn (b Bar) draw() {
	for r in b.runes.f {
		eprint(`\r`)
		if b.kind == .pull {
			eprint(b.runes.d[0].repeat(b.width - b.state))
		} else {
			eprint(b.runes.d[0].repeat(b.state))
		}
		eprint(r)
		time.sleep(bartender.timeout_ms * time.millisecond)
	}
	if b.state >= b.width {
		b.finish()
		return
	}
	if b.kind == .pull {
		eprint(b.runes.d[1].repeat(b.state))
	} else {
		eprint(b.runes.d[1].repeat(b.width - b.state))
	}
	eprint(' ${b.state * 100 / b.width}% ${b.label[0]}')
}

pub fn (mut b Bar) progress() {
	if b.runes.f.len == 0 {
		b.prep()
	}
	b.state += 1

	match b.kind {
		.pull, .push {
			b.draw()
		}
		else {}
	}
}

fn (b Bar) finish() {
	dlm := match b.kind {
		.pull {
			b.runes.d[1]
		}
		else {
			b.runes.d[0]
		}
	}
	eprint('\r')
	term.erase_line('2')
	println('${dlm.repeat(b.width + 1)} ${b.state * 100 / b.width}% ${b.label[1]}')
}

// <== }
