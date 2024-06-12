module main

import net

type ShellFn = fn (mut P2PMsgSession, []string) !

// 0 == no command executed
// 1 == a command was executed, therefore don't send to peers
fn msg_shell(mut session P2PMsgSession, shell_fns map[string]ShellFn, data string) !int {
	if data[0..2] == '//' {
		mut shell_str := data[2..data.len].clone()

		shell_args := shell_str.split(' ')

		shell_action := shell_fns[shell_args[0]] or {
			eprintln('invallid command')
			return 1
		}
		shell_action(mut session, shell_args) or {
			eprintln('${err}')
			return 1
		}
		return 1
	}
	return 0
}

fn add(mut session P2PMsgSession, args []string) ! {
	new_rpeer := net.resolve_ipaddrs(args[1], .ip, .udp)![0]

	for rpeer in session.rpeers {
		if rpeer.str() == new_rpeer.str() {
			return error('${rpeer} has already been added as a peer')
		}
	}

	session.rpeers << new_rpeer
}
