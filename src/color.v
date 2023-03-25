module bartender

import term

type BarColorType = BarColor | TermColor
type SmoothBarColorType = SmoothBarColor | TermColor
type TermColor = fn (msg string) string

pub struct BarColor {
	fill   TermColor
	indicator TermColor
	border TermColor
}

pub struct SmoothBarColor {
	fill   TermColor
	border TermColor
}

pub fn (mut b Bar) colorize(color BarColorType) {
	b.setup()

	if color !is BarColor {
		b.colorize_all(color as TermColor)
		return
	}
	b.colorize_components(color as BarColor)
}

fn (mut b Bar) colorize_all(color TermColor) {
	b.runes_ = [term.colorize(color as TermColor, b.runes_[0]),
		term.colorize(color as TermColor, b.runes_[1])]!
	b.indicator_ = term.colorize(color as TermColor, b.indicator_)

	if b.border.len > 0 {
		b.border = [term.colorize(color as TermColor, b.border[0]),
			term.colorize(color as TermColor, b.border[1])]!
	}
}

fn (mut b Bar) colorize_components(color BarColor) {
	b.runes_ = [term.colorize(color.fill, b.runes_[0]),
		term.colorize(color.fill, b.runes_[1])]!
	b.indicator_ = term.colorize(color.indicator, b.indicator_)

	if b.border.len > 0 {
		b.border = [term.colorize(color.border, b.border[0]),
			term.colorize(color.border, b.border[1])]!
	}
}

pub fn (mut b SmoothBar) colorize(color SmoothBarColorType) {
	b.setup()

	if color !is SmoothBarColor {
		b.colorize_all(color as TermColor)
		return
	}
	b.colorize_components(color as SmoothBarColor)
}

fn (mut b SmoothBar) colorize_all(color TermColor) {
	mut painted_runes := SmoothRunes{}

	for d in b.runes.f {
		painted_runes.f << term.colorize(color as TermColor, d)
	}
	for mut f in b.runes.s {
		painted_runes.s << term.colorize(color as TermColor, f)
	}
	if b.runes.sm.len > 0 {
		for mut f in b.runes.sm {
			painted_runes.sm << term.colorize(color as TermColor, f)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		b.border = [term.colorize(color as TermColor, b.border[0]),
			term.colorize(color as TermColor, b.border[1])]!
	}
}

fn (mut b SmoothBar) colorize_components(color SmoothBarColor) {
	mut painted_runes := SmoothRunes{}

	painted_runes.f << term.colorize(color.fill, b.runes.f[0])
	painted_runes.f << b.runes.f[1]
	for mut f in b.runes.s {
		painted_runes.s << term.colorize(color.fill, f)
	}
	if b.runes.sm.len > 0 {
		for mut f in b.runes.sm {
			painted_runes.sm << term.colorize(color.fill, f)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		painted_border := [term.colorize(color.border, b.border[0]),
			term.colorize(color.border, b.border[1])]!
		b.border = painted_border
	}
}
