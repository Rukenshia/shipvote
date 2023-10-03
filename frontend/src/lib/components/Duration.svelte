<script>
  export let options = [null, 1, 5, 15, 20, 30];

  let selected = null;
</script>

<div>
  <div class="flex items-center justify-between">
    <h2 class="text-sm font-medium text-gray-300">Time Limit</h2>
  </div>

  <fieldset class="mt-2">
    <legend class="sr-only">Choose a memory option</legend>
    <div class="grid grid-cols-3 gap-3 sm:grid-cols-6">
      {#each options as option}
        <label
          class="border rounded-md py-3 px-3 flex items-center justify-center text-sm font-medium sm:flex-1 cursor-pointer transition focus:outline-none border-zinc-400 text-gray-50 hover:text-gray-900 hover:bg-zinc-200 active:ring-2 active:ring-offset-2 active:ring-gray-500"
          class:bg-gray-500={selected === option}
          class:border-transparent={selected === option}
          class:text-white={selected === option}
          class:hover:text-white={selected === option}
          class:hover:bg-gray-400={selected === option}
        >
          <input
            checked={selected === option}
            on:click={() => (selected = option)}
            type="radio"
            name="duration"
            value={option}
            class="sr-only"
            aria-labelledby="duration-{option}-label"
          />
          <p id="duration-{option}-label">
            {#if !option}
              None
            {:else}
              {option}

              minute{#if option > 1}s{/if}
            {/if}
          </p>
        </label>
      {/each}
    </div>
  </fieldset>
</div>
