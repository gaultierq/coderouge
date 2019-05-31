<template>
    <div id="map"></div>
</template>

<script>
    export default {
        mounted: function() {
            debugger;
            let text = document.getElementById("map-view").dataset.initial_waypoints;

            let waypoints = JSON.parse(text);
            this.initMap(waypoints)
        },
        methods: {
            // will init the map from the last 5 positions
            initMap: lastPositions => {

                const map = new google.maps.Map(document.getElementById('map'));

                const bounds = new google.maps.LatLngBounds();
                const infowindow = new google.maps.InfoWindow();

                const latLngs = [];

                const len = lastPositions.length;
                for (let i = 0; i < len; i++) {
                    const pos = lastPositions[i];
                    const latLng = new google.maps.LatLng(pos.latitude, pos.longitude);
                    latLngs.push(latLng);

                    const marker = new google.maps.Marker({
                        position: latLng,
                        map: map
                    });

                    //extend the bounds to include each marker's position
                    if (i < len - 1) {
                        bounds.extend(marker.position);
                    }

                    //??
                    google.maps.event.addListener(marker, 'click', (function(marker, i) {
                        return function() {
                            infowindow.setContent(locations[i][0]);
                            infowindow.open(map, marker);
                        }
                    })(marker, i));
                }

                //now fit the map to the newly inclusive bounds
                map.fitBounds(bounds);

                const line = new google.maps.Polyline({
                    path: latLngs,
                    geodesic: true,
                    strokeColor: '#FF0000',
                    strokeOpacity: 1.0,
                    strokeWeight: 1
                });

                line.setMap(map);

            }
        }

    }


</script>

