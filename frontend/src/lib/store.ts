import { derived, get, readable, Writable, writable } from 'svelte/store';
import { ShipvoteApi, Vote } from './api';
import type { Channel } from './api';

export const channelId = writable(null);
export const vote: Writable<Promise<Vote>> = writable(new Promise(() => {}));

export const api = readable(null, (set) => {
  window.Twitch.ext.onAuthorized((data: { channelId: any; token: any }) => {
    channelId.set(data.channelId);

    const token = data.token;

    const api = new ShipvoteApi('http://localhost:4000', token, get(channelId));
    set(api);

    vote.set(api.getOpenVote());
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

export const channel = derived(api, ($api: ShipvoteApi): Promise<Channel> => {
  if (!$api) {
    return new Promise(() => {});
  }

  return $api.broadcasterGetChannel();
});
