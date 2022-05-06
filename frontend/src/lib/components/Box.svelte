<script lang="ts">
  export let hover = false;
</script>

<div
  class="text-gray-100 bg-gray-800 overflow-hidden drop-shadow-xl rounded-lg p-4 sm:p-6"
  class:hover:bg-gray-700={hover}
  class:transition={hover}
  class:hover:cursor-pointer={hover}
>
  <slot />
</div>
