import { appsignal } from '../../lib/appsignal'
import App from './App.svelte'
import '../../app.css'
import '../../twitch'

const app = new App({
  target: document.getElementById('app'),
})

export default app
