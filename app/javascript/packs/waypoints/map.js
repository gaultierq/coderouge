import Vue from 'vue/dist/vue.js';
import * as VueGoogleMaps from 'vue2-google-maps'

import axios from 'axios'
let token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
axios.defaults.headers.common['X-CSRF-Token'] = token
axios.defaults.headers.common['Accept'] = 'application/json'
window.axios = axios



import TimeAgo from 'javascript-time-ago'
// Load locale-specific relative date/time formatting rules.
import fr from 'javascript-time-ago/locale/en'
// Add locale-specific relative date/time formatting rules.
TimeAgo.addLocale(fr);
window.timeAgo = new TimeAgo('fr-FR');

import MapView from 'view/map';
import Info from 'view/info';
Vue.component('info', Info)

Vue.use(VueGoogleMaps, {
    load: {
        key: __GOOGLE_MAP_API_KEY__,
        libraries: 'places,geometry', // This is required if you use the Autocomplete plugin
        // OR: libraries: 'places,drawing'
        // OR: libraries: 'places,drawing,visualization'
        // (as you require)

        //// If you want to set the version, you can do so:
        // v: '3.26',
    },

    //// If you intend to programmatically custom event listener code
    //// (e.g. `this.$refs.gmap.$on('zoom_changed', someFunc)`)
    //// instead of going through Vue templates (e.g. `<GmapMap @zoom_changed="someFunc">`)
    //// you might need to turn this on.
    // autobindAllEvents: false,

    //// If you want to manually install components, e.g.
    //// import {GmapMarker} from 'vue2-google-maps/src/components/marker'
    //// Vue.component('GmapMarker', GmapMarker)
    //// then disable the following:
    // installComponents: true,
});

new Vue({
    el: '#map-view', //exact

    //registering components
    components: {
        'map-view': MapView,
    }
});

