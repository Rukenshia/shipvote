<script lang="ts">
  import type { Ship, Vote } from "../api";
  import { derived, type Readable } from "svelte/store";

  export let vote: Readable<Vote>;
  export let warships: { [key: string]: Ship };

  let topThreeShips = derived(
    vote,
    ($vote) => {
      if (!$vote || !$vote.votes) {
        return [];
      }

      return Object.entries($vote.votes)
        .sort(([_, a], [__, b]) => b - a)
        .slice(0, 3)
        .map(([id, votes]) => {
          return {
            ship: warships[`${id}`],
            votes,
          };
        });
    },
    [],
  );
</script>

<div class="flex flex-col">
  {#each $topThreeShips as votedShip}
    <div
      class="bg-cyan-900/80 rounded pr-2 py-0.5 text-cyan-100 flex items-center gap-2 text-md"
    >
      <img src={votedShip.ship.image} alt={votedShip.ship.name} class="h-6" />
      <div class="flex-grow">{votedShip.ship.name}</div>

      <div class="text-cyan-200">{votedShip.votes}</div>
    </div>
  {/each}
</div>
