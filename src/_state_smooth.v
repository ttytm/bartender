module bartender

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

const smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
const smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
const fillers = ['█', ' '] // Used for progress until current state and remaining space.
