PS1='─\e[7m \[${PWD}\] \e[0m\[$(printf "%0.s─" $(seq 1 $((COLUMNS - ${#PWD} - 3)) ))\]\n'
PS2=""
PS0='\[$(printf "%0.s-" $(seq 1 $((COLUMNS)) ))\]\n'
