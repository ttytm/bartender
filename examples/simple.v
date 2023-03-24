module main

import bartender { Theme, ThemeVariant }
import time

fn main() {
	mut b := bartender.Classic{
		border: ["|", "|"]!
		width: 60
	}
	mut b2 := bartender.Classic{
		border: ["[", "]"]!
		runes: [`#`, `-`]!
		width: 60
	}

	for _ in 0 .. b.width {
		b.progress()
		time.sleep(time.millisecond * 20)
	}
	for _ in 0 .. b2.width {
		b2.progress()
		time.sleep(time.millisecond * 20)
	}

}
