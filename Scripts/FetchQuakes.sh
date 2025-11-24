#!/bin/bash
set -euo pipefail

FEED_URL="https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.csv"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$BASE_DIR/Data"
SCHEMA_FILE="$BASE_DIR/Sql/Schema.sql"
CSV_FILE="$DATA_DIR/latest_all_day.csv"
MYSQL_CMD="/opt/lampp/bin/mysql -u root"
DB_NAME="earthquake_db"

ensure_database() {
    "$MYSQL_CMD" < "$SCHEMA_FILE"
}

download_csv() {
    mkdir -p "$DATA_DIR"
    curl -sSf "$FEED_URL" -o "$CSV_FILE"
    if [ ! -s "$CSV_FILE" ]; then
        echo "Error: downloaded CSV is empty"
        exit 1
    fi
    header="$(head -n 1 "$CSV_FILE")"
    if [ "$header" != "time,latitude,longitude,depth,mag,magType,nst,gap,dmin,rms,net,id,updated,place,type,locationSource,magSource,horizontalError,depthError,magError,magNst,status" ]; then
        echo "Error: unexpected CSV header"
        exit 1
    fi
}

import_csv() {
    awk -v FPAT='([^,]*)|("[^"]*")' "
NR==1 { next }
{
    time=\$1
    lat=\$2
    lon=\$3
    depth=\$4
    mag=\$5
    magType=\$6
    nst=\$7
    gap=\$8
    dmin=\$9
    rms=\$10
    net=\$11
    id=\$12
    updated=\$13
    place=\$14
    type=\$15
    locationSource=\$16
    magSource=\$17
    horizontalError=\$18
    depthError=\$19
    magError=\$20
    magNst=\$21
    status=\$22

    gsub(/^\"|\"$/, \"\", time)
    gsub(/^\"|\"$/, \"\", updated)
    gsub(/^\"|\"$/, \"\", place)

    gsub(\"Z$\", \"\", time)
    gsub(\"T\", \" \", time)
    gsub(\"Z$\", \"\", updated)
    gsub(\"T\", \" \", updated)

    gsub(\"'\", \"''\", place)

    if (lat == \"\") lat=\"NULL\"
    if (lon == \"\") lon=\"NULL\"
    if (depth == \"\") depth=\"NULL\"
    if (mag == \"\") mag=\"NULL\"
    if (nst == \"\") nst=\"NULL\"
    if (gap == \"\") gap=\"NULL\"
    if (dmin == \"\") dmin=\"NULL\"
    if (rms == \"\") rms=\"NULL\"
    if (horizontalError == \"\") horizontalError=\"NULL\"
    if (depthError == \"\") depthError=\"NULL\"
    if (magError == \"\") magError=\"NULL\"
    if (magNst == \"\") magNst=\"NULL\"

    if (time == \"\") time_val=\"NULL\"; else time_val=sprintf(\"'%s'\", time)
    if (updated == \"\") updated_val=\"NULL\"; else updated_val=sprintf(\"'%s'\", updated)
    if (magType == \"\") magType_val=\"NULL\"; else magType_val=sprintf(\"'%s'\", magType)
    if (net == \"\") net_val=\"NULL\"; else net_val=sprintf(\"'%s'\", net)
    if (id == \"\") next
    id_val=sprintf(\"'%s'\", id)
    if (place == \"\") place_val=\"NULL\"; else place_val=sprintf(\"'%s'\", place)
    if (type == \"\") type_val=\"NULL\"; else type_val=sprintf(\"'%s'\", type)
    if (locationSource == \"\") locationSource_val=\"NULL\"; else locationSource_val=sprintf(\"'%s'\", locationSource)
    if (magSource == \"\") magSource_val=\"NULL\"; else magSource_val=sprintf(\"'%s'\", magSource)
    if (status == \"\") status_val=\"NULL\"; else status_val=sprintf(\"'%s'\", status)

    printf \"INSERT IGNORE INTO networks (code) VALUES (%s);\n\", net_val

    printf \"INSERT IGNORE INTO earthquakes (event_id, event_time, latitude, longitude, depth_km, magnitude, mag_type, nst, gap, dmin, rms, net_code, updated_time, place, event_type, location_source, mag_source, horizontal_error, depth_error, mag_error, mag_nst, status) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);\n\", id_val, time_val, lat, lon, depth, mag, magType_val, nst, gap, dmin, rms, net_val, updated_val, place_val, type_val, locationSource_val, magSource_val, horizontalError, depthError, magError, magNst, status_val
}
" "$CSV_FILE" | "$MYSQL_CMD" "$DB_NAME"
}

ensure_database
download_csv
import_csv
echo "Earthquake data fetch and insert completed"
