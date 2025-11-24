#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLOTS_DIR="$BASE_DIR/Plots"
DATA_DIR="$BASE_DIR/Data"
MYSQL_CMD="/opt/lampp/bin/mysql -u root -N"
DB_NAME="earthquake_db"

mkdir -p "$PLOTS_DIR"
mkdir -p "$DATA_DIR"

function PlotMagTime {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT event_time, magnitude FROM earthquakes WHERE magnitude IS NOT NULL ORDER BY event_time;" > "$DATA_DIR/mag_time.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/MagVsTime.png"
set title "Earthquake Magnitude Over Time"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"
set xlabel "Time"
set ylabel "Magnitude"
plot "$DATA_DIR/mag_time.dat" using 1:2 with lines linewidth 2 title "Magnitude"
EOF
}

function PlotDepthTime {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT event_time, depth_km FROM earthquakes WHERE depth_km IS NOT NULL ORDER BY event_time;" > "$DATA_DIR/depth_time.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/DepthVsTime.png"
set title "Earthquake Depth Over Time"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"
set xlabel "Time"
set ylabel "Depth (km)"
plot "$DATA_DIR/depth_time.dat" using 1:2 with lines linewidth 2 title "Depth"
EOF
}

function PlotMagHist {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT magnitude FROM earthquakes WHERE magnitude IS NOT NULL;" > "$DATA_DIR/mag_only.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/MagnitudeHist.png"
set title "Histogram of Earthquake Magnitudes"
binwidth = 0.2
bin(x,width) = width*floor(x/width) + width/2.0
set boxwidth binwidth
set style fill solid
set xlabel "Magnitude"
set ylabel "Count"
plot "$DATA_DIR/mag_only.dat" using (bin(\$1,binwidth)):(1.0) smooth freq with boxes title "Frequency"
EOF
}

function PlotDepthHist {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT depth_km FROM earthquakes WHERE depth_km IS NOT NULL;" > "$DATA_DIR/depth_only.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/DepthHist.png"
set title "Histogram of Earthquake Depths"
binwidth = 10
bin(x,width) = width*floor(x/width) + width/2.0
set boxwidth binwidth
set style fill solid
set xlabel "Depth (km)"
set ylabel "Count"
plot "$DATA_DIR/depth_only.dat" using (bin(\$1,binwidth)):(1.0) smooth freq with boxes title "Frequency"
EOF
}

function PlotLocations {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT longitude, latitude FROM earthquakes WHERE latitude IS NOT NULL AND longitude IS NOT NULL;" > "$DATA_DIR/locations.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/LocationScatter.png"
set title "Earthquake Locations"
set xlabel "Longitude"
set ylabel "Latitude"
set key off
plot "$DATA_DIR/locations.dat" using 1:2 with points pointtype 7 pointsize 0.5
EOF
}

function PlotLocationsMagSize {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT longitude, latitude, magnitude FROM earthquakes WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND magnitude IS NOT NULL;" > "$DATA_DIR/locations_mag.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/LocationBubble.png"
set title "Earthquake Locations (Point Size = Magnitude)"
set xlabel "Longitude"
set ylabel "Latitude"
set key off
plot "$DATA_DIR/locations_mag.dat" using 1:2:(0.1*\$3) with points pointtype 7 pointsize variable
EOF
}

function PlotCountByHour {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT DATE_FORMAT(event_time, '%Y-%m-%d %H:00:00') AS hour, COUNT(*) FROM earthquakes GROUP BY hour ORDER BY hour;" > "$DATA_DIR/count_hour.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/CountByHour.png"
set title "Number of Earthquakes Per Hour"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"
set xlabel "Hour"
set ylabel "Count"
set boxwidth 1800
set style fill solid
plot "$DATA_DIR/count_hour.dat" using 1:2 with boxes title "Count"
EOF
}

function PlotCountByMagBand {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT CASE WHEN magnitude < 2 THEN '<2' WHEN magnitude < 4 THEN '2-4' WHEN magnitude < 6 THEN '4-6' ELSE '6+' END AS band, COUNT(*) FROM earthquakes WHERE magnitude IS NOT NULL GROUP BY band ORDER BY band;" > "$DATA_DIR/count_mag_band.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/CountByMagBand.png"
set title "Number of Earthquakes by Magnitude Band"
set style data histograms
set style fill solid
set xlabel "Magnitude Band"
set ylabel "Count"
plot "$DATA_DIR/count_mag_band.dat" using 2:xtic(1) title "Count"
EOF
}

function PlotCumulativeCount {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SET @c:=0; SELECT event_time, (@c:=@c+1) AS cum FROM earthquakes ORDER BY event_time;" > "$DATA_DIR/cumulative.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/CumulativeCount.png"
set title "Cumulative Number of Earthquakes"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%m/%d\n%H:%M"
set xlabel "Time"
set ylabel "Cumulative Count"
plot "$DATA_DIR/cumulative.dat" using 1:2 with lines linewidth 2 title "Cumulative"
EOF
}

function PlotDepthVsMag {
    "$MYSQL_CMD" -D "$DB_NAME" -e "SELECT depth_km, magnitude FROM earthquakes WHERE depth_km IS NOT NULL AND magnitude IS NOT NULL;" > "$DATA_DIR/depth_mag.dat"
    gnuplot <<EOF
set term png size 1000,600
set output "$PLOTS_DIR/DepthVsMag.png"
set title "Depth vs Magnitude"
set xlabel "Depth (km)"
set ylabel "Magnitude"
set key off
plot "$DATA_DIR/depth_mag.dat" using 1:2 with points pointtype 7 pointsize 0.5
EOF
}

case "${1:-All}" in
    MagTime)       PlotMagTime ;;
    DepthTime)     PlotDepthTime ;;
    MagHist)       PlotMagHist ;;
    DepthHist)     PlotDepthHist ;;
    Locations)     PlotLocations ;;
    LocationsMag)  PlotLocationsMagSize ;;
    CountHour)     PlotCountByHour ;;
    CountMagBand)  PlotCountByMagBand ;;
    Cumulative)    PlotCumulativeCount ;;
    DepthVsMag)    PlotDepthVsMag ;;
    All)
        PlotMagTime
        PlotDepthTime
        PlotMagHist
        PlotDepthHist
        PlotLocations
        PlotLocationsMagSize
        PlotCountByHour
        PlotCountByMagBand
        PlotCumulativeCount
        PlotDepthVsMag
        ;;
    *)
        echo "Usage: $0 [MagTime|DepthTime|MagHist|DepthHist|Locations|LocationsMag|CountHour|CountMagBand|Cumulative|DepthVsMag|All]"
        ;;
esac
