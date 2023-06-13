module main

import bartender { SmoothBar, Theme, ThemeVariant }
import sync
import time
import rand

fn pseudo_dissimilar_progress_(mut wg sync.WaitGroup, mut b SmoothBar) ! {
	rand_num := rand.intn(20) or { panic(err) }
	for _ in 0 .. b.iters {
		b.progress()!
		// HACK: modifer to adjust timeout for the scope of this example
		modifier := if b.pre.str()[..1].int() > 4 { 2 } else { 1 }
		time.sleep((time.millisecond * rand_num) + (15 * modifier * time.millisecond))
	}
	wg.done()
}

fn main() {
	mut b1 := SmoothBar{
		multi: true
		post: ''
	}
	b1.pre = '1: '
	mut b2 := b1
	b2.pre = '2: '
	b2.theme = Theme.pull
	mut b3 := b1
	b3.pre = '3: '
	b3.theme = ThemeVariant{.push, .drain}
	mut b4 := b1
	b4.pre = '4: '
	b4.theme = ThemeVariant{.pull, .drain}
	mut b5 := b1
	b5.pre = '5: '
	b5.theme = Theme.expand
	mut b6 := b1
	b6.pre = '6: '
	b6.theme = Theme.split
	mut b7 := b1
	b7.pre = '7: '
	b7.theme = Theme.merge
	mut bars := [&b1, &b2, &b3, &b4, &b5, &b6, &b7]

	mut wg := sync.new_waitgroup()
	for mut b in bars {
		wg.add(1)
		spawn pseudo_dissimilar_progress_(mut wg, mut b)
	}
	wg.add(1)
	spawn bars.watch(mut wg)
	wg.wait()
}
