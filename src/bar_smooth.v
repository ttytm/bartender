module bartender

import term
import time
import io

pub struct SmoothBar {
	BarBase
pub mut:
	theme ThemeChoice = Theme.push
	pre   AffixInput  = Affix{
		pending: ''
		finished: ''
	}
	post AffixInput = fn (b SmoothBar) (string, string) {
		return ' ${b.pct()}% (${b.eta(0)})', ' ${b.pct()}%'
	}
mut:
	theme_ Theme
	runes  SmoothRunes
	rune_i u8
}

// The current solution might be improved. In Rust it would be one enum with push & pull being tuple variants.
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

struct SmoothRunes {
mut: // Strings instead of runes for color support.
	f  []string // Fillers.
	s  []string // Smooth.
	sm []string // Smooth Mirrored. Used for merge, expand and split variant.
}

struct SmoothBarReader {
	BarReaderBase
mut:
	bar SmoothBar
}

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	fillers    = ['█', ' '] // Used for progress until current state and remaining space.
)

fn (mut b SmoothBar) setup() {
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

	b.width--
	if b.theme_ != .push && b.theme_ != .pull {
		b.width--
	}
	b.width_ = b.width

	b.iters = b.width_ * b.runes.s.len
	if b.theme_ != .push && b.theme_ != .pull {
		b.iters /= 2
	}

	b.state.pos = 0
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

fn (mut b SmoothBar) set_vals() {
	// Time
	b.state.time.last_change = time.ticks()

	// Pre- and Postfix
	prefix, postfix := resolve_affixations(b)
	b.pre_ = prefix
	b.post_ = postfix

	// Width - adjust to potential term size change
	last_width := b.width
	b.set_fit_width()
	if last_width != b.width_ {
		b.iters = b.width_ * b.runes.s.len
		if b.theme_ != .push && b.theme_ != .pull {
			b.iters /= 2
		}
	}

	// Positions
	b.rune_i++ // Index of the smooth rune to be rendered in the current progress.
	if b.rune_i == b.runes.s.len { // When all the smooth runes are rendered in one col, start again at the next col.
		b.rune_i = 0
		b.state.pos++
		if b.theme_ == .merge || b.theme_ == .expand || b.theme_ == .split {
			b.state.pos++
		}
	}
}

fn (b SmoothBar) draw_push_pull() {
	n := if b.theme_ == .pull {
		[b.width_ - b.state.pos, b.state.pos] // progressively empty
	} else {
		[b.state.pos, b.width_ - b.state.pos] // progressively fill
	}

	left := '${b.pre_}${b.runes.f[0].repeat(n[0])}${b.runes.s[b.rune_i]}'
	right := '${b.runes.f[1].repeat(n[1])}${b.post_}'

	eprint('\r${left}${right}')

	if b.state.pos >= b.width_ {
		progress := if b.theme_ == .pull { b.runes.f[1] } else { b.runes.f[0] }
		b.finish(progress.repeat(b.width_ + 1))
	}
}

fn (b SmoothBar) draw_merge() {
	remaining := b.width_ - b.state.pos

	left := '${b.pre_}${b.runes.f[0].repeat(b.state.pos / 2)}${b.runes.s[b.rune_i]}'
	// TODO: Smoothness for last two cols.
	middle := if remaining >= 0 {
		b.runes.f[1].repeat(remaining)
	} else {
		b.runes.f[0]
	}
	right := '${b.runes.sm[b.rune_i]}${b.runes.f[0].repeat(b.state.pos / 2)}${b.post_}'

	eprint('\r${left}${middle}${right}')

	if b.state.pos >= b.width_ {
		b.finish(b.runes.f[0].repeat(b.width_ + 2))
	}
}

fn (b SmoothBar) draw_expand() {
	left := '${b.pre_}${b.runes.f[1].repeat((b.width_ - b.state.pos) / 2)}${b.runes.sm[b.rune_i]}'
	middle := b.runes.f[0].repeat(b.state.pos)
	right := '${b.runes.s[b.rune_i]}${b.runes.f[1].repeat((b.width_ - b.state.pos) / 2)}${b.post_}'

	eprint('\r${left}${middle}${right}')

	if b.state.pos >= b.width_ {
		b.finish(b.runes.f[0].repeat(b.width_ + 2))
	}
}

fn (b SmoothBar) draw_split() {
	left := '${b.pre_}${b.runes.f[0].repeat((b.width_ - b.state.pos) / 2)}${b.runes.sm[b.rune_i]}'
	middle := b.runes.f[1].repeat(b.state.pos)
	right := '${b.runes.s[b.rune_i]}${b.runes.f[0].repeat((b.width_ - b.state.pos) / 2)}${b.post_}'

	eprint('\r${left}${middle}${right}')

	if b.state.pos >= b.width_ {
		b.finish(b.runes.f[1].repeat(b.width_ + 2))
	}
}

fn (mut r SmoothBarReader) read(mut buf []u8) !int {
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

fn (b SmoothBar) next_pos() u16 {
	return b.state.pos + u16(if b.theme_ == .push || b.theme_ == .pull {
		1
	} else {
		2
	})
}

fn (b &SmoothBar) finish(bar string) {
	term.erase_line('2')
	println('\r${b.pre_}${bar}${b.post_}')
	term.show_cursor()
}
