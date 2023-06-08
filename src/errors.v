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
	return match err.kind {
		.finished { 'Trying to progress already finished bar.' }
		.delay_exceeded { 'Delay cannot exceed 100%.' }
		.missing_multi { 'Failed drawing bars. []&Bar indices not set as multi: ${err.msg}' }
	}
}
