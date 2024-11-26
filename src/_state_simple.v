module bartender

pub struct Bar {
	BarBase
pub mut:
	runes BarRunes
	pre   AffixInput = '['
	post  AffixInput = fn (b Bar) (string, string) {
		return '] ${b.pct()}% (${b.eta(0)})', '] ${b.pct()}%'
	}
mut:
	runes_     BarRunes_
	indicator_ string
}

pub struct BarRunes {
pub:
	progress  rune = `#`
	indicator ?rune
	remaining rune = ` `
}

// Internally resolve to strings instead of runes for color support.
struct BarRunes_ {
	progress  string
	indicator string
	remaining string
}
