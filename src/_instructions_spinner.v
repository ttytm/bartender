module bartender

const spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!

fn (b Bar) spinner_() string {
	if b.state.pos + 1 >= b.width_ {
		return ''
	}
	return bartender.spinner_runes[(b.state.pos - 1) % bartender.spinner_runes.len]
}

fn (b SmoothBar) spinner_() string {
	next_pos := b.next_pos()
	if b.width_ == next_pos {
		return ''
	}
	return bartender.spinner_runes[(b.rune_i) % bartender.spinner_runes.len]
}
