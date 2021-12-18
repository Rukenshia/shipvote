window.Vue.use(window.VueMDCAdapter)

Vue.config.errorHandler = window.errorHandler(window.appsignal, Vue)

new window.Vue({
  el: '#app',
  render: h => h(window.App)
})
