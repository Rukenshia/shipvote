<script lang="ts">
  import { createEventDispatcher } from "svelte";

  const colorClassesMap = {
    default: "text-gray-100 bg-gray-800",
    primary:
      "text-emerald-50 bg-size-100 font-normal tracking-widest bg-gradient-to-b from-emerald-500 to-emerald-700 hover:bg-size-110",
  };

  const disabledClassesMap = {
    default: "text-gray-400 bg-gray-700",
    primary: "text-emerald-400 bg-emerald-900",
  };

  export let name: string;
  export let disabled: boolean = false;
  export let role: "default" | "primary" = "default";

  let classes = colorClassesMap[role];
  let disabledClasses = disabledClassesMap[role];

  const dispatch = createEventDispatcher();

  async function navigate() {
    dispatch("navigate", { name });
  }
</script>

<button
  on:click={navigate}
  class="overflow-hidden drop-shadow-xl rounded-lg px-4 py-5 sm:p-6 transition-all duration-250 {disabled
    ? disabledClasses
    : classes}"
  class:hover:cursor-pointer={!disabled}
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
