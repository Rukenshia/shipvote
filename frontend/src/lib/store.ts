import { derived, get, readable, type Writable, writable } from 'svelte/store';
import { ShipvoteApi, type Vote } from './api';

export const channelId = writable(null);

export const api = readable(null, (set) => {
  window.Twitch.ext.onAuthorized((data: { channelId: any; token: any }) => {
    channelId.set(data.channelId);

    const token = data.token;

    const api = new ShipvoteApi('http://localhost:4000', token, get(channelId));
    set(api);
  });
  return null;
});

export const warships = derived(api, async ($api: ShipvoteApi) => {
  if (!$api) {
    return new Promise(() => {});
  }

  const ships = await $api.getAllWarships();

  // Turn list into map of [id: string]: ship
  return ships.reduce((acc, ship) => ({ ...acc, [ship.id]: ship }), {});
});

export const vote: Writable<Vote> = writable(null);
