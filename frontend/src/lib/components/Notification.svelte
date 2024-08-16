<script lang="ts">
  export let hover = false;
  export let title: string | undefined = undefined;
  export let type: "info" | "error" | "success" = "info";

  const colors = {
    info: "bg-cyan-800 text-cyan-100",
    error:
      "text-red-100 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-rose-500/80 to-red-700/80",
    success: "bg-emerald-500 text-emerald-100",
  };

  const titleColors = {
    info: "text-cyan-50",
    error: "text-red-50",
    success: "text-emerald-50",
  };

  $: color = colors[type];
  $: titleColor = titleColors[type];
</script>

<div
  class="{color} overflow-hidden drop-shadow-xl rounded-lg p-4 sm:p-6"
  class:hover:bg-gray-700={hover}
  class:transition={hover}
  class:hover:cursor-pointer={hover}
>
  {#if title}
    <slot name="title">
      <h2 class="{titleColor} text-xl font-medium mb-4">{title}</h2>
    </slot>
  {/if}

  <slot />
</div>
