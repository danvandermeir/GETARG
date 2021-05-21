#!/bin/bash
GETARGS() {
	#present function call with getopts like interface
	local FLGVARNAME ARGVARNAME SHUFARG SHUFARG2
	FLGVARNAME="FLG$$"
	ARGVARNAME="ARG$$"
	if [ -n "${!FLGVARNAME}" ]; then
		eval "${!FLGVARNAME}"
		eval "${!ARGVARNAME}"
	fi
	if declare -p FLG&>/dev/null; then

		if [ "${#FLG[@]}" -ne 0 ]; then
			for SHUFARG in "${!FLG[@]}"; do
				if [ $SHUFARG -eq 0 ]; then
					eval export "$2"="${FLG[0]}"
				else
					FLG[$((SHUFARG - 1))]="${FLG[SHUFARG]}"
				fi
				unset FLG[$SHUFARG]
			done
			if [ ${#ARG[@]} -eq 0 ]; then
				unset OPTARG
			else
				for SHUFARG in "${!ARG[@]}"; do
					if [ $SHUFARG -eq 0 ]; then
						if [ -n "${ARG[0]}" ]; then
							export OPTARG="${ARG[0]}"
						else
							unset OPTARG
						fi
					else
						ARG[$((SHUFARG - 1))]="${ARG[SHUFARG]}"
					fi
					unset ARG[$SHUFARG]
				done
			fi
			SHUFARG='$(declare -p FLG)'
			eval $FLGVARNAME="$SHUFARG"
			SHUFARG='$(declare -p ARG)'
			eval $ARGVARNAME="$SHUFARG"
			return 0
		else
			unset $FLGVARNAME $ARGVARNAME $2 OPTARG
			return 1
		fi
	fi
	local CURARG ALLARGS SHUFARG3 SHUFARG4
	#minor input sanitize and build list of presented flags
	ALLARGS=''
	while [[ "$1" == *'::'* ]]; do
		set -- "${1/::/:}" "${@:2}"
	done
	CURARG="${@:3}"
	[[ "$CURARG" == '-' ]] || [[ "$CURARG" != '-'* ]] && return 1
	for CURARG in "${@:3}"; do
		[[ "$CURARG" == '-' ]] && return 1
		[[ "$CURARG" == '-'* ]] && ALLARGS="$ALLARGS${CURARG#-}"
	done
	[ -z "$ALLARGS" ] && return 1
	CURARG="$ALLARGS"
	#error for unknown presented flags
	while [[ -n "$CURARG" ]]; do
		SHUFARG="${CURARG::1}"
		[[ "$1" != *"$SHUFARG"* ]] && return 1
		CURARG="${CURARG:1}"
	done
	#creates presented flags to iterate over allowing multiple iterance of flag if postpended , in flag options
	while [ -n "$ALLARGS" ]; do
		SHUFARG="${ALLARGS::1}"
		CURARG="$CURARG$SHUFARG"
		SHUFARG2="${1#*$SHUFARG}"
		SHUFARG3="${SHUFARG2::1}"
		SHUFARG4=''
		while [ "$SHUFARG3" = ',' ] || [ "$SHUFARG3" = ':' ]; do
			[ "$SHUFARG3" = ',' ] && ALLARGS="${ALLARGS:1}" && SHUFARG4=','
			[ "$SHUFARG3" = ':' ] && CURARG="$CURARG$SHUFARG3"
			SHUFARG2="${SHUFARG2:1}"
			SHUFARG3="${SHUFARG2::1}"
		done
		[ -z "$SHUFARG4" ] && ALLARGS="${ALLARGS//$SHUFARG}"
	done
	#create arrays of flags and respective arguements, error if required arguement not present
	SHUFARG2=0
	SHUFARG3=false
	SHUFARG4=false
	for SHUFARG in "${@:3}"; do
		if [[ "$SHUFARG" == "-"* ]]; then
			$SHUFARG3 && return 1
			ALLARGS="${SHUFARG#-}"
		fi
		while [ -n "$ALLARGS" ]; do
			SHUFARG3=true
			if $SHUFARG4 || [ "${ALLARGS::1}" = "${CURARG::1}" ]; then
				local FLG[$SHUFARG2]
				FLG[$SHUFARG2]="${ALLARGS::1}"
				CURARG="${CURARG:1}"
				if [ "${CURARG::1}" = ':' ]; then
					SHUFARG4=true
					break 1
				elif $SHUFARG4; then
					SHUFARG4=false
					local ARG[$SHUFARG2]
					ARG[$SHUFARG2]="$SHUFARG"
				fi
				SHUFARG2=$((SHUFARG2 + 1))
			elif [ "${1::1}" = ':' ]; then
				eval export "$2"='?'
				export OPTARG="${FLG[$SHUFARG2]}"
			else
				printf "FAILURE\n" &>2
				exit  1
			fi
			ALLARGS="${ALLARGS:1}"
			SHUFARG3=false
		done
	done
	$SHUFARG3 || $SHUFARG4 && return 1
	#first output to function call location
	for SHUFARG in "${!FLG[@]}"; do
		if [ $SHUFARG -eq 0 ]; then
			eval export "$2"="${FLG[0]}"
		else
			FLG[$((SHUFARG - 1))]="${FLG[SHUFARG]}"
		fi
		unset FLG[$SHUFARG]
	done
	if [ ${#ARG[@]} -ne 0 ]; then
		for SHUFARG in "${!ARG[@]}"; do
			if [ $SHUFARG -eq 0 ]; then
				if [ -n "${ARG[0]}" ]; then
					export OPTARG="${ARG[0]}"
				else
					unset OPTARG
				fi
			else
				ARG[$((SHUFARG - 1))]="${ARG[SHUFARG]}"
			fi
			unset ARG[$SHUFARG]
		done
	fi
	SHUFARG='$(declare -p FLG)'
	eval export $FLGVARNAME="$SHUFARG"
	SHUFARG='$(declare -p ARG)'
	eval export $ARGVARNAME="$SHUFARG"
	return 0
}

while GETARGS a::b,c:, x "$@"; do
	case $x in
		a) echo 'a called with '"$OPTARG";;
		b) echo 'b called'"$OPTARG";;
		c) echo 'c called with '"$OPTARG";;
	esac
done

#pPeoiInsfca
#:p:P:le:o:i:I:n:s:f:c:ugda:

	# $1 must be allowed flag list as described
	# $2 must be chosen variable name
	# $3 must be "$@" or arguements
	# : prepended to flag list will not exit on error, errors must be handled similar to getopts
	# , postpended to flag means flag can be passed multiple times
	# : postpended to flag means flag has required arguement
