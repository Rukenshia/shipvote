<script lang="ts">
  export let hover = false;
  export let title: string | undefined = undefined;

  export let colorClasses = "bg-gray-800 text-gray-100";
</script>

<div
  class="{colorClasses} overflow-hidden drop-shadow-xl rounded-lg p-4 sm:p-6"
  class:hover:bg-gray-700={hover}
  class:transition={hover}
  class:hover:cursor-pointer={hover}
>
  {#if title}
    <slot name="title">
      <h2 class="text-gray-200 text-xl font-medium mb-4">{title}</h2>
    </slot>
  {/if}

  <slot />
</div>
