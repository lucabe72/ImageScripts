while getopts t:v: opt
 do
  case "$opt" in
    t)		TMP_DIR=$OPTARG;;
    v)		KVER=$OPTARG;;
    [?])	print >&2 "Usage: $0 [-v <version>] <core> <config> [<host image>]"
		exit 1;;
  esac
done
shift $((OPTIND-1))
