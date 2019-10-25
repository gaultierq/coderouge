<template>
    <div id="map">
        <info style='position: absolute; z-index: 1000; margin: 1%;'></info>
        <GmapMap
                ref="mapRef"
                :center="{lat:10, lng:10}"
                style="width: 100%; height: 350px;"
                mapTypeId="terrain"
                :options="{
                          zoomControl: true,
                          mapTypeControl: false,
                          scaleControl: false,
                          streetViewControl: false,
                          rotateControl: false,
                          fullscreenControl: false,
                        }"
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
                    v-if="zoom > 3"
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

    import {gmapApi} from 'vue2-google-maps'
    import _ from 'lodash'

    // Create relative date/time formatter.
    const DAY_S = 24 * 3600;

    export default {
        data() {
            return {
                zoom: 2,
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

                this.$refs.mapRef.$on('zoom_changed', zoom => {
                    this.zoom = zoom
                });

                this.fetchStopovers();
                this.fetchPoly().then(poly => {
                    this.adjustBounds(poly);
                });
                this.fetchLastPosition()
                    .then(last => {
                        this.last_waypoint = last;
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
                return {
                    url: __FLAG_PNG__,
                    scaledSize: new this.google.maps.Size(20, 20),
                    origin: new this.google.maps.Point(0,0), // origin
                    anchor: new this.google.maps.Point(5, 20) // anchor
                };
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
                // let $mapObject = this.$refs.mapRef.$mapObject;
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
            fetchLastPosition: function () {
                return axios.get('/waypoints/last_position')
                    .then(res => res.data)
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

