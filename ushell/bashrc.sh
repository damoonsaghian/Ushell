if [ "$CODEVSHELL_PROMPT" = true ]; then
	PS1=""
	PS2=""
	_run_cmd() {
		echo "$BASH_COMMAND" >> /tmp/codevshell-command
		clear
	}	
else
	PS1='\n─\e[7m \[${PWD}\] \e[0m\[$(printf "%0.s─" $(seq 1 $((COLUMNS - ${#PWD} - 3)) ))\]\n'
	PS2=""
	PS0='\[$(printf "%0.s┄" $(seq 1 $((COLUMNS)) ))\]\n'
	_run_cmd() {
		printf '%0.s-' $(seq 1 $COLUMNS)
		echo
		$BASH_COMMAND
	}
fi
trap _run_cmd DEBUG

[ -n "$CODEVSHELL_COMMAND" = true ] && {
	. /tmp/codevshell-term-env
	$CODEVSHELL_COMMAND
	export -p > /tmp/codevshell-term-env
	exit
}
