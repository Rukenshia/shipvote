import Vue from 'vue'
import { Socket } from 'phoenix'
import App from './App.vue'
import VueMDCAdapter from 'vue-mdc-adapter'
Vue.use(VueMDCAdapter)

new Vue({
  el: '#app',
  render: h => h(App)
})
