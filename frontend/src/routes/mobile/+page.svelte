<script lang="ts">
  import { dev } from '$app/environment';
  import type { Channel, Ship } from '$lib/api';
  import { api, vote, warships } from '$lib/store';
  import { onMount } from 'svelte';
  import { writable, type Writable } from 'svelte/store';
  import Notification from '$lib/components/Notification.svelte';
    import VoteForShipMobile from '$lib/components/VoteForShipMobile.svelte';

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
    switch (message.type) {
      case 'vote_status': {
        const data = message.data as VoteStatusMessage;

        if (!$vote) {
          if (data.status === 'open') {
            $vote = await $api.getVote(data.id);
          }
          return;
        }


        if ($vote && $vote.status === 'closed') {
          $vote = undefined;
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

<div class="bg-gray-900 min-h-screen p-4">
  {#await $warships then $warships}
    {#if $vote && $vote.status === 'open'}
      <VoteForShipMobile vote={$vote} warships={$warships} />
    {:else}
      <Notification
      title="No vote in progress">
        <p>
          There is no vote in progress. Come back here when the streamer starts a vote.
        </p>
      </Notification>
    {/if}
  {/await}
</div>

