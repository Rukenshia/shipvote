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
  import VideoOverlaySettings from "../../lib/components/VideoOverlaySettings.svelte";

  let currentOverlay: "new_vote" | "settings" | null = null;

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
    $api.getOpenVote().then((v: any) => ($vote = v));
    $closedVotes = $api.getClosedVotes();
  }

  function navigate(e: CustomEvent<{ name: string }>) {
    e.preventDefault();

    switch (e.detail.name) {
      case "new_vote":
        currentOverlay = "new_vote";
        break;
      case "settings":
        currentOverlay = "settings";
        break;
    }
  }

  let feedback = "";
  let feedbackStatus = "";
  async function submitFeedback() {
    try {
      await $api.sendFeedback(feedback);
      feedback = "";
      feedbackStatus = "sent";
    } catch (e) {
      feedbackStatus = "error";
    }

    setTimeout(() => {
      feedbackStatus = "";
    }, 5000);
  }
</script>

<div class="flex flex-col gap-4">
  {#await $channel then channel}
    <div
      class="flex flex-col gap-4"
      class:hidden={!channel}
      transition:slide|global={{ duration: 300 }}
    >
      {#if currentOverlay !== null}
        {#if currentOverlay === "new_vote"}
          <NewVote
            on:back={() => (currentOverlay = null)}
            on:vote_opened={() => (currentOverlay = null)}
          />
        {/if}
        {#if currentOverlay === "settings"}
          <VideoOverlaySettings
            on:back={() => (currentOverlay = null)}
            {channel}
          />
        {/if}
      {:else}
        <div
          transition:slide|global={{ duration: 100 }}
          class="flex flex-col gap-4"
        >
          {#if $vote === undefined || $vote === null || $vote.status === "closed"}
            <Link
              on:navigate={navigate}
              name="new_vote"
              role="primary"
              disabled={$vote !== undefined && $vote !== null}>New Vote</Link
            >
          {/if}
          <VoteStatus
            on:close={async () => ($closedVotes = await $api.getClosedVotes())}
          />

          <Box>
            <VoteHistory votes={closedVotes} />
          </Box>

          <Link on:navigate={navigate} name="settings">
            <div class="flex gap-2">
              <span
                class="inline-flex items-center rounded-md bg-cyan-400/10 px-2 py-1 text-xs font-medium text-cyan-400 ring-1 ring-inset ring-cyan-400/30"
                >New</span
              >
              <span>Settings</span>
            </div>
          </Link>

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
              <h3 class="text-xl font-bold">v3.3.0</h3>
              <div class="prose text-gray-400">
                <ul>
                  <li>
                    Fixed a bug where remaining vote time was not displayed
                  </li>
                  <li>
                    Added visual indicator while saving the main config page
                  </li>
                  <li>Fixed the sorting of tiers in all filters</li>
                  <li>Improved styling for ship selection</li>
                </ul>
              </div>

              <h3 class="text-xl font-bold">v3.2.0</h3>
              <div class="prose text-gray-400">
                <ul>
                  <li>
                    Added a Settings page where you can configure the overlay
                    position for desktop viewers
                  </li>
                  <li>
                    Cleaned up some UI elements to make it easier to interact
                    with votes
                  </li>
                  <li>
                    The most recently used ships for your vote are now saved in
                    the backend so that it resets less often for you
                  </li>
                  <li>
                    You can now submit feedback directly from the extension
                  </li>
                </ul>
              </div>
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

          <ExpandableBox
            colorClasses="text-amber-50 bg-gradient-to-b from-amber-400/20 to-amber-600/20"
            title="Feedback"
          >
            <div class="flex flex-col gap-4">
              <div class="prose text-gray-50 min-w-full">
                If you have any feedback, feature requests, or bug reports,
                please let me know! You can either submit feedback through the
                field below or contact me on Discord at <span
                  class="font-semibold">Rukenshia#4396<span>. </span></span
                >
              </div>

              <textarea
                bind:value={feedback}
                class="w-full p-2 rounded-lg bg-amber-950/60 text-amber-100 placeholder-amber-100"
                placeholder="Enter your feedback here"
              ></textarea>
              <button
                on:click={submitFeedback}
                class="rounded-lg bg-gradient-to-b from-amber-400/50 to-amber-600/50 text-amber-50 px-6 py-2 bg-size-100 hover:bg-size-110 transition-all duration-250"
                >Submit</button
              >

              {#if feedbackStatus}
                <div in:slide|global out:slide|global>
                  {#if feedbackStatus === "error"}
                    <div class="text-red-200">
                      Error sending feedback. Please contact me on Discord!
                    </div>
                  {:else}
                    <div class="text-amber-200">Feedback sent!</div>
                  {/if}
                </div>
              {/if}
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
