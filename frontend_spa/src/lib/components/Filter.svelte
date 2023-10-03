<script lang="ts">
  export let name: string;
  export let options: string[];

  let allOptions = ["all", ...options];
  export let value = allOptions[0];
</script>

<div class="flex-auto">
  <label for={name} class="block text-sm font-medium text-cyan-100"
    ><slot /></label
  >
  <select
    id={name}
    {name}
    class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-cyan-600 bg-cyan-700 focus:outline-none focus:ring-cyan-500 focus:border-cyan-500 sm:text-sm rounded-md"
    bind:value
  >
    {#each allOptions as option}
      <option>{option}</option>
    {/each}
  </select>
</div>
