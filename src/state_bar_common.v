module bartender

struct BarBase {
pub mut:
	width u16 = 60
	// Number of iterations. NOTE: Solution is up for improvement.
	// Resolves to `width_` for `Bar` and `smooth_runes.len * width_` for `SmoothBar`.
	iters int = 60
	multi bool
mut:
	state State
	// Private params. Based on public equivalents.
	// Assigned on `<bar>.setup()` or on `<bar>.progress()`.
	// Might get mutated by state or terminal size changes.
	width_ u16
	pre_   string
	post_  string
}

struct BarReaderBase {
	bytes []u8
	size  int
mut:
	pos int
}

struct State {
mut:
	pos  u16
	time Times
}

struct Times {
mut:
	start       i64
	last_change i64
}

type BarType = Bar | SmoothBar
type BarReaderType = BarReader | SmoothBarReader
