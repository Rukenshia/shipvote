<script lang="ts">
  const dev = import.meta.env.DEV;
  import type { Channel, Ship } from "../../lib/api";
  import { api, vote, warships } from "../../lib/store";
  import { onDestroy, onMount } from "svelte";
  import { writable, type Writable } from "svelte/store";
  import Notification from "../../lib/components/Notification.svelte";
  import VoteForShipMobile from "../../lib/components/VoteForShipMobile.svelte";
  import { fakePubSubVoting, PubSubHandler } from "../../lib/pubsub";

  let channel: Writable<Channel> = writable();
  api.subscribe(async ($api) => {
    if (!$api) {
      return;
    }

    $channel = await $api.getChannelInfo();
  });

  const pubSubHandler = new PubSubHandler();

  onMount(() => {
    pubSubHandler.init();

    if (dev) {
      return fakePubSubVoting();
    }

    return () => {};
  });

  onDestroy(() => {
    pubSubHandler.deinit();
  });
</script>

<div class="min-h-screen bg-gray-900 p-4">
  {#await $warships then $warships}
    {#if $vote && $vote.status === "open"}
      <VoteForShipMobile vote={$vote} warships={$warships} />
    {:else}
      <Notification title="No vote in progress">
        <p>
          There is no vote in progress. Come back here when the streamer starts
          a vote.
        </p>
      </Notification>
    {/if}
  {/await}
</div>
