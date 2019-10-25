<template>
    <div v-if="infos"
         v-bind:style="styleObject">
        <div>Total distance: {{ (infos.total_nm  * 1.1).toFixed(0)}}nM</div>
        <div v-if="infos.last_update">Last update: {{ lastUpdate() }}</div>
    </div>

</template>

<script>
    import _ from 'lodash'

    export default {
        data() {
            return {
                infos: null,
                styleObject: {
                    padding: "12px",
                    backgroundColor: '#ffffff',
                    borderRadius: "8px",
                    fontWeight: 600,
                    color: "#333"
                }
            }
        },
        computed: {
        },
        mounted: async function() {
            this.infos = await this.fetchInfos()
        },
        methods: {
            fetchInfos() {
                return axios.get('/infos')
                    .then(res => res.data)
                    .catch(err => console.log(err));
            },
            lastUpdate() { return timeAgo.format(new Date(this.infos.last_update)) }
        }
    }
</script>

