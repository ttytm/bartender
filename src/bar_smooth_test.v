module bartender

const test_bar = SmoothBar{
	width: 40
	post: ' Loading...'
}

fn test_setup() {
	mut b := bartender.test_bar
	b.setup()
	assert b.theme == ThemeChoice(Theme.push)
	assert b.state.pos == 0
	assert b.width_ == b.width
	assert b.iters == [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'].len * b.width
}

fn test_progress() {
	mut b := bartender.test_bar
	// 1/9
	b.progress()
	assert b.format() == '▏                                        Loading...'
	// 2/9
	b.progress()
	assert b.format() == '▎                                        Loading...'
	// 1
	for i := 0; i < 6; i++ {
		b.progress()
	}
	assert b.format() == '█                                        Loading...'
	// 1 5/9
	for i := 0; i < 5; i++ {
		b.progress()
	}
	assert b.format() == '█▌                                       Loading...'
	// 20 5/9
	for i := 0; i < 9 * 19; i++ {
		b.progress()
	}
	assert b.format() == '████████████████████▌                    Loading...'
	// TODO: test finished
}
