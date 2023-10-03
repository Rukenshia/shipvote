<script lang="ts">
  import { createEventDispatcher } from "svelte";

  export let name: string;
  export let classes: string;
  export let disabledClasses: string = "";
  export let disabled: boolean = false;

  const dispatch = createEventDispatcher();

  async function navigate() {
    dispatch("navigate", { name });
  }
</script>

<button
  on:click={navigate}
  class="text-gray-100 bg-gray-800 overflow-hidden drop-shadow-xl rounded-lg px-4 py-5 sm:p-6 transition {disabled
    ? disabledClasses
    : classes}"
  class:hover:cursor-pointer={!disabled}
  class:hover:bg-gray-700={!disabled}
  {disabled}
>
  <div class="flex space-around items-center gap-4">
    <slot />
    <svg
      class="w-6 h-6"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      ><path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M17 8l4 4m0 0l-4 4m4-4H3"
      /></svg
    >
  </div>
</button>
