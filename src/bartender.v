// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time

pub struct Bar {
mut:
	state u8
pub mut:
	label string
	theme Theme = Push{.fill}
	width u16   = 79
	runes Runes
}

pub struct Runes {
	f []rune // fillers
	d []rune // delimeters
}

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
		}
		'bartender.Pull' {
			b.prep_pull(b.theme.stream)
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

fn (b Bar) push() {
	for r in b.runes.f {
		eprint(`\r`)
		eprint(b.runes.d[0].repeat(b.state))
		eprint(r)
		time.sleep(bartender.timeout_ms * time.millisecond)
	}
	eprint(b.runes.d[1].repeat(b.width - b.state))
	eprint(' ${b.state * 100 / b.width}% ${b.label}')
	if b.state >= b.width {
		println('')
	}
}

fn (b Bar) pull() {
	for r in b.runes.f {
		eprint(`\r`)
		eprint(b.runes.d[0].repeat(b.width - b.state))
		eprint(r)
		time.sleep(bartender.timeout_ms * time.millisecond)
	}
	eprint(b.runes.d[1].repeat(b.state))
	eprint(' ${b.state * 100 / b.width}% ${b.label}')
	if b.state >= b.width {
		println('')
	}
}

pub fn (mut b Bar) progress() {
	if b.runes.f.len == 0 {
		b.prep()
	}
	b.state += 1

	match b.theme.type_name() {
		'bartender.Push' {
			b.push()
		}
		'bartender.Pull' {
			b.pull()
		}
		else {}
	}
}

// <== }
