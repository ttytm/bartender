module bartender

struct BarError {
	Error
	kind ErrorKind
}

enum ErrorKind {
	finished
}

fn (err BarError) msg() string {
	match err.kind {
		.finished { return 'Trying to progress already finished bar.' }
	}
}
