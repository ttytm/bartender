module bartender

import time

const test_bar = Bar{
	width: 20
	pre: '['
	post: Affix{
		pending: '] Loading...'
		finished: '] Done!'
	}
	runes: BarRunes{
		progress: `#`
		indicator: `>`
		remaining: ` `
	}
}

fn test_setup() {
	mut b := bartender.test_bar
	b.setup()
	assert b.state.pos == 0
	assert b.width_ == b.width
	assert b.runes_ == BarRunes_{
		progress: b.runes.progress.str()
		remaining: b.runes.remaining.str()
		indicator: b.runes.indicator or { b.runes.progress }.str()
	}
}

fn test_progress() {
	mut b := bartender.test_bar
	b.progress()!
	assert b.format() == '[>                   ] Loading...'
	b.progress()!
	assert b.format() == '[#>                  ] Loading...'
	for i := 0; i < 8; i++ {
		b.progress()!
	}
	assert b.format() == '[#########>          ] Loading...'
	for i := 0; i < 10; i++ {
		b.progress()!
	}
	assert b.state.pos == 20
	assert b.format() == '[####################] Done!'
}

fn test_pct() {
	mut b := bartender.test_bar
	b.setup()
	b.state.pos = 10
	// pct() gets the percentage of the next position to be used in the next draw event
	assert b.pct() == 55
}

fn test_eta() {
	mut b := bartender.test_bar
	b.setup()
	for i := 0; i < 10; i++ {
		b.progress()!
		// would take 2000ms to complete full bar
		time.sleep(100 * time.millisecond)
	}
	// eta() the estimated time of arrival from the next position to be used in the next draw event
	eta := b.eta(0)[..3].f32()
	assert eta > .6 && eta < 1.0

	b.width = 40
	b.reset()
	for i := 0; i < 20; i++ {
		b.progress()!
		// would take 2000ms to complete full bar
		time.sleep(50 * time.millisecond)
	}
	eta2 := b.eta(0)[..3].f32()
	assert eta2 > .6 && eta2 < 1.0
}
