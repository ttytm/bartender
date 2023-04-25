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
	rune_i u8 // idx used to render all runes in one col before progressing to next col(b.state.pos).
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

fn (b SmoothBar) draw() {
	term.clear_previous_line()
	println(b.format())
}

fn (b SmoothBar) format() string {
	remaining := b.width_ - b.state.pos
	return match b.theme_ {
		.push {
			left := b.pre_ + b.runes.f[0].repeat(b.state.pos)
			smooth_rune := if b.state.pos >= b.width_ { b.runes.f[0] } else { b.runes.s[b.rune_i] }
			right := b.runes.f[1].repeat(b.width_ - b.state.pos) + b.post_

			left + smooth_rune + right
		}
		.pull {
			mut left := b.pre_ + b.runes.f[0].repeat(b.width_ - b.state.pos) + b.runes.s[b.rune_i]
			if b.state.pos >= b.width_ {
				left = b.pre_ + b.runes.f[1]
			}
			right := b.runes.f[1].repeat(b.state.pos) + b.post_

			left + right
		}
		.merge {
			left := b.pre_ + b.runes.f[0].repeat(b.state.pos / 2)
			middle := if remaining == 0 { // Finished. Full bar is filled.
				b.runes.f[0].repeat(2)
			} else if remaining <= 2 { // Last two cols. Smooth runes are in the center.
				b.runes.f[0] + b.runes.s[b.rune_i] + b.runes.sm[b.rune_i] + b.runes.f[0]
			} else { // Default. Center filled with remaining space smooth runes left and right.
				b.runes.s[b.rune_i] + b.runes.f[1].repeat(remaining) + b.runes.sm[b.rune_i]
			}
			right := b.runes.f[0].repeat(b.state.pos / 2) + b.post_

			left + middle + right
		}
		.expand {
			left := b.pre_ + if remaining == 0 {
				b.runes.f[0].repeat(1)
			} else if remaining <= 2 {
				b.runes.sm[b.rune_i] + b.runes.f[0]
			} else {
				b.runes.f[1].repeat((b.width_ - b.state.pos) / 2) + b.runes.sm[b.rune_i]
			}
			middle := b.runes.f[0].repeat(b.state.pos)
			right := if remaining == 0 {
				b.runes.f[0].repeat(1)
			} else if remaining <= 2 {
				b.runes.f[0] + b.runes.s[b.rune_i]
			} else {
				b.runes.s[b.rune_i] + b.runes.f[1].repeat((b.width_ - b.state.pos) / 2)
			} + b.post_

			left + middle + right
		}
		.split {
			left := b.pre_ + if remaining == 0 {
				b.runes.f[1].repeat(1)
			} else if remaining <= 2 {
				b.runes.sm[b.rune_i] + b.runes.f[1]
			} else {
				b.runes.f[0].repeat((b.width_ - b.state.pos) / 2) + b.runes.sm[b.rune_i]
			}
			middle := b.runes.f[1].repeat(b.state.pos)
			right := if remaining == 0 {
				b.runes.f[1].repeat(1)
			} else if remaining <= 2 {
				b.runes.f[1] + b.runes.s[b.rune_i]
			} else {
				b.runes.s[b.rune_i] + b.runes.f[0].repeat((b.width_ - b.state.pos) / 2)
			} + b.post_

			left + middle + right
		}
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

fn (bars []&SmoothBar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}

// A function that takes a sumtype arg []&Bar | []&SmoothBar would more concice, but won't work atm.
fn (bars []&SmoothBar) ensure_mutli() ! {
	mut not_multi := []int{}
	for i, bar in bars {
		if !bar.multi {
			not_multi << i
		}
	}
	if not_multi.len > 0 {
		return IError(BarError{
			kind: .missing_multi
			msg: '${not_multi}'
		})
	}
}
