<template>
  <div id="app">
    <router-view/>
  </div>
</template>

<script>
import ReconnectingWebSocket from 'reconnecting-websocket'

export default {
  name: 'App',
  mounted() {
    this.ws = new ReconnectingWebSocket(`${((window.location.protocol === 'https:') ? 'wss://' : 'ws://') + window.location.host}/ws/`);
    this.ws.onmessage = (message) => {
      this.$bus.$emit('message', message.data)
    }

    // Heartbeat/keepalive
    setInterval(() => { this.ws.send('.') }, 10 * 1000)
  },
  methods: {
  },
  data() {
    return {
      ws: null,
    };
  },
};
</script>

<style lang="scss">
  @import '../node_modules/bulma/bulma';

</style>
