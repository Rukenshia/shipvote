<script lang="ts">
  export let name: string;
  export let options: string[] | { value: any; label: string }[];

  let allOptions: { value: string; label: string }[] = [
    { value: "all", label: "all" },
    ...options.map((option) => {
      if (typeof option === "string") {
        return { value: option, label: option };
      }

      return option;
    }),
  ];
  export let value = allOptions[0].value;
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
      <option value={option.value}>{option.label}</option>
    {/each}
  </select>
</div>
