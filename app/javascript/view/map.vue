<template>
    <div id="map">
        <GmapMap
                ref="mapRef"
                :center="{lat:10, lng:10}"
                style="width: 100%; height: 350px;"
                mapTypeId="terrain"
        >
            <gmap-info-window
                    :options="infoOptions"
                    :position="infoWindowPos"
                    :opened="infoWinOpen"
                    @closeclick="infoWinOpen=false"
            >
                <div v-html="infoContent"></div>
            </gmap-info-window>

            <!-- current position -->
            <GmapMarker
                    v-if="this.last_waypoint"
                    :position="extrPosition(this.last_waypoint)"
                    :clickable="false"
                    :icon="getBoatIcon()"
            ></GmapMarker>

            <!-- stopovers -->
            <GmapMarker
                    v-for="(so, index) in stopovers"
                    :key="index"
                    :position="extrPosition(so)"
                    :clickable="false"
                    :icon="getStopoverIcon(so)"
            ></GmapMarker>

            <gmap-polyline
                    v-bind:path.sync="polyline"
                    v-bind:options="{ strokeColor:'#ff0000', strokeOpacity: 0.5, geodesic: true,}">
            </gmap-polyline>

        </GmapMap>
    </div>

</template>

<script>
    import axios from 'axios'
    import {gmapApi} from 'vue2-google-maps'
    import _ from 'lodash'
    import TimeAgo from 'javascript-time-ago'
    // Load locale-specific relative date/time formatting rules.
    import fr from 'javascript-time-ago/locale/en'

    let token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'

    // Add locale-specific relative date/time formatting rules.
    TimeAgo.addLocale(fr);
    // Create relative date/time formatter.
    const timeAgo = new TimeAgo('fr-FR');
    const DAY_S = 24 * 3600;

    export default {
        data() {
            return {
                last_waypoint: null,
                encodedPolyline: null,
                stopovers: [],
                infoContent: '',
                infoWindowPos: null,
                infoWinOpen: false,
                currentMidx: null,
                //optional: offset infowindow so it visually sits nicely on top of our marker
                infoOptions: {
                    pixelOffset: {
                        width: 0,
                        height: -35
                    }
                },
            }
        },
        computed: {
            google: gmapApi,
            // segments: function() {
            //     return this.makeSegments(this.waypoints)
            // },
            polyline: function() {
                return this.decodePolyline(this.encodedPolyline)
            },
        },
        updated: function() {
            // console.log('updated', this)
        },
        mounted: function() {
            this.$refs.mapRef.$mapPromise.then(() => {
                this.fetchStopovers();
                this.fetchPoly().then(poly => {
                    this.adjustBounds(poly);
                });
                this.fetchWaypoints()
                    .then(initialWaypoints => {
                        this.last_waypoint = _.first(initialWaypoints);
                        // if (this.last_waypoint) {
                        //     this.toggleInfoWindow(this.last_waypoint, this.last_waypoint.id)
                        // }
                    })
            })

        },
        methods: {
            getBoatIcon() {
                if (!this.google) return null;
                return {
                    url: __BOAT_SVG__,
                    scaledSize: new this.google.maps.Size(60, 60),
                    origin: new this.google.maps.Point(0,0), // origin
                    anchor: new this.google.maps.Point(30, 55) // anchor
                };
            },
            getStopoverIcon(so) {
                if (!this.google) return null;
                return {
                    url: __FLAG_PNG__,
                    scaledSize: new this.google.maps.Size(20, 20),
                    origin: new this.google.maps.Point(0,0), // origin
                    anchor: new this.google.maps.Point(5, 20) // anchor
                };
                // let scale = 0;
                // if (so.duration_s > 15 * DAY_S) {
                //     scale = 20
                // }
                // else if (so.duration_s > 7 * DAY_S) {
                //     scale = 10
                // }
                // else if (so.duration_s > 3 * DAY_S) {
                //     scale = 5
                // }
                // else if (so.duration_s > 1 * DAY_S) {
                //     scale = 3
                // }
                // else {
                //     scale = 1
                // }
                // scale /= 50.;
                // scale = 0.0171875;
                //
                //
                // var hi = "M2425 9544 c-64 -33 -102 -88 -141 -204 -18 -53 -19 -175 -22 -3662 l-2 -3608 97 0 c54 0 162 -3 241 -7 l142 -6 1 1009 c1 901 9 1434 19 1204 4 -110 5 -118 29 -203 32 -117 70 -160 107 -123 8 9 19 16 23 16 4 0 29 21 55 46 103 98 244 185 382 234 81 28 245 70 419 106 11 2 34 7 50 11 17 4 32 7 35 8 3 1 25 5 50 9 70 13 397 90 595 141 99 25 190 48 201 50 12 3 51 14 85 24 56 17 101 29 134 36 23 6 133 38 170 50 45 14 155 47 170 51 87 20 753 249 895 308 36 15 72 29 80 31 14 3 211 82 423 169 97 39 278 118 372 162 33 15 63 28 66 28 13 2 496 230 764 361 205 101 649 330 825 427 36 19 121 66 190 103 659 359 886 499 1015 630 120 122 101 171 -81 208 -12 2 -30 0 -40 -6 -13 -6 -16 -6 -9 0 6 6 208 131 450 278 242 147 446 273 454 280 10 10 11 20 2 47 l-11 34 -198 -23 c-419 -48 -897 -87 -1427 -115 -302 -16 -1345 -16 -1635 0 -1252 68 -2218 228 -3044 503 -666 222 -1164 496 -1535 845 l-81 76 0 92 c0 174 -57 320 -145 371 -49 29 -124 33 -170 9z";
                // return {
                //     path: hi, //this.google.maps.SymbolPath.CIRCLE,
                //     // anchor: new google.maps.Point(200, 400),
                //     strokeColor: 'red',
                //     strokeWeight: 2,
                //     // strokeOpacity: 0.6,
                //     strokeWidth: 5,
                //     scale
                // }
            },
            getInfoContent: function (wp) {
                return `<p>
                            <b>${this.niceDate(new Date(wp.date))}</b><br>
                            ${this.agoDate(new Date(wp.date))}
                        <\p>
                        <p>
                            ${wp.logbook || ""}
                            <br>#${wp.id}
                            </p>`;
            },
            decodePolyline(encoded) {
                if (!this.google || !encoded || !this.google.maps.geometry) return [];
                return this.google.maps.geometry.encoding.decodePath(encoded);
            },
            toggleInfoWindow: function(wp, idx) {
                this.infoWindowPos = this.extrPosition(wp);
                this.infoContent = this.getInfoContent(wp);
                //check if its the same marker that was selected if yes toggle
                if (this.currentMidx === idx) {
                    this.infoWinOpen = !this.infoWinOpen;
                }
                //if different marker set infowindow to open and reset current marker index
                else {
                    this.infoWinOpen = true;
                    this.currentMidx = idx;
                }
            },
            extrPosition: function (wp) {
                return {lat: wp.latitude, lng: wp.longitude};
            },
            saveData: function (data) {
                let mapped = data.reduce((acc, cur) => ({...acc, [cur.id]: cur}), {});
                // this.waypoints = {...this.waypoints, ...mapped};
            },
            niceDate: function (date) {
                const months = ["JAN", "FEB", "MAR","APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
                let formatted_date = date.getDate() + "-" + months[date.getMonth()] + "-" + date.getFullYear()
                return formatted_date
            },
            agoDate: function (date) {
                return timeAgo.format(date)
            },
            fetchStopovers: function () {
                //fetching the stopovers
                axios.get('/stopovers').then(res => {
                    this.stopovers = res.data
                }).catch(err => console.log(err));
            },
            fetchPoly: function () {
                let $mapObject = this.$refs.mapRef.$mapObject;

                //fetching the polyline
                let bounds = {
                    "south": -90,
                    "west": -180,
                    "north": 90,
                    "east": 180
                };
                return axios.get('/waypoints/polyline', {
                        params: {
                            bounds
                        }
                    }
                ).then(res => {
                    this.encodedPolyline = res.data;
                    return this.decodePolyline(res.data);
                }).catch(err => console.log(err));
            },
            fetchWaypoints: function () {
                let $mapObject = this.$refs.mapRef.$mapObject;
                let bounds = $mapObject && $mapObject.getBounds();
                console.log("fetching " + bounds);


                return axios.get('/waypoints', {
                    params: {
                        bounds,
                    }
                })
                    .then(res => {
                        console.log("fetch result:", res);
                        this.saveData(res.data);
                        // this.refreshRoutes()
                        return res.data
                    })
                    .catch(err => console.log(err));
            },
            debouncedFetchPoly: _.debounce(function() {this.fetchPoly()}, 300),
            // will init the map
            getVisibleBounds: function (visibWp) {
                const bounds = new this.google.maps.LatLngBounds();
                let i = 0;
                do {
                    let wp = _.nth(visibWp, i);
                    if (wp) {
                        // bounds.extend({lat: wp.latitude, lng: wp.longitude});
                        bounds.extend(wp);
                    }
                } while (++i < visibWp.length - 1);
                return bounds;
            },
            adjustBounds: async function(waypoints) {
                const map = await this.$refs.mapRef.$mapPromise;
                const bounds = this.getVisibleBounds(waypoints);
                map.fitBounds(bounds);
            }
        }
    }
</script>

