<script lang="ts">
  import type { Channel, Vote } from '$lib/api';
  import VoteProgress from '$lib/components/VoteProgress.svelte';
  import { api } from '$lib/store';
  import { writable, type Writable } from 'svelte/store';

  let channel: Writable<Channel> = writable();

  api.subscribe(async ($api) => {
    if (!$api) {
      return;
    }

    $channel = await $api.getChannelInfo();
  });
</script>

{#if $channel}
  <VoteProgress channel={$channel} />
{/if}
