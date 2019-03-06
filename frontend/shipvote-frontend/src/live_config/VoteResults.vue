<template>
  <mdc-list two-line bordered>
    <mdc-list-item v-for="vote in votes.slice(0, 3)" :key="vote.id">
      <span>X ship</span>
      <span slot="secondary">x minutes ago</span>
    </mdc-list-item>
  </mdc-list>
</template>

<script>
export default {
  props: ['votes'],
  data() {
    return {};
  }
}
</script>
