<template>
  <div id="map"></div>
</template>

<script>
    export default {
        data: function() {
            return ({
                csrf: document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            })
        },
        mounted: function() {
            initMap([])
        }
    }
</script>

