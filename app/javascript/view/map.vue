<template>
    <div id="map">
        <GmapMap
                ref="mapRef"
                :center="{lat:10, lng:10}"
                style="width: 100%; height: 350px;"
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
            this.fetchStopovers();
            this.fetchPoly().then(poly => {
                this.adjustBounds(poly);
            });
            this.fetchWaypoints()
                .then(initialWaypoints => {
                    this.last_waypoint = _.first(initialWaypoints);
                    if (this.last_waypoint) {
                        this.toggleInfoWindow(this.last_waypoint, this.last_waypoint.id)
                    }

                })
        },
        methods: {
            getBoatIcon() {
                return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAABJlBMVEX/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD////17FAzAAAAYHRSTlMACWFNGbYaBXLqQyQv0foNX/bSgP6hiXF7SFv9IDH1BAzb3J6+ogrdjoZBgpH0Hmgr+1GnTCVKlA/zUMlpfHeVxLUQR35Ar3/VzfFJKT5sbYHvxsf4hwbBuA4C6AdPja1b0yJJAAAAAWJLR0RhsrBMhgAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB+MGDBc2AufpzDgAAAFsSURBVEjHxdTXUsJAFIDhtWBDQSQooCCiYkGDDbti70ZRmtTz/k8hEBK2Zk5u9Nzu/83OnJ2EkH+YgcEhMuzxjCDz0bFxmCBeAC+un5wC8PnxYDoAADMEDYJau4cQGsx2e5jDgrDZQwQJovNmDws4EIv3+sAiCiSWej0kCQosWz2soEBEs8GqBVIOfWrN7mHdAhubapDu9xC2wNa2UuhxCmRsAEoRonqI9oFK7OzSYI8CCrFP93BAA6nIMhfAIQNk4ggcbpCI4xMWnHJAEBm2Z7YkFWccOBcAK7IaBy5EwIhLroecBNDiigfXMtAXNz4eJKXAFrd8D76EFFjiTgBwLwc98SCCRwUwxZMInlWgK15EoMVUoCMir+J4TfAmOXpXfIIOvxnjQzafAGnpgUHy4Gry5Msd+CZBdyBI9IKbvqATUnQDiu01lcr4vlzqLNZfwfaVH/MpqkYNk9eMqv169Uaz5XGcVrNRJ38zvwM0nY+y9g0BAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE5LTA2LTEyVDIxOjU1OjA2KzAyOjAwK5d/owAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxOS0wNi0xMlQyMTo1NDowMiswMjowMEFHiDIAAAAASUVORK5CYII="
            },
            getStopoverIcon(so) {
                let scale = 0;
                if (so.duration_s > 15 * DAY_S) {
                    scale = 20
                }
                else if (so.duration_s > 7 * DAY_S) {
                    scale = 10
                }
                else if (so.duration_s > 3 * DAY_S) {
                    scale = 5
                }
                else if (so.duration_s > 1 * DAY_S) {
                    scale = 3
                }
                else {
                    scale = 1
                }

                return {
                    path: this.google.maps.SymbolPath.CIRCLE,
                    strokeColor: 'red',
                    strokeWeight: 4,
                    strokeOpacity: 0.4,
                    strokeWidth: 5,
                    scale
                }
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
                if (!this.google || !encoded || !this.google.maps.geometry) return null;
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
                // let bounds = $mapObject && $mapObject.getBounds();
                // console.log("fetching " + bounds);

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

