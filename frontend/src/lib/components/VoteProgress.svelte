<script lang="ts">
  import type { Channel, Vote } from '$lib/api';
  import { api } from '$lib/store';
  import { onMount } from 'svelte';

  export let channel: Channel;

  let vote: Vote;

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

        if (!vote) {
          if (data.status === 'open') {
            vote = await $api.getVote(data.id);
          }
          return;
        }
        if (data.id === vote.id) {
          vote.status = data.status;
        }
      }
      case 'vote_progress': {
        const data = message.data as VoteProgressMessage;

        if (!vote) {
          vote = await $api.getVote(data.id);
          return;
        }

        if (data.id === vote.id) {
          vote.votes = data.voted_ships;
        }
      }
    }
  }
</script>

{#if vote}
  <div class="absolute left-0 top-0">{vote.id}</div>
{/if}
