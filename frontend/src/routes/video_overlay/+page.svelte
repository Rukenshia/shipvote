<script lang="ts">
  import { dev } from '$app/environment';
  import type { Channel, Ship, Vote } from '$lib/api';
  import VoteForShip from '$lib/components/VoteForShip.svelte';
  import VoteProgressOverlay from '$lib/components/VoteProgressOverlay.svelte';
  import { api, vote, warships } from '$lib/store';
  import { onMount } from 'svelte';
  import { writable, type Writable } from 'svelte/store';
  import { scale } from 'svelte/transition';

  let channel: Writable<Channel> = writable();
  api.subscribe(async ($api) => {
    if (!$api) {
      return;
    }

    $channel = await $api.getChannelInfo();
  });

  let hidden = false;

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

  if (dev) {
    setInterval(async () => {
      if (!$api) {
        return;
      }

      if ($vote && $vote.status === 'open') {
        $vote = await $api.getVote($vote.id);

        if ($vote.status === 'closed') {
          window.Twitch.ext.send('broadcast', 'application/json', {
            type: 'vote_status',
            data: { id: $vote.id, status: 'closed' }
          });

          return;
        }

        window.Twitch.ext.send('broadcast', 'application/json', {
          type: 'vote_progress',
          data: { id: $vote.id, voted_ships: $vote.votes }
        });

        return;
      }

      $vote = await $api.getOpenVote();
      console.log($vote);
    }, 1000);
  }
</script>

{#await $warships then $warships}
  {#if $vote}
    {#if $vote.status === 'open'}
      <div class="fixed left-0 top-0">
        <VoteProgressOverlay {vote} warships={$warships} />
      </div>
      {#if !hidden}
        <div class="flex h-screen w-full">
          <div in:scale out:scale class="relative group max-w-2xl m-auto">
            <div
              class="absolute -inset-1 bg-gradient-to-r from-cyan-200 to-cyan-400 rounded-lg blur opacity-100 group-hover:opacity-100 transition duration-1000 group-hover:duration-200"
            />
            <div class="bg-cyan-900 text-white p-4 rounded-lg drop-shadow-lg">
              <VoteForShip vote={$vote} warships={$warships} close={() => (hidden = true)} />
            </div>
          </div>
        </div>
      {/if}
    {/if}
  {/if}
{/await}
