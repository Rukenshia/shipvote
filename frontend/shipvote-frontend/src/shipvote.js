export const BASE_URL = "https://shipvote.in.fkn.space";
export const BASE_WS_URL = "wss://shipvote.in.fkn.space";
// export const BASE_URL = 'http://localhost:4000';
// export const BASE_WS_URL = 'ws://localhost:4000';
// export const BASE_URL = 'http://100.115.92.198:4000';
// export const BASE_WS_URL = 'ws://100.115.92.198:4000';

export { ShipvoteApi } from './api.js';

// Remove comments from the below to enable simulation
import * as twitchMock from './twitch_mock.js';

setTimeout(() => {
  window.simulateTwitch();
}, 500);
