<script lang="ts">
  const dev = import.meta.env.DEV;
  import { onMount, onDestroy } from "svelte";
  import { slide } from "svelte/transition";

  import NewVote from "../../lib/components/NewVote.svelte";
  import VoteStatus from "../../lib/components/VoteStatus.svelte";
  import VoteHistory from "../../lib/components/VoteHistory.svelte";
  import Link from "../../lib/components/Link.svelte";
  import { api, vote } from "../../lib/store";
  import Box from "../../lib/components/Box.svelte";
  import type { Vote } from "../../lib/api";
  import { fakePubSubVoting, PubSubHandler } from "../../lib/pubsub";
  import {
    derived,
    type Readable,
    type Writable,
    writable,
  } from "svelte/store";
  import CreatorBanner from "../../lib/components/CreatorBanner.svelte";
  import ExpandableBox from "../../lib/components/ExpandableBox.svelte";
  import Notification from "../../lib/components/Notification.svelte";

  let showNewVote = false;

  const pubSubHandler = new PubSubHandler();

  const channel = derived(api, ($api, set) => {
    if (!$api) {
      return;
    }

    set($api.broadcasterGetChannel());
  });

  onMount(() => {
    pubSubHandler.init();

    pubSubHandler.addEventListener("vote_closed", async () => {
      $closedVotes = await $api.getClosedVotes();
    });

    if (dev) {
      return fakePubSubVoting();
    }

    return () => {};
  });

  onDestroy(() => {
    pubSubHandler.deinit();
  });

  const closedVotes: Writable<Promise<Vote[]>> = writable(
    new Promise(() => {}),
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

<div class="flex flex-col gap-4">
  {#await $channel then channel}
    <div
      class="flex flex-col gap-4"
      class:hidden={!channel}
      transition:slide={{ duration: 300 }}
    >
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
            disabled={$vote !== undefined && $vote !== null}>New Vote</Link
          >
          <VoteStatus
            on:close={async () => ($closedVotes = await $api.getClosedVotes())}
          />
          <Box>
            <VoteHistory votes={closedVotes} />
          </Box>

          <ExpandableBox>
            <div slot="title" class="flex gap-2">
              <h2>Changelog</h2>
              <div
                class="flex items-center rounded-lg bg-gray-900 px-2 text-xs text-cyan-100"
              >
                {import.meta.env.VITE_APP_VERSION}
              </div>
            </div>
            <div class="flex flex-col gap-2">
              <h3 class="text-xl font-bold">v3.1.0</h3>
              <div class="prose text-gray-400">
                <ul>
                  <li>
                    You can now select a time limit for votes. The vote will
                    close automatically after the time limit is reached. Viewers
                    can also see the remaining time.
                  </li>
                  <li>
                    Various changes in the backend to make it run on a more
                    modern server
                  </li>
                </ul>
              </div>

              <h3 class="text-xl font-bold">v3.0.1</h3>
              <div class="prose text-gray-400">
                <ul>
                  <li>Fixed a bug where channels could not be configured</li>
                  <li>
                    Fixed a bug where there were too many HTTP requests to the
                    Shipvote server.
                  </li>
                </ul>
              </div>
              <h3 class="text-xl font-bold">v3.0.0</h3>
              <div class="prose text-gray-400">
                <p>
                  This version is a complete rewrite of the previous interface.
                  It hopefully lays some groundwork for upcoming improvements.
                  This version is more or less on par with the previous version
                  feature-wise, although I had to remove the timer functionality
                  for now.
                </p>
                <p>
                  Please let me know if you encounter any problems or are
                  missing any features - I am happy to take feature requests!
                </p>
              </div>
            </div>
          </ExpandableBox>
        </div>
      {/if}
    </div>
  {:catch e}
    {#if e.response && e.response.status === 404}
      <Notification type="info" title="No configuration found">
        <p>
          Please visit the "Extensions" page and set up the Shipvote extension
          for your channel
        </p>
      </Notification>
    {:else}
      <Notification type="error" title="Error">
        <p>Could not load channel configuration</p>
      </Notification>
    {/if}
  {/await}
  <Box>
    <CreatorBanner />
  </Box>
</div>
