<script lang="ts">
	import { derived, Readable } from 'svelte/store';
	import { warships } from '../store';

	export let votes: Readable<object>;

	const ships = derived([votes, warships], async ([value, $warships]) => {
		if (!$warships) {
			return new Array(4).fill({ name: '' });
		}

		const currentWarships = await $warships;
		return Object.entries(value)
			.map(([key, value]) => {
				return {
					...currentWarships[key],
					votes: value
				};
			})
			.sort((a, b) => (a > b ? -1 : a === b ? 0 : 1)) // Sort votes from high to low
			.slice(0, 4);
	});
</script>

<h2 class="text-xl mt-2">Results</h2>

<ul class="px-4">
	{#await $ships}
		{#each new Array(4) as _v}
			<li
				class="bg-gray-700 hover:bg-gray-600 transition
			drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-4"
			>
				<div class="h-10" />
			</li>
		{/each}
	{:then ships}
		{#each ships as ship, rank}
			<li
				class="bg-gray-700 hover:bg-gray-600 transition
			drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-4"
			>
				<img alt="ship" class="h-10 w-16" src={ship.image} />
				<span class="text-lg font-medium text-gray-400">{rank + 1}.</span>
				<span class="flex-grow text-lg">{ship.name}</span>
				<span>{ship.votes}</span>
			</li>
		{/each}
	{/await}
</ul>
