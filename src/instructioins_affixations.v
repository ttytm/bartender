module bartender

fn (a AffixInput) resolve_affix(b BarType, state AffixState) string {
	return match a {
		fn (SmoothBar) (string, string) {
			pending, finished := a(b as SmoothBar)
			match state {
				.pending { pending }
				.finished { finished }
			}
		}
		fn (Bar) (string, string) {
			pending, finished := a(b as Bar)
			match state {
				.pending { pending }
				.finished { finished }
			}
		}
		Affix {
			match state {
				.pending { a.pending }
				.finished { a.finished }
			}
		}
		string {
			a
		}
	}
}

fn resolve_affixations(b BarType) (string, string) {
	next_pos := match b {
		Bar { b.state.pos + 1 }
		SmoothBar { b.next_pos() }
	}
	prefix := if next_pos >= b.width_ {
		b.pre.resolve_affix(b, .finished)
	} else {
		b.pre.resolve_affix(b, .pending)
	}
	postfix := if next_pos >= b.width_ {
		b.post.resolve_affix(b, .finished)
	} else {
		b.post.resolve_affix(b, .pending)
	}

	return prefix, postfix
}
