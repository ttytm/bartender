module bartender

import time

pub struct SmoothBar {
	Bar_
mut:
	theme_ Theme
	runes  SmoothRunes
pub mut:
	timeout time.Duration = time.microsecond * 500 // Duration between same column character prints for a smooth effect.
	theme   ThemeChoice   = Theme.push // Putting sumtype field first breaks default value. Related issue (github.com/vlang/v/issues/17758).
}

// Strings instead of runes for color support.
struct SmoothRunes {
mut:
	f  []string // Fillers.
	s  []string // Smooth.
	sm []string // Smooth Mirrored. Used for merge, expand and split variant.
}

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	fillers    = ['█', ' '] // Used for progress until current state and remaining space.
)

// The current solution might be improved. In Rust it would be one enum with `push` & `pull` being tuple variants.
type ThemeChoice = Theme | ThemeVariant

pub enum Theme {
	push
	pull
	merge
	expand
	split
}

pub struct ThemeVariant {
	theme  ThemeVariantOpt
	stream Stream
}

pub enum ThemeVariantOpt {
	push
	pull
}

pub enum Stream {
	fill
	drain
}

fn (mut b SmoothBar) setup() {
	b.state = 0

	if mut b.theme is Theme {
		b.theme_ = b.theme
		match b.theme {
			.push {
				b.setup_push(.fill)
			}
			.pull {
				b.setup_pull(.fill)
			}
			else {
				b.setup_duals()
			}
		}
	} else if mut b.theme is ThemeVariant {
		match b.theme.theme {
			.push {
				b.theme_ = .push
				b.setup_push(b.theme.stream)
			}
			.pull {
				b.theme_ = .pull
				b.setup_pull(b.theme.stream)
			}
		}
	}
}

fn (mut b SmoothBar) setup_push(stream Stream) {
	b.runes = struct {
		s: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		f: if stream == .fill { bartender.fillers } else { bartender.fillers.reverse() }
	}
}

fn (mut b SmoothBar) setup_pull(stream Stream) {
	b.runes = struct {
		s: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		f: if stream == .fill { bartender.fillers.reverse() } else { bartender.fillers }
	}
}

fn (mut b SmoothBar) setup_duals() {
	b.runes = struct {
		s: if b.theme_ == .split { bartender.smooth_rtl } else { bartender.smooth_ltr }
		sm: if b.theme_ == .split {
			bartender.smooth_ltr.reverse()
		} else {
			bartender.smooth_rtl.reverse()
		}
		f: bartender.fillers
	}
}

fn (b SmoothBar) draw_push_pull() {
	// Progressively empty. || Progressively fill.
	n := if b.theme_ == .pull { [b.width - b.state, b.state] } else { [b.state, b.width - b.state] }

	for r in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(n[0])}${r}')
		time.sleep(b.timeout)
	}

	if b.state >= b.width {
		dlm := if b.theme_ == .pull { b.runes.f[1] } else { b.runes.f[0] }
		finish('${b.border[0]}${dlm.repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(n[1])}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b SmoothBar) draw_merge() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(b.state)}${b.runes.s[idx]}')
		if width - b.state * 2 >= 0 {
			eprint(b.runes.f[1].repeat(width - b.state * 2))
		} else {
			eprint(b.runes.f[0])
		}
		eprint(b.runes.sm[idx])
		time.sleep(b.timeout)
	}
	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_expand() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[1].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[0].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_split() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[1].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[1].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}
