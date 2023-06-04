<script lang="ts">
  import type { Channel, Vote } from '$lib/api';
  import { api, vote } from '$lib/store';
  import { onMount } from 'svelte';
  import { writable, type Writable } from 'svelte/store';

  let channel: Writable<Channel> = writable();
  api.subscribe(async ($api) => {
    if (!$api) {
      return;
    }

    $channel = await $api.getChannelInfo();
  });

  interface VoteStatusMessage {
    id: number;
    status: 'open' | 'closed';
  }

  interface VoteProgressMessage {
    id: number;
    voted_ships: { [key: number]: number };
  }

  interface Message {
    type: 'vote_status' | 'vote_progress';
    data: VoteStatusMessage | VoteProgressMessage;
  }

  onMount(async () => {
    window.Twitch.ext.listen('broadcast', (target, contentType, message) => {
      if (contentType !== 'application/json') {
        return;
      }
      const data = JSON.parse(atob(message));
      handlePubSubMessage(data);
    });
  });

  async function handlePubSubMessage(message: Message) {
    console.log(message);
    switch (message.type) {
      case 'vote_status': {
        const data = message.data as VoteStatusMessage;

        if (!$vote) {
          if (data.status === 'open') {
            $vote = await $api.getVote(data.id);
          }
          return;
        }
        if (data.id === $vote.id) {
          $vote.status = data.status;
        }
      }
      case 'vote_progress': {
        const data = message.data as VoteProgressMessage;

        if (!$vote) {
          $vote = await $api.getVote(data.id);
          return;
        }

        if (data.id === $vote.id) {
          $vote.votes = data.voted_ships;
        }
      }
    }
  }
</script>

{#if $vote}
  <div class="p-48">
    <div class="relative group">
      <div
        class="absolute -inset-1 bg-gradient-to-r from-cyan-200 to-cyan-400 rounded-lg blur opacity-100 group-hover:opacity-100 transition duration-1000 group-hover:duration-200"
      />
      <div class="bg-cyan-900 text-white p-8 rounded-lg drop-shadow-lg">
        <h1 class="text-2xl font-bold">Vote Status</h1>
        <p class="text-lg">Vote ID: {$vote.id}</p>
        <p class="text-lg">Status: {$vote.status}</p>
        <p class="text-lg">Ships:</p>
        <ul class="list-disc list-inside">
          {#each Object.entries($vote.votes) as [ship, votes]}
            <li class="text-lg">{ship}: {votes}</li>
          {/each}
        </ul>
      </div>
    </div>
  </div>
{/if}
