module main

import net

type ShellFn = fn (mut P2PMsgSession, []string) !

fn add(mut session P2PMsgSession, args []string) ! {
	new_rpeer := net.resolve_ipaddrs(args[1], .ip, .udp)![0]
	session.rpeers << new_rpeer
}
