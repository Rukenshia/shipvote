<script>
  export let options = [null, 1, 5, 15, 20, 30];

  export let selected = null;
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
          class="flex cursor-pointer items-center justify-center rounded-md border border-cyan-400 px-3 py-3 text-sm font-medium text-gray-50 transition hover:bg-cyan-500 hover:text-gray-900 focus:outline-none active:ring-2 active:ring-gray-500 active:ring-offset-2 sm:flex-1"
          class:bg-cyan-700={selected === option}
          class:border-transparent={selected === option}
          class:text-white={selected === option}
          class:hover:text-white={selected === option}
          class:hover:bg-cyan-700={selected === option}
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
