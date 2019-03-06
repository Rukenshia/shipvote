<template>
  <mdc-list two-line bordered>
    <mdc-list-item v-for="vote in votes.slice(votes.length - 3, votes.length)" :key="vote.id">
      <span>X ship</span>
      <span slot="secondary">{{relativeTime(vote.updated_at)}}</span>
    </mdc-list-item>
  </mdc-list>
</template>

<script>
export default {
  props: ['votes'],
  data() {
    return {};
  },
  methods: {
    relativeTime(since) {

      var msPerMinute = 60 * 1000;
      var msPerHour = msPerMinute * 60;
      var msPerDay = msPerHour * 24;
      var msPerMonth = msPerDay * 30;
      var msPerYear = msPerDay * 365;

      var elapsed = new Date() - new Date(since);

      if (elapsed < msPerMinute) {
        const rounded = Math.round(elapsed/1000);
        return `${rounded} second${rounded !== 1 ? 's' : ''} ago`;
      }

      else if (elapsed < msPerHour) {
        const rounded = Math.round(elapsed/msPerMinute);
        return `${rounded} minute${rounded !== 1 ? 's' : ''} ago`;
      }

      else if (elapsed < msPerDay ) {
        const rounded = Math.round(elapsed/msPerHour);
        return `${rounded} hour${rounded !== 1 ? 's' : ''} ago`;
      }

      else {
        return 'some days ago';
      }
    }
  }
}
</script>
