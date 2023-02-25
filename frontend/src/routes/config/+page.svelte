<script lang="ts">
  import { api, channelId } from '$lib/store';
  import { onMount } from 'svelte';
  import Box from '$lib/components/Box.svelte';
  import ChannelShips from '$lib/components/ChannelShips.svelte';
  import type { Channel, ShipvoteApi } from '$lib/api';
  import { writable, type Writable } from 'svelte/store';

  const channel: Writable<Channel> = writable();
  let exists = false;

  api.subscribe(async ($api: ShipvoteApi) => {
    if (!$api) {
      return;
    }

    channel.set(await $api.broadcasterGetChannel());
  });

  let wows_username = '';
  let wows_realm = '';

  onMount(async () => {
    channel.subscribe(async ($channel) => {
      if (!$channel) {
        exists = false;
        return;
      }
      exists = true;

      wows_username = $channel.wows_username;
      wows_realm = $channel.wows_realm;
    });
  });

  async function updateConfig() {
    $channel = await $api.updateChannelConfig({ ...$channel, wows_username, wows_realm });
  }

  async function createConfig() {
    $channel = await $api.createChannelConfig({
      id: $channelId,
      wows_username,
      wows_realm,
      ships: []
    });
  }

  async function updateShips({ detail: ships }) {
    $channel.ships = ships;
  }
</script>

<div class="flex flex-col gap-4">
  {#if $channel}
    <Box title="Settings">
      <form action="#" method="GET">
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-2">
            <label for="channel-name">WoWS Username</label>
            <input
              id="channel-name"
              type="text"
              bind:value={wows_username}
              class="border rounded px-2 py-1 bg-cyan-900 border-gray-800"
            />
          </div>
          <div class="flex flex-col gap-2">
            <label for="channel-name">WoWS Server</label>
            <select
              id="channel-name"
              bind:value={wows_realm}
              class="border rounded px-2 py-1 bg-cyan-900 border-gray-800"
            >
              <option value="eu">EU</option>
              <option value="na">NA</option>
              <option value="asia">ASIA</option>
            </select>
          </div>
        </div>

        <button
          type="submit"
          class="bg-cyan-900 hover:bg-cyan-800 transition text-gray-200 px-4 py-2 rounded mt-4"
          on:click={updateConfig}>Save</button
        >
      </form>
    </Box>

    <ChannelShips on:update={updateShips} {channel} />
  {:else}
    <Box title="Setup">
      <form action="#" method="GET">
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-2">
            <label for="channel-name">WoWS Username</label>
            <input
              id="channel-name"
              type="text"
              bind:value={wows_username}
              class="border rounded px-2 py-1 bg-cyan-900 border-gray-800"
            />
          </div>
          <div class="flex flex-col gap-2">
            <label for="channel-name">WoWS Server</label>
            <select
              id="channel-name"
              bind:value={wows_realm}
              class="border rounded px-2 py-1 bg-cyan-900 border-gray-800"
            >
              <option value="eu">EU</option>
              <option value="na">NA</option>
              <option value="asia">ASIA</option>
            </select>
          </div>
        </div>

        <button
          type="submit"
          class="bg-cyan-900 hover:bg-cyan-800 transition text-gray-200 px-4 py-2 rounded mt-4"
          on:click={createConfig}>Save</button
        >
      </form>
    </Box>
  {/if}
</div>
