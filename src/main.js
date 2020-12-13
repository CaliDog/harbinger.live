import Vue from 'vue';
import Sparkline from 'vue-sparklines'

import App from './App.vue';
import router from './router';

Vue.use(Sparkline)

Vue.config.productionTip = false;

const store = new Vue({
  data() {
    return window.ctx
  },
})

Vue.prototype.$store = store.$data
Vue.prototype.$bus = store

window.VUE = new Vue({
  router,
  render: (h) => h(App),
}).$mount('#app');
