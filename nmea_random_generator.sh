checksum () {
	checksum=0
	for i in $(echo -n $1 | hexdump -v -e '/1 "%02X\n"'); do
        	checksum=$(printf "%02X\n" $((0x$i ^ 0x$checksum)))
        done
	echo -n "$checksum"
}

while true; do
	time=$(date -u +"%l%M%S")
	day=$(date -u +"%-d")
	month=$(date -u +"%-m")
	year=$(date -u +"%Y")
	lat_deg_f=$(printf "%f\n" $(echo $(shuf -i0-90000000 -n1) / 1000000 | bc -l))
	lat_deg_int=$(echo $lat_deg_f / 1 | bc)
	lat_min_f=`echo "($lat_deg_f - $lat_deg_int) * 60" | bc`
	lat_dir=`shuf -e N S | head -n1`
	lon_deg_f=$(printf "%f\n" $(echo $(shuf -i0-180000000 -n1) / 1000000 | bc -l))
	lon_deg_int=$(echo $lon_deg_f / 1 | bc)
	lon_min_f=`echo "($lon_deg_f - $lon_deg_int) * 60" | bc`
	lon_dir=`shuf -e E W | head -n1`
	track_mag=$(printf "%f\n" $(echo $(shuf -i0-3600 -n1) / 10 | bc -l))
	track_true=$(echo $track_mag - 14 | bc -l)
	speed_knots=$(printf "%f\n" $(echo $(shuf -i0-990 -n1) / 10 | bc -l))
	speed_kmph=$(echo "$speed_knots * 1.852" | bc -l)

	gns_str=$(printf "GPGNS,%09.2f,%02d%07.4f,%s,%03d%07.4f,%s,D,09,1.20,10.9,-29.6,," $time $lat_deg_int $lat_min_f $lat_dir $lon_deg_int $lon_min_f $lon_dir)
	printf "\$%s*%2s\r\n" $gns_str $(checksum "$gns_str")

	gga_str=$(printf "GPGGA,%09.2f,%02d%07.4f,%s,%03d%07.4f,%s,2,09,1.20,10.9,M,-29.6,M,," $time $lat_deg_int $lat_min_f $lat_dir $lon_deg_int $lon_min_f $lon_dir)
	printf "\$%s*%2s\r\n" $gga_str $(checksum "$gga_str")

	zda_str=$(printf "GPZDA,%09.2f,%02d,%02d,%04d,04,00" $time $day $month $year)
	printf "\$%s*%2s\r\n" $zda_str $(checksum "$zda_str")

	vtg_str=$(printf "GPVTG,%05.1f,T,%05.1f,M,%00.1f,N,%00.1f,K,A" $track_true $track_mag $speed_knots $speed_kmph)
	printf "\$%s*%2s\r\n" $vtg_str $(checksum "$vtg_str")

	sleep 1
done
