module bartender

import term

type BarColorType = BarColor | BarColors | Color
type SmoothBarColorType = Color | SmoothBarColor

type Color = fn (msg string) string

// NOTE: Upstream issue.
// Doesn't seem possible to use a named type atm. `Colors` below or [2]Color, both fail.
// type Colors = [2]fn (msg string) string

struct ComponentColor {
	progress Color
	border   Color
}

// NOTE: Upstream issue.
// Embedding `ComponentColor` would be preferred. Unfortunately, not working atm.
pub struct BarColor {
	progress  Color = term.reset
	fill      Color = term.reset
	border    Color = term.reset
	indicator Color = term.reset
}

pub struct BarColors {
	progress  [2]fn (msg string) string = [term.reset, term.reset]!
	fill      [2]fn (msg string) string = [term.reset, term.reset]!
	border    [2]fn (msg string) string = [term.reset, term.reset]!
	indicator [2]fn (msg string) string = [term.reset, term.reset]!
}

pub type SmoothBarColor = ComponentColor

// { == Bar ==> ===============================================================

fn (mut b Bar) colorize_all(color Color) {
	b.runes_ = [term.colorize(color as Color, b.runes_[0]), term.colorize(color as Color,
		b.runes_[1])]!
	b.indicator_ = term.colorize(color as Color, b.indicator_)

	if b.border.len > 0 {
		b.border = [term.colorize(color as Color, b.border[0]),
			term.colorize(color as Color, b.border[1])]!
	}
}

fn (mut b Bar) colorize_components(color BarColor) {
	b.runes_ = [term.colorize(color.progress, b.runes_[0]), term.colorize(color.fill, b.runes_[1])]!
	b.indicator_ = term.colorize(color.indicator, b.indicator_)

	if b.border.len > 0 {
		b.border = [term.colorize(color.border, b.border[0]),
			term.colorize(color.border, b.border[1])]!
	}
}

pub fn (mut b Bar) colorize_fg_bg(colors BarColors) {
	b.setup()
	b.runes_ = [colors.progress.apply_fg_bg(b.runes_[0]), colors.fill.apply_fg_bg(b.runes_[1])]!
	b.indicator_ = colors.indicator.apply_fg_bg(b.indicator_)
	if b.border.len > 0 {
		b.border = [colors.border.apply_fg_bg(b.border[0]), colors.border.apply_fg_bg(b.border[1])]!
	}
}

fn (colors [2]fn (msg string) string) apply_fg_bg(s string) string {
	return term.colorize(colors[0], term.colorize(colors[1], s))
}

// <== }

// { == SmoothBar ==> =========================================================

fn (mut b SmoothBar) colorize_all(color Color) {
	// NOTE: Upstream issue.
	// Not possible to directly mutate. E.g.:
	// for mut f in b.runes.f {
	// 	f = term.colorize(color as Color, f)
	// }
	// Putting them into a variable and then assigning works.
	mut painted_runes := SmoothRunes{}

	for f in b.runes.f {
		painted_runes.f << term.colorize(color, f)
	}
	for mut s in b.runes.s {
		painted_runes.s << term.colorize(color, s)
	}
	if b.runes.sm.len > 0 {
		for mut s in b.runes.sm {
			painted_runes.sm << term.colorize(color, s)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		b.border = [term.colorize(color as Color, b.border[0]),
			term.colorize(color as Color, b.border[1])]!
	}
}

fn (mut b SmoothBar) colorize_components(color SmoothBarColor) {
	mut painted_runes := SmoothRunes{}

	painted_runes.f << term.colorize(color.progress, b.runes.f[0])
	painted_runes.f << b.runes.f[1]
	for mut f in b.runes.s {
		painted_runes.s << term.colorize(color.progress, f)
	}
	if b.runes.sm.len > 0 {
		for mut f in b.runes.sm {
			painted_runes.sm << term.colorize(color.progress, f)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		painted_border := [term.colorize(color.border, b.border[0]),
			term.colorize(color.border, b.border[1])]!
		b.border = painted_border
	}
}

// <== }
