module main

import net

type RmsgShellFn = fn (mut P2PMsgSession, net.Addr, []string) !

// same as msg_shell
fn rmsg_shell(mut session P2PMsgSession, shell_fns map[string]RmsgShellFn, from net.Addr, data string) !int {
	if data[0..2] != '::' {
		return 0
	}

	command := data[2..data.len].clone()
	args := command.split(' ')

	action := shell_fns[args[0]] or {
		session.lpeer.write_to_string(from, '::invalid')!
		return 1
	}

	action(mut session, from, args) or {
		session.lpeer.write_to_string(from, '::error ${err}')!
		return 1
	}
	return 1
}

fn alias(mut session P2PMsgSession, rpeer net.Addr, args []string) ! {
	rpeer_ip_str := rpeer.str()
	session.alias_map[rpeer_ip_str] = args[1]
}

fn r_invalid(mut session P2PMsgSession, rpeer net.Addr, args []string) ! {
	eprintln('\rAn invalid command was sent to ${rpeer}')
	print('> ')
}

fn r_shell_error(mut session P2PMsgSession, rpeer net.Addr, args []string) ! {
	if args.len > 1 {
		eprintln('\rAn error occured as a result of a command you sent to ${rpeer}')
		eprintln('${args[1..args.len].join(' ')}')
		print('> ')
	} else {
		eprintln('\runknown error from ${rpeer}')
		print('> ')
	}
}
