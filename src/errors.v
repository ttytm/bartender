module bartender

struct BarError {
	Error
	kind ErrorKind
	msg  string
}

enum ErrorKind {
	finished
	delay_exceeded
	missing_multi
}

fn (err BarError) msg() string {
	match err.kind {
		.finished { return 'Trying to progress already finished bar.' }
		.delay_exceeded { return 'Delay cannot exceed 100%.' }
		.missing_multi { return 'Failed drawing bars. []&Bar indices not set as multi: ${err.msg}' }
	}
}
