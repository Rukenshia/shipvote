<script lang="ts">
	import { onMount } from 'svelte';

	import '../../twitch';
	import VoteStatus from '$lib/components/VoteStatus.svelte';
	import Box from '$lib/components/Box.svelte';

	onMount(() => {
		window.Twitch.ext.listen(
			'broadcast',
			(_target: string, contentType: string, message: string) => {
				if (contentType !== 'application/json') {
					return;
				}

				const data = JSON.parse(atob(message));
				handlePubSubMessage(data);
			}
		);
	});

	function handlePubSubMessage(data: object) {
		console.log(data);
	}
</script>

<div class="flex flex-col gap-4">
	<VoteStatus />
	<Box>
		<h1>Configure Vote</h1>
	</Box>
</div>
