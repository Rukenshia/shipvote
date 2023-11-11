<script lang="ts">
  const dev = import.meta.env.DEV;

  import { api, channelId } from "../../lib/store";
  import { onMount } from "svelte";
  import Box from "../../lib/components/Box.svelte";
  import ChannelShips from "../../lib/components/ChannelShips.svelte";
  import type { Channel, ShipvoteApi } from "../../lib/api";
  import { writable, type Writable } from "svelte/store";
  import Notification from "../../lib/components/Notification.svelte";

  const channel: Writable<Channel> = writable();
  let loading = true;
  let exists = false;

  api.subscribe(async ($api: ShipvoteApi) => {
    if (!$api) {
      return;
    }

    loading = true;

    try {
    channel.set(await $api.broadcasterGetChannel());
    } catch (e) {
      console.error(e);
    }

    loading = false;
  });

  let wows_username = "";
  let wows_realm = "eu";

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
    $channel = await $api.updateChannelConfig({
      ...$channel,
      wows_username,
      wows_realm,
    });
  }

  async function createConfig() {
    $channel = await $api.createChannelConfig({
      id: $channelId,
      wows_username,
      wows_realm,
      ships: [],
    });
  }

  async function updateShips({ detail: ships }) {
    $channel.ships = ships;
  }
</script>

<div class="flex flex-col gap-4">
  {#if loading}
    <Notification type="info" title="Loading">
      <p>Please wait while we load your configuration</p>
    </Notification>
  {:else}
    {#if !exists}
      <Notification type="info" title="No configuration found">
        <p>
          Please enter your World of Warships account information below to get
          started
        </p>
      </Notification>
    {/if}

    {#if $channel}
      <Box title="Settings">
        <form on:submit={(e) => { e.preventDefault(); }}>
          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-2">
              <label for="channel-name">WoWS Username</label>
              <input
                id="channel-name"
                type="text"
                bind:value={wows_username}
                placeholder="Your WoWS username"
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
        <form on:submit={(e) => { e.preventDefault(); }}>
          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-2">
              <label for="channel-name">WoWS Username</label>
              <input
                id="channel-name"
                type="text"
                bind:value={wows_username}
                placeholder="Your WoWS username"
                class="border placeholder-cyan-700/90 rounded px-2 py-1 bg-cyan-900 border-gray-800"
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
  {/if}

  <Box>
    If you have any problems configuring this extension, please contact me on
    Discord(Rukenshia#4396) or via Mail (svc-shipvote@ruken.pw)
  </Box>
</div>
