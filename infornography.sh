#!/bin/sh

setcolors() {
    if test -z "$COLORTERM" || test -z "${TERM#'*color'}" ; then
	return
    fi
}

for arg in "$@"; do
    case "$arg" in
	"-c")
	    setcolors
	    ;;
    esac
done

OS="$(uname -s)"
VERS="$(uname -r)"

command -v acpi >/dev/null && \
BAT="battery: $(acpi | awk '{print $4}')"

case $OS in
    *BSD)
        CPU="$(sysctl -n hw.model)"
        UPTIME="$(uptime | awk '{gsub(/,/,"") print $3 $4)}')"
        MEM="$(top -n 1 -b | awk '/Memory/{print $3}')" 
        if test -z "$MEM"; then
            if test -f /proc/meminfo; then
                MEMF="$(awk '/MemFree/{print int($2/10^3)}' /proc/meminfo)"
    		MEMC="$(awk '/Cached/{print int($2/10^3)}' /proc/meminfo)"
	        MEMA="$(( MEMF+MEMC ))"
                MEMT="$(awk '/MemTotal/{print int($2/10^3)}' /proc/meminfo)"
                MEM="$(( MEMT-MEMA ))/${MEMT}M"
            else
                MEMT="$(vmstat -h | awk 'NR==3{print $4}')"
                MEMF="$(vmstat -h | awk 'NR==3{gsub(/M/,""); print $5}')"
                MEM="$MEMF/$MEMT"
            fi
        fi
        ;;
    Darwin)
	CPU="$(sysctl -n machdep.cpu.brand_string)"
	;;
    *Linux)
        CPU="$(awk '/model name/{$1=$2=$3=""; sub(/ */,""); print $0}' \
                /proc/cpuinfo | uniq)"
        T="$(awk '{print int($1)}' /proc/uptime)"
	UPTIME="$(printf '%dd %dh %dm\n' \
		$(( $T/86400 )) $(( $T%86400/3600 )) $(( $T%3600/60 )))"
        MEMA="$(awk '/MemAvailable/{print int($2/10^3)}' /proc/meminfo)"
        if test -z "$MEMA"; then
            MEMF="$(awk '/MemFree/{print int($2/10^3)}' /proc/meminfo)"
	    MEMC="$(awk '/Cached/{print int($2/10^3)}' /proc/meminfo)"
	    MEMA="$(( MEMF+MEMC ))"
        
        fi
        MEMT="$(awk '/MemTotal/{print int($2/10^3)}' /proc/meminfo)"
        MEM="$(( MEMT-MEMA ))/${MEMT}M"
        ;;
    *)
        ;;
esac

test -z "$CPU" && CPU="Unknown"
test -z "$MEM" && MEM="Unknown"

cat << EOF
                ........              
             .........xx...           
      ..xx.......xoo@@ooooox..        $USER@$(/bin/hostname)
     ..o@o.....x@@@@@@oxxo@@x..       
     ..xx.....o@@@@@ooxxxxo@@o..      $OS
       .......ooxx.    ..  ..ox.      $VERS
       ........  ............ ...     $UPTIME
       ......  .....o@...........     $CPU
       .....\.xxo..x@@xx.x.x.....     
       ...../xoooxoo@@@@@xxoo.. .     $MEM
      .....xxo@@oxo@@@@@@oxo@x...     $BAT
      ....  x@@@@@@@@@@@@@@@oxox.     
      .....  .o@@@@@ccc@@@@o.xox.     $SHELL
     ...xooxxxxoo@@@@@@@@ox..xxxx.    $TERM
     ..xoooooooooxooooooxxx..xxxxx.   
     ..xoooooooxxx...x..xxx..xxxxxx   
    ....xxxxxxx..............xxxxx    
   ................................   
  ..................................  
 .....................x.............  
 ...................................  
..................................... 
.......................x............. 
EOF

unset MEM MEMF MEMA MEMC MEMT BAT CPU UPTIME VERS OS
