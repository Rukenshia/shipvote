<script lang="ts">
	import { api } from '$lib/store';

	import { readable } from 'svelte/store';

	import type { Vote } from '$lib/api';
	import VoteResults from './VoteResults.svelte';
	import Box from './Box.svelte';

	let currentVote: Promise<Vote> = null;

	$: if ($api) {
		currentVote = $api.getOpenVote();
	}

	const votes = readable({ 4282267344: 30, 3762206544: 25, 3760076080: 20, 4179605296: 15 });
</script>

<main>
	<Box>
		The vote is currently

		<span class="font-medium">
			{#await currentVote}
				loading...
			{:then vote}
				{#if vote}
					open
				{:else}
					closed
				{/if}
			{:catch}
				&lt;request failed&gt;
			{/await}
		</span>

		<div>
			<VoteResults {votes} />
		</div>
	</Box>
</main>
