#!/bin/bash
GETARGS() {
	#present function call with getopts like interface
	local FLGVARNAME ARGVARNAME CURARG
	FLGVARNAME="FLG$$"
	ARGVARNAME="ARG$$"
	if [ -n "${!FLGVARNAME}" ]; then
		eval "${!FLGVARNAME}"
		eval "${!ARGVARNAME}"
	fi
	if declare -p FLG&>/dev/null; then
		if [ "${#FLG[@]}" -eq 0 ]; then
			unset $FLGVARNAME $ARGVARNAME $2 OPTARG
			return 1
		else
			for CURARG in "${!FLG[@]}"; do
				if [ $CURARG -eq 0 ]; then
					eval export "$2"="${FLG[0]}"
				else
					FLG[$((CURARG - 1))]="${FLG[$CURARG]}"
				fi
				unset FLG[$CURARG]
			done
			if [ ${#ARG[@]} -eq 0 ]; then
				unset OPTARG
			else
				[ -z "${ARG[0]}" ] && unset OPTARG
				for CURARG in "${!ARG[@]}"; do
					if [ $CURARG -eq 0 ]; then
						[ -n "${ARG[0]}" ] && export OPTARG="${ARG[0]}"
					else
						ARG[$((CURARG - 1))]="${ARG[$CURARG]}"
					fi
					unset ARG[$CURARG]
				done
			fi
			CURARG='$(declare -p FLG)'
			eval $FLGVARNAME="$CURARG"
			CURARG='$(declare -p ARG)'
			eval $ARGVARNAME="$CURARG"
			return 0
		fi
	fi
	local ALLFLGS SHRTFLGS TMPSHRTFLGS TMPLNGFLGS CURFLG TMP1 TMP2 REQARGS NOREQARGS ERRHNDL
	#input sanitize, build lists of accepted flags, then build array based on presented arguements and accepted flags
	ALLFLGS="$1"
	while [[ "$ALLFLGS" == *'::'* ]]; do
		ALLFLGS="${ALLFLGS/::/:}"
	done
	while [[ "$ALLFLGS" == *',,'* ]]; do
		ALLFLGS="${ALLFLGS/,,/,}"
	done
	while [[ "$ALLFLGS" == *'---'* ]]; do
		ALLFLGS="${ALLFLGS/---/--}"
	done
	TMPLNGFLGS="--${ALLFLGS#*--}"
	SHRTFLGS="${ALLFLGS%%--*}"
	SHRTFLGS="${SHRTFLGS//-/}"
	TMPSHRTFLGS="$SHRTFLGS"
	if [ "${SHRTFLGS::1}" = ':' ]; then
		SHRTFLGS="${SHRTFLGS:1}"
		ERRHNDL=true
	else
		ERRHNDL=false
	fi
	CURFLG=0
	REQARGS=''
	NOREQARGS=''
	for CURARG in "${@:3}"; do
		if [ "$CURARG" = '-' ] || [ "$CURARG" = '--' ]; then
			if $ERRHNDL; then
				local FLG[$CURFLG] ARG[$CURFLG]
				FLG[$CURFLG]='?'
				ARG[$CURFLG]="$CURARG"
				CURFLG=$((CURFLG + 1))
				continue 1
			else
				printf -- "$CURARG is invalid!\n" >&2
				return 1
			fi
		fi
		if [[ "$CURARG" == '-'* ]]; then
				if [ -n "$REQARGS" ]; then
					if $ERRHNDL; then
						while [ -n "$REQARGS" ]; do
							TMP1="${REQARGS%%,*}"
							local ARG[$TMP1]
							ARG[$TMP1]="${FLG[$TMP1]}"
							FLG[$TMP1]='?'
							REQARGS="${REQARGS#$TMP1,}"
						done
					else
						TMP1="${REQARGS%%,*}"
						printf -- "${FLG[$TMP1]} no supplied arguement!\n" >&2
						return 1
					fi
				fi
			if [[ "$CURARG" == '--'* ]]; then
				if [[ "$ALLFLGS" != *"$CURARG"* ]]; then
					if $ERRHNDL; then
						local FLG[$CURFLG] ARG[$CURFLG]
						FLG[$CURFLG]="?"
						ARG[$CURFLG]="$CURARG"
						CURFLG=$((CURFLG + 1))
						continue 1
					else
						printf -- "$CURARG is invalid flag!\n" >&2
						return 1
					fi
				fi
				if [[ "$TMPLNGFLGS" = *"$CURARG"* ]]; then
					TMP2="$TMPLNGFLGS"
					while [ -n "$TMP2" ]; do
						if [[ "$TMP2" = "$CURARG"* ]]; then
							local FLG[$CURFLG]
							FLG[$CURFLG]="$CURARG"
							TMP2="${TMP2#$CURARG}"
							if [ "${TMP2::1}" = ':' ]; then
								[ "${TMP2:1:1}" != ',' ] && TMPLNGFLGS="${TMPLNGFLGS/$CURARG:}"
								REQARGS="$REQARGS$CURFLG,"
							elif [ "${TMP2::1}" = ',' ]; then
								if [ "${TMP2:1:1}" = ':' ]; then
									REQARGS="$REQARGS$CURFLG,"
								else
									NOREQARGS="$NOREQARGS$CURFLG,"
								fi
							else
								TMPLNGFLGS="${TMPLNGFLGS/$CURARG:}"
								NOREQARGS="$NOREQARGS$CURFLG,"
							fi
							CURFLG=$((CURFLG + 1))
							break 1
						else
							TMP2="${TMP2:2}"
							TMP2="--${TMP2#*--}"
						fi
					done
				elif $ERRHNDL; then
					local FLG[$CURFLG] ARG[$CURFLG]
					FLG[$CURFLG]="?"
					ARG[$CURFLG]="$CURARG"
					CURFLG=$((CURFLG + 1))
					continue 1
				else
					printf -- "$CURARG cannot be used again!\n" >&2
					return 1
				fi
			else
				CURARG="${CURARG:1}"
				while [ -n "$CURARG" ]; do
					TMP1="${CURARG::1}"
					CURARG="${CURARG:1}"
					if [[ "$SHRTFLGS" != *"$TMP1"* ]]; then
						if $ERRHNDL; then
							local FLG[$CURFLG] ARG[$CURFLG]
							FLG[$CURFLG]="?"
							ARG[$CURFLG]="-$TMP1"
							CURFLG=$((CURFLG + 1))
							continue 1
						else
							printf -- "-$TMP1 is invalid flag!\n" >&2
							return 1
						fi
					fi
					if [[ "$TMPSHRTFLGS" = *"$TMP1"* ]]; then
						TMP2="$TMPSHRTFLGS"
						while [ -n "$TMP2" ]; do
							if [[ "$TMP2" = "$TMP1"* ]]; then
								local FLG[$CURFLG]
								FLG[$CURFLG]="$TMP1"
								TMP2="${TMP2:1}"
								TMP1="${TMP2::1}"
								if [ "$TMP1" = ':' ]; then
									[ "${TMP2:1:1}" != ',' ] && TMPSHRTFLGS="${TMPSHRTFLGS/${FLG[$CURFLG]}:}"
									REQARGS="$REQARGS$CURFLG,"
								elif [ "$TMP1" = ',' ]; then
									if [ "${TMP2:1:1}" = ':' ]; then
										REQARGS="$REQARGS$CURFLG,"
									else
										NOREQARGS="$NOREQARGS$CURFLG,"
									fi
								else
									TMPSHRTFLGS="${TMPSHRTFLGS/${FLG[$CURFLG]}}"
									NOREQARGS="$NOREQARGS$CURFLG,"
								fi
								FLG[$CURFLG]="-${FLG[$CURFLG]}"
								CURFLG=$((CURFLG + 1))
								break 1
							else
								TMP2="${TMP2:1}"
							fi
						done
					elif $ERRHNDL; then
						local FLG[$CURFLG] ARG[$CURFLG]
						FLG[$CURFLG]="?"
						ARG[$CURFLG]="-$TMP1"
						NOREQARGS="$NOREQARGS$CURFLG,"
						CURFLG=$((CURFLG + 1))
						continue 1
					else
						printf -- "-$TMP1 cannot be used again!\n" >&2
						return 1
					fi
				done
			fi
		elif [ -n "$REQARGS" ]; then
			TMP1="${REQARGS%%,*}"
			local ARG[$TMP1]
			ARG[$TMP1]="$CURARG"
			REQARGS="${REQARGS#$TMP1,}"
			NOREQARGS="$NOREQARGS$TMP1,"
		elif [ -z "${FLG[0]}" ]; then
			if $ERRHNDL; then
				local FLG[$CURFLG] ARG[$CURFLG]
				FLG[$CURFLG]="?"
				ARG[$CURFLG]="$CURARG"
				CURFLG=$((CURFLG + 1))
			else
				printf -- "$CURARG is not a flag!\n" >&2
				return 1
			fi
		elif [ -z "$REQARGS" ]; then
			if $ERRHNDL; then
				local FLG[$CURFLG] ARG[$CURFLG]
				FLG[$CURFLG]='?'
				if [[ "$NOREQARGS" = *"$((CURFLG - 1))"* ]]; then
					ARG[$CURFLG]="$CURARG"
					NOREQARGS="$NOREQARGS$CURFLG,"
				elif [ "${FLG[$((CURFLG - 1))]}" = '?' ]; then
					ARG[$CURFLG]="${ARG[$((CURFLG - 1))]}"
				else
					ARG[$CURFLG]="${FLG[$((CURFLG - 1))]}"
				fi
				CURFLG=$((CURFLG + 1))
			else
				printf -- "${FLG[$((CURFLG - 1))]} over supplied arrguements!\n" >&2
				return 1
			fi
		fi
	done
	if [ -n "$REQARGS" ]; then
		if $ERRHNDL; then
			while [ -n "$REQARGS" ]; do
				TMP1="${REQARGS%%,*}"
				local ARG[$TMP1]
				ARG[$TMP1]="${FLG[$TMP1]}"
				FLG[$TMP1]='?'
				REQARGS="${REQARGS#$TMP1,}"
			done
		else
			TMP1="${REQARGS%%,*}"
			printf -- "${FLG[$TMP1]} no supplied arguement!\n" >&2
			return 1
		fi
	fi
	#first output to function call location
	if [ -n "${FLG[0]}" ]; then
		for REQARGS in "${!FLG[@]}"; do
			if [ $REQARGS -eq 0 ]; then
				eval export "$2"="${FLG[0]}"
			else
				FLG[$((REQARGS - 1))]="${FLG[$REQARGS]}"
			fi
			unset FLG[$REQARGS]
		done
		if [ ${#ARG[@]} -ne 0 ]; then
			[ -z "${ARG[0]}" ] && unset OPTARG
			for REQARGS in "${!ARG[@]}"; do
				if [ $REQARGS -eq 0 ]; then
					[ -n "${ARG[0]}" ] && export OPTARG="${ARG[0]}"
				else
					ARG[$((REQARGS - 1))]="${ARG[$REQARGS]}"
				fi
				unset ARG[$REQARGS]
			done
		fi
		REQARGS='$(declare -p FLG)'
		eval export $FLGVARNAME="$REQARGS"
		REQARGS='$(declare -p ARG)'
		eval export $ARGVARNAME="$REQARGS"
		return 0
	else
		return 1
	fi
}
