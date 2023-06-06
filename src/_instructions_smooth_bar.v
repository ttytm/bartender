module bartender

import term
import time
import io
import os

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
	b.runes = SmoothRunes{
		s: if stream == .fill { smooth_ltr } else { smooth_rtl }
		f: if stream == .fill { fillers } else { fillers.reverse() }
	}
}

fn (mut b SmoothBar) setup_pull(stream Stream) {
	b.runes = SmoothRunes{
		s: if stream == .fill {
			smooth_rtl.reverse()
		} else {
			smooth_ltr.reverse()
		}
		f: if stream == .fill { fillers.reverse() } else { fillers }
	}
}

fn (mut b SmoothBar) setup_duals() {
	b.runes = SmoothRunes{
		s: if b.theme_ == .split { smooth_rtl } else { smooth_ltr }
		sm: if b.theme_ == .split {
			smooth_ltr.reverse()
		} else {
			smooth_rtl.reverse()
		}
		f: fillers
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

fn (mut b SmoothBar) progress_() {
	if b.state.time.start == 0 {
		if b.runes.s.len == 0 {
			b.setup()
		}
		b.state.time = struct {time.ticks(), 0}
		term.hide_cursor()
		os.signal_opt(.int, handle_interrupt) or { panic(err) }
	}
	if b.state.pos > b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}

	b.set_vals()
	if b.multi {
		return
	}

	b.draw()
	if b.state.pos >= b.width_ && b.rune_i == 0 {
		println('')
		term.show_cursor()
	}
}

fn (mut b SmoothBar) colorize_(color Color) {
	b.setup()

	mut painted_runes := SmoothRunes{}

	for r in b.runes.f {
		painted_runes.f << color.paint(r, .fg)
	}
	for mut r in b.runes.s {
		painted_runes.s << color.paint(r, .fg)
	}
	if b.runes.sm.len > 0 {
		for mut r in b.runes.sm {
			painted_runes.sm << color.paint(r, .fg)
		}
	}

	b.runes = painted_runes
}

fn (b SmoothBar) eta_(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.next_pos()
	if b.width_ == b.state.pos {
		return ''
	}
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner_()
	}
	// Avg. time(until current position) to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

fn (b SmoothBar) pct_() u16 {
	if b.width_ == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.width_
}
