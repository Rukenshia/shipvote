<template>
  <mdc-list two-line bordered>
    <mdc-list-item
      v-for="vote in votes.slice(votes.length - 3, votes.length).reverse()"
      :key="vote.id"
    >
      <span>{{topVoted(vote.votes)}}</span>
      <span slot="secondary">{{relativeTime(vote.updated_at)}}</span>
    </mdc-list-item>
  </mdc-list>
</template>

<script>
export default {
  props: ['votes', 'ships'],
  data() {
    return {};
  },
  methods: {
    topVoted(votes) {
      const sorted = Object.keys(votes).map(v => ({
        ...this.ships.find(s => s.id === parseInt(v, 10)),
        votes: votes[v]
      }));

      sorted.sort((a, b) => {
        const av = votes[a.id] || 0;
        const bv = votes[b.id] || 0;

        if (av < bv) {
          return 1;
        } else if (av === bv) {
          return 0;
        }
        return -1;
      });

      if (sorted.length === 0 || typeof sorted[0] === 'undefined') {
        return 'none';
      }

      const max = votes[sorted[0].id];

      return sorted
        .filter(s => s.votes === max)
        .map(s => s.name)
        .join(', ');
    },
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
