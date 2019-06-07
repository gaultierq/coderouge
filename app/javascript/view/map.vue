<template>
    <div id="map">
        <GmapMap
                ref="mapRef"
                :center="{lat:10, lng:10}"
                map-type-id="terrain"
                style="width: 100%; height: 400px;"
        >
            <gmap-info-window
                    :options="infoOptions"
                    :position="infoWindowPos"
                    :opened="infoWinOpen"
                    @closeclick="infoWinOpen=false"
            >
                {{infoContent}}
            </gmap-info-window>

            <GmapMarker
                    :key="index"
                    v-for="(m, index) in markers"
                    :position="m.position"
                    :clickable="true"
                    @click="toggleInfoWindow(m,index)"
            ></GmapMarker>
        </GmapMap>
    </div>

</template>

<script>
    import axios from 'axios'
    import {gmapApi} from 'vue2-google-maps'

    let token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'


    export default {
        data() {
            return {
                waypoints: {},
                visibleWaypointsIds: [],
                segments: [],
                markers: [],
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
            google: gmapApi
        },
        mounted: function() {
            let text = document.getElementById("map-view").dataset.initial_waypoints;
            this.refreshData(JSON.parse(text));
            this.initMap();
            this.fitBounds(true);
            this.refreshRoutes()
        },
        methods: {
            toggleInfoWindow: function(marker, idx) {
                this.infoWindowPos = marker.position;
                this.infoContent = marker.logbook;
                //check if its the same marker that was selected if yes toggle
                if (this.currentMidx == idx) {
                    this.infoWinOpen = !this.infoWinOpen;
                }
                //if different marker set infowindow to open and reset current marker index
                else {
                    this.infoWinOpen = true;
                    this.currentMidx = idx;
                }
            },
            makeSegments: function (waypoints) {
                let result = [];
                let store = Object.keys(waypoints);

                let keys = Object.keys(waypoints);
                let froms = keys.reduce((acc, val) => ({...acc, [val]: waypoints[val].from_id}), {})
                let tos = {};
                for (let k in froms) {
                    let v = froms[k];
                    tos[v] = k
                }

                let getTip = (tipStore, seed) => {
                    let res1 = [];
                    {
                        //left
                        let currId = seed;
                        for (;;) {
                            let fromId = tipStore[currId];
                            let ix = store.indexOf(fromId);
                            if (ix < 0) break;
                            currId = store.splice(ix, 1);
                            res1.push(currId)
                        }
                    }
                    return res1
                };

                while (store.length > 0) {
                    let seed = store.shift();
                    let lefts = getTip(froms, seed).reverse();
                    let rights = getTip(tos, seed);
                    let r = lefts.concat([seed]).concat(rights)
                    result.push(r);
                }

                return result
            }, refreshData: function (data) {
                let mapped = data.reduce((acc, cur) => ({...acc, [cur.id]: cur}), {});
                this.waypoints = {...this.waypoints, ...mapped};
                this.markers = Object.values(this.waypoints).map(wp => (
                        {
                            position: {lat: parseFloat(wp.latitude), lng: parseFloat(wp.longitude)},
                            logbook: wp.logbook
                        }
                    )
                );
                this.visibleWaypointsIds = data.map(w => w.id);



                //array of segments
                this.segments = this.makeSegments(this.waypoints);

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
                        this.refreshData(res.data);
                        this.refreshRoutes()
                    })
                    .catch(err => console.log(err));

            },
            // will init the map
            initMap: async function() {
                this.map = await this.$refs.mapRef.$mapPromise;
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
            refreshRoutes: async function () {
                (await this.$gmapApiPromiseLazy());
                this.segments.forEach(segment => {
                    let latLngs = segment.map(wpId => this.waypoints[wpId]).map(wp => new this.google.maps.LatLng(wp.latitude, wp.longitude));

                    let route = new this.google.maps.Polyline({
                        path: latLngs,
                        geodesic: true,
                        strokeColor: '#FF0000',
                        strokeOpacity: 1.0,
                        strokeWeight: 1
                    });

                    route.setMap(this.map);
                });

            }, getVisibleBounds: function (map) {
                const bounds = new this.google.maps.LatLngBounds();

                const latLngs = [];

                let visibWp = this.visibleWaypoints();

                const len = visibWp.length;
                for (let i = 0; i < len; i++) {
                    const wp = visibWp[i];
                    const latLng = new this.google.maps.LatLng(wp.latitude, wp.longitude);
                    latLngs.push(latLng);

                    //extend the bounds to include each marker's position
                    if (i < len - 1) {
                        bounds.extend({lat: parseFloat(wp.latitude), lng: parseFloat(wp.longitude)});
                    }

                }
                return bounds;
            },
            fitBounds: async function() {

                (await this.$gmapApiPromiseLazy())
                const map = await this.$refs.mapRef.$mapPromise;
                const bounds = this.getVisibleBounds(map);
                //now fit the map to the newly inclusive bounds
                map.fitBounds(bounds);

            }
        }
    }
</script>

