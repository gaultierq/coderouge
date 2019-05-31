import Vue from 'vue/dist/vue.js';
import MapView from 'view/map';

new Vue({
    el: '#map-view',
    components: {
        'map-view': MapView
    }
});
