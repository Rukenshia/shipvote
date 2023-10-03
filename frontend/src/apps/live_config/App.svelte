<script lang="ts">
  const dev = import.meta.env.DEV;
  import { onMount } from "svelte";
  import { slide } from "svelte/transition";

  import NewVote from "../../lib/components/NewVote.svelte";
  import VoteStatus from "../../lib/components/VoteStatus.svelte";
  import VoteHistory from "../../lib/components/VoteHistory.svelte";
  import Link from "../../lib/components/Link.svelte";
  import { api, vote } from "../../lib/store";
  import Box from "../../lib/components/Box.svelte";
  import type { Vote } from "../../lib/api";
  import { fakePubSubVoting, registerPubSubHandler } from "../../lib/pubsub";
  import {
    derived,
    type Readable,
    type Writable,
    writable,
  } from "svelte/store";
  import CreatorBanner from "../../lib/components/CreatorBanner.svelte";
  import ExpandableBox from "../../lib/components/ExpandableBox.svelte";

  let showNewVote = false;

  onMount(() => {
    registerPubSubHandler();

    if (dev) {
      return fakePubSubVoting();
    }

    return () => {};
  });

  const closedVotes: Writable<Promise<Vote[]>> = writable(
    new Promise(() => {})
  );

  $: if ($api) {
    $api.getOpenVote().then((v) => ($vote = v));
    $closedVotes = $api.getClosedVotes();
  }

  function navigate(e: CustomEvent<{ name: string }>) {
    e.preventDefault();

    if (e.detail.name === "new_vote") {
      showNewVote = true;
    }
  }
</script>

<div class="flex flex-col gap-4" transition:slide={{ duration: 300 }}>
  {#if showNewVote}
    <NewVote
      on:back={() => (showNewVote = false)}
      on:vote_opened={() => (showNewVote = false)}
    />
  {:else}
    <div transition:slide={{ duration: 100 }} class="flex flex-col gap-4">
      <Link
        on:navigate={navigate}
        name="new_vote"
        classes="bg-cyan-900 hover:bg-cyan-800"
        disabled={$vote !== undefined}>New Vote</Link
      >
      <VoteStatus
        on:close={async () => ($closedVotes = await $api.getClosedVotes())}
      />
      <Box>
        <VoteHistory votes={closedVotes} />
      </Box>

      <ExpandableBox title="Changelog">
        <div class="flex flex-col gap-2">
          <h3 class="font-bold text-xl">v3.0.0</h3>
          <div class="text-gray-400 prose">
            <p>
              This version is a complete rewrite of the previous interface. It
              hopefully lays some groundwork for upcoming improvements. This
              version is more or less on par with the previous version
              feature-wise, although I had to remove the timer functionality for
              now.
            </p>
            <p>
              Please let me know if you encounter any problems or are missing
              any features - I am happy to take feature requests!
            </p>
          </div>
        </div>
      </ExpandableBox>
      <Box>
        <CreatorBanner />
      </Box>
    </div>
  {/if}
</div>
