<template>
    <div id="map">
        <GmapMap
                ref="mapRef"
                :center="{lat:10, lng:10}"
                style="width: 100%; height: 400px;"
                @bounds_changed="fetchWaypointsAtTimes"
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
                    v-for="(wp, index) in waypoints"
                    :key="wp.id"
                    :position="extrPosition(wp)"
                    :clickable="true"
                    @click="toggleInfoWindow(wp,index)"
                    :icon="getIcon(wp)"
            ></GmapMarker>

            <gmap-polyline
                    v-for="(segment, index) in segments"
                    v-bind:path.sync="segment"
                    v-bind:options="{ strokeColor:'#FF0000', strokeOpacity: .5, geodesic: true,}">
            </gmap-polyline>
        </GmapMap>
    </div>


</template>

<script>
    import axios from 'axios'
    import {gmapApi} from 'vue2-google-maps'
    import _ from 'lodash'

    let token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    axios.defaults.headers.common['X-CSRF-Token'] = token
    axios.defaults.headers.common['Accept'] = 'application/json'

    export default {
        data() {
            return {
                waypoints: {},
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
            segments: function() {
                return this.makeSegments(this.waypoints)
            },
        },
        updated: function() {
            // console.log('updated', this)
        },
        mounted: function() {
            this.fetchWaypoints().then((initialWaypoints) => {
                this.adjustBounds(initialWaypoints);
            })
        },
        methods: {
            getIcon(wp) {
                if (_.isNumber(wp.to_id)) {
                    return {
                        path: google.maps.SymbolPath.CIRCLE,
                    }
                }
                return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Am1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAABJlBMVEX/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD////17FAzAAAAYHRSTlMACWFNGbYaBXLqQyQv0foNX/bSgP6hiXF7SFv9IDH1BAzb3J6+ogrdjoZBgpH0Hmgr+1GnTCVKlA/zUMlpfHeVxLUQR35Ar3/VzfFJKT5sbYHvxsf4hwbBuA4C6AdPja1b0yJJAAAAAWJLR0RhsrBMhgAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB+MGDBc2AufpzDgAAAFsSURBVEjHxdTXUsJAFIDhtWBDQSQooCCiYkGDDbti70ZRmtTz/k8hEBK2Zk5u9Nzu/83OnJ2EkH+YgcEhMuzxjCDz0bFxmCBeAC+un5wC8PnxYDoAADMEDYJau4cQGsx2e5jDgrDZQwQJovNmDws4EIv3+sAiCiSWej0kCQosWz2soEBEs8GqBVIOfWrN7mHdAhubapDu9xC2wNa2UuhxCmRsAEoRonqI9oFK7OzSYI8CCrFP93BAA6nIMhfAIQNk4ggcbpCI4xMWnHJAEBm2Z7YkFWccOBcAK7IaBy5EwIhLroecBNDiigfXMtAXNz4eJKXAFrd8D76EFFjiTgBwLwc98SCCRwUwxZMInlWgK15EoMVUoCMir+J4TfAmOXpXfIIOvxnjQzafAGnpgUHy4Gry5Msd+CZBdyBI9IKbvqATUnQDiu01lcr4vlzqLNZfwfaVH/MpqkYNk9eMqv169Uaz5XGcVrNRJ38zvwM0nY+y9g0BAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE5LTA2LTEyVDIxOjU1OjA2KzAyOjAwK5d/owAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxOS0wNi0xMlQyMTo1NDowMiswMjowMEFHiDIAAAAASUVORK5CYII="
            },
            toggleInfoWindow: function(wp, idx) {
                this.infoWindowPos = this.extrPosition(wp);
                this.infoContent = `[${wp.id}] ${wp.logbook}`;
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
            makeSegments: function (waypoints) {
                let result = [];
                let store = Object.keys(waypoints).map(Number);
                let keys = Object.keys(waypoints).map(Number);

                let froms = keys.reduce((acc, val) => ({...acc, [val]: waypoints[val].from_id}), {});
                let tos = keys.reduce((acc, k) => ({...acc, [froms[k]]: k}), {});

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
                    let r = lefts.concat([seed]).concat(...rights)
                    result.push(r);
                }

                return result
                    .map(wpIds =>
                        wpIds
                            .map(wpId => waypoints[wpId])
                            .map(wp => new this.google.maps.LatLng(wp.latitude, wp.longitude)));
            },
            extrPosition: function (wp) {
                return {lat: wp.latitude, lng: wp.longitude};
            },
            saveData: function (data) {
                let mapped = data.reduce((acc, cur) => ({...acc, [cur.id]: cur}), {});
                this.waypoints = {...this.waypoints, ...mapped};
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
            fetchWaypointsAtTimes: _.debounce(function() {this.fetchWaypoints()}, 300),
            // will init the map
            getVisibleBounds: function (visibWp) {
                const bounds = new this.google.maps.LatLngBounds();
                let i = 0;
                do {
                    let wp = _.nth(visibWp, i);
                    if (wp) {
                        bounds.extend({lat: wp.latitude, lng: wp.longitude});
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

