while getopts c:t:v: opt
 do
  case "$opt" in
    c)		CPUS=$OPTARG;;
    t)		TMP_DIR=$OPTARG;;
    v)		KVER=$OPTARG;;
    [?])	print >&2 "Usage: $0 [-v <version>] <core> <config> [<host image>]"
		exit 1;;
  esac
done
shift $((OPTIND-1))
