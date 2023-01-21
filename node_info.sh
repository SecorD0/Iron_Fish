#!/bin/bash
# Default variables
language="EN"
raw_output="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about an Iron Fish node"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help               show help page"
		echo -e "  -l, --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                           LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -ro, --raw-output        the raw JSON output"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Iron_Fish/blob/main/node_info.sh — script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://t.me/OnePackage — noderun and tech community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
main() {
	# Texts
	if [ "$language" = "RU" ]; then
		local t_nn="\nНазвание ноды:          ${C_LGn}%s${RES}"
		local t_nv="Версия ноды:            ${C_LGn}%s${RES}"
		local t_lb="Последний блок:         ${C_LGn}%d${RES}"
		local t_sy1="Нода синхронизирована:  ${C_LR}нет${RES}"
		local t_sy2="Осталось нагнать:           ${C_LR}%d-%d=%d${RES}\n"
		local t_sy3="Нода синхронизирована:  ${C_LGn}да${RES}\n"
		
		local t_m1="Майнер:                 ${C_LGn}пул${RES}"
		local t_m2="Майнер:                 ${C_LGn}запущен${RES}"
		local t_m3="Майнер:                 ${C_LR}не запущен${RES}\n"
		local t_t="Потоков используется:   ${C_LGn}%d${RES}\n"
		
		local t_wn="Название кошелька:      ${C_LGn}%s${RES}"
		local t_wa="Адрес кошелька:         ${C_LGn}%s${RES}"
		local t_bal="Баланс:                 ${C_LGn}%f${RES} IRON\n"
		
		local t_err_nwn="\n${C_R}Нода не работает!${RES}\n"

	# Send Pull request with new texts to add a language - https://github.com/SecorD0/Iron_Fish/blob/main/node_info.sh
	#elif [ "$language" = ".." ]; then
	else
		local t_nn="\nMoniker:                 ${C_LGn}%s${RES}"
		local t_nv="Node version:            ${C_LGn}%s${RES}"
		local t_lb="Latest block height:     ${C_LGn}%d${RES}"
		local t_sy1="Node is synchronized:    ${C_LR}no${RES}"
		local t_sy2="It remains to catch up:  ${C_LR}%d-%d=%d${RES}\n"
		local t_sy3="Node is synchronized:    ${C_LGn}yes${RES}\n"
		
		local t_m1="Miner:                   ${C_LGn}pool${RES}"
		local t_m2="Miner:                   ${C_LGn}launched${RES}"
		local t_m3="Miner:                   ${C_LR}not launched${RES}\n"
		local t_t="Threads are used:        ${C_LGn}%d${RES}\n"
		
		local t_wn="Wallet name:             ${C_LGn}%s${RES}"		
		local t_wa="Wallet address:          ${C_LGn}%s${RES}"
		local t_bal="Balance:                 ${C_LGn}%f${RES} IRON\n"

		local t_err_nwn="\n${C_R}Node isn't working!${RES}\n"		
	fi
	
	# Actions
	sudo apt install wget awk jq bc -y &>/dev/null
	if ! docker ps -a | grep iron_fish_node | grep -q "Up" && ! sudo systemctl cat ironfishd 2>/dev/null | grep -q running; then
		printf_n "$t_err_nwn"
		return 1 2>/dev/null; exit 1
	fi
	
	if docker ps -a | grep -q iron_fish_node; then
		local command="docker exec -t iron_fish_node ironfish"
		local response=`docker inspect iron_fish_miner 2>&1`
		if ! grep -q "No such" <<< "$response"; then
			if grep -q "pool" <<< "$response"; then
				local miner="pool"
			else
				local miner="true"
			fi
			local threads=`jq -r ".[0].Config.Cmd[-1]" <<< "$response"`
		else
			local miner="false"
		fi
	else
		local command="ironfish"
		local response=`sudo systemctl status ironfishd-miner | grep running`
		if [ -n "$response" ]; then
			if grep -q "pool" <<< "$response"; then
				local miner="pool"
			else
				local miner="true"
			fi
			local threads=`sudo systemctl cat ironfishd-miner | grep -oPm1 "(?<=\-t )([^%]+)(?= \-\-no)"`
		else
			local miner="false"
		fi
	fi
	
	local moniker=`$command config:get nodeName --no-color | tr -d '"' | tr -d '\r'`
	local status=`$command status | tr -d '\r'`
	local node_version=`echo "$status" | grep Version | awk '{print $2}'`
	local latest_block_height=`echo "$status" | grep Blockchain | awk '{print $(3)}' | tr -d '(' | tr -d ')'`
	if [ `echo "$status" | grep Blockchain | awk '{print $(NF)}' | tr -d '(' | tr -d ')'` = "SYNCED" ]; then
		local catching_up="false"
	else
		local catching_up="true"
	fi
	
	local wallet_name=`$command wallet:which | tr -d '\r'`
	local wallet_address=`$command wallet:address | tr -d '\r' | awk '{print $(NF)}'`
	local balance=`$command wallet:balance | grep Balance | awk '{print $(NF)}'`
	
	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '{"moniker": "%s", "node_version": "%s", "latest_block_height": %d, "catching_up": %b, "miner": "%s", "threads": %d, "wallet_name": "%s", "wallet_address": "%s", "balance": %f}' \
"$moniker" \
"$node_version" \
"$latest_block_height" \
"$catching_up" \
"$miner" \
"$threads" \
"$wallet_name" \
"$wallet_address" \
"$balance" 2>/dev/null
	else
		printf_n "$t_nn" "$moniker"
		printf_n "$t_nv" "$node_version"
		printf_n "$t_lb" "$latest_block_height"
		if [ "$catching_up" = "true" ]; then
			local current_block=`wget -qO- "https://api-production.ironfish.network/blocks?limit=1&main=true" | jq -r ".data[0].sequence"`
			local diff=`bc -l <<< "$current_block-$latest_block_height"`
			printf_n "$t_sy1"
			printf_n "$t_sy2" "$current_block" "$latest_block_height" "$diff"
		else
			printf_n "$t_sy3"
		fi
		
		if [ "$miner" = "pool" ]; then
			printf_n "$t_m1"
		elif [ "$miner" = "true" ]; then
			printf_n "$t_m2"
		else
			printf_n "$t_m3"
		fi
		if [ -n "$threads" ]; then printf_n "$t_t" "$threads"; fi

		printf_n "$t_wn" "$wallet_name"
		printf_n "$t_wa" "$wallet_address"
		printf_n "$t_bal" "$balance" 2>/dev/null
	fi
}

main
