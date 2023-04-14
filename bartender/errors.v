module bartender

struct BarError {
	Error
	kind ErrorKind
}

enum ErrorKind {
	finished
	delay_exceeded
}

fn (err BarError) msg() string {
	match err.kind {
		.finished { return 'Trying to progress already finished bar.' }
		.delay_exceeded { return 'Delay cannot exceed 100%.' }
	}
}
