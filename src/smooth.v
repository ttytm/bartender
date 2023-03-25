module bartender

import time

pub struct SmoothBar {
	Bar_
mut:
	theme_ Theme
	runes  SmoothRunes
pub mut:
	timeout time.Duration = time.microsecond * 500 // Duration between same column character prints for a smooth effect.
	theme   ThemeChoice   = Theme.push // Putting sumtype field first breaks default value. Related issue (github.com/vlang/v/issues/17758)
}

struct SmoothRunes {
mut:
	f  []string // Fillers
	s  []string // Smooth
	sm []string // Smooth Mirrored. Used for merge, expand and split variant.
}

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	fillers    = ['█', ' '] // Used for progress until current state and remaining space.
)
