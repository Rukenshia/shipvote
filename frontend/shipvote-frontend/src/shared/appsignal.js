import Appsignal from "@appsignal/javascript"
import { errorHandler } from "@appsignal/vue"
import { plugin } from "@appsignal/plugin-breadcrumbs-network"

window.appsignal = new Appsignal({
  key: "9765df9f-9098-4d43-ba8b-8d71c38f066f"
});

window.appsignal.use(plugin());

window.errorHandler = errorHandler;

export default window.appsignal;
