<template>
    <div id="map"></div>
</template>

<script>
    import axios from 'axios'

    let token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'


    export default {
        data() {
            return {
                waypoints: {},
                visibleWaypointsIds: [],
            }
        },
        mounted: function() {
            let text = document.getElementById("map-view").dataset.initial_waypoints;
            this.doStuff(JSON.parse(text));
            this.initMap();
            this.refreshMap(true)
        },
        methods: {

            doStuff: function (data) {
                let mapped = data.reduce((acc, cur) => ({...acc, [cur.id]: cur}), {})
                this.waypoints = {...this.waypoints, ...mapped}
                this.visibleWaypointsIds = data.map(w => w.id)
            },
            fetchWaypoints: function () {
                let bounds = this.map.getBounds();
                console.log("fetching " + bounds);

                axios.get('/waypoints', {
                    params: {
                        bounds,
                    }
                })
                    .then(res => {
                        console.log(res);
                        this.doStuff(res.data);
                        this.refreshMap(false)
                    })
                    .catch(err => console.log(err));

            },
            // will init the map
            initMap: function() {
                this.map = new google.maps.Map(document.getElementById('map'));
                let mapChangedJob = null;

                this.map.addListener('bounds_changed', () => {
                    if (mapChangedJob) clearTimeout(mapChangedJob);
                    mapChangedJob = setTimeout(() => {
                        this.fetchWaypoints()
                    }, 300)
                });
            },
            visibleWaypoints: function () {
                return this.visibleWaypointsIds.map(id => this.waypoints[id])
            },
            refresh_route: function () {
                if (this.route) {
                    this.route.setMap(null)
                }

                let latLngs = this.visibleWaypoints().map(wp => new google.maps.LatLng(wp.latitude, wp.longitude));

                this.route = new google.maps.Polyline({
                    path: latLngs,
                    geodesic: true,
                    strokeColor: '#FF0000',
                    strokeOpacity: 1.0,
                    strokeWeight: 1
                });

                this.route.setMap(this.map);

            }, refreshMap: function(fitBounds) {
                const map = this.map;

                const bounds = new google.maps.LatLngBounds();

                const latLngs = [];

                let waypoints = this.visibleWaypoints()
                const len = waypoints.length;
                for (let i = 0; i < len; i++) {
                    const waypoint = waypoints[i];
                    const latLng = new google.maps.LatLng(waypoint.latitude, waypoint.longitude);
                    latLngs.push(latLng);


                    let infowindow = new google.maps.InfoWindow({
                        content: waypoint.logbook
                    });

                    const marker = new google.maps.Marker({
                        position: latLng,
                        map: map
                    });

                    marker.addListener('click', () => {
                        infowindow.open(map, marker);
                    });

                    //extend the bounds to include each marker's position
                    if (i < len - 1) {
                        bounds.extend(marker.position);
                    }

                }

                if (fitBounds) {
                    //now fit the map to the newly inclusive bounds
                    map.fitBounds(bounds);
                }

                this.refresh_route();
            }
        }
    }
</script>

