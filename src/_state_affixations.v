module bartender

pub struct Affix {
pub mut:
	pending  string
	finished string
}

enum AffixState {
	pending
	finished
}

type AffixInput = Affix
	| fn (b Bar) (string, string)
	| fn (b SmoothBar) (string, string)
	| string
