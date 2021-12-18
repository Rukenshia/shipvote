import { derived, get, readable, writable } from 'svelte/store';
import { ShipvoteApi } from './api';
import type { Ship } from './api';

export const channelId = writable(null);

export const api = readable(null, (set) => {
  window.Twitch.ext.onAuthorized((data: { channelId: any; token: any }) => {
    channelId.set(data.channelId);

    const token = data.token;

    set(
      new ShipvoteApi('https://shipvote.in.fkn.space', token, get(channelId))
    );
  });
  return null;
});

export const warships = derived(api, ($api: ShipvoteApi) => {
  if (!$api) {
    return new Promise(() => {});
  }

  return $api.getAllWarships().then((ships: Ship[]) => ships.reduce((acc, ship) => ({ ...acc, [ship.id]: ship}), {}));
});
