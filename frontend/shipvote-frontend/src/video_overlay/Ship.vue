<template>
  <div class="ship" @click="vote" :data-voteable="canBeVoted">
    <div v-if="canBeVoted" class='vote-button'>Vote</div>
    <div class="progress-bar">
      <div class="progress" :style="{minWidth: `${votes > 0 ? votes / totalVotes * 100 : 0}%`}"></div>
    </div>
    <img :src="image" />
    <span class="typography--headline2">{{name}} ({{votes}})</span>
  </div>
</template>

<script>
export default {
  props: ['name', 'image', 'votes', 'canBeVoted', 'totalVotes'],
  data() {
    return {};
  },
  methods: {
    vote() {
      this.$emit('vote');
    }
  }
};
</script>

<style lang="scss">
@import '../card';

.ship {
  margin-right: 4px;
  width: calc(48% - 8px);
  position: relative;
  display: flex;
  align-items: center;
  border-radius: 4px;
  border: 1px solid #eaeaea;
  padding: 4px;
  margin-bottom: 4px;
  overflow: hidden;

  transition: background-color 0.2s, border-color 0.2s;

  &[data-voteable='true']:hover {
    .vote-button {
      visibility: visible;
      opacity: 1;
      cursor: pointer;
    }

    @include raised();
    border-color: #6441a4;
  }

  * {
    z-index: 1;
  }

  img {
    width: 20%;
    margin-right: 8px;
  }

  .progress-bar .progress {
    transition: background-color 0.2s;
  }

  .vote-button {
    z-index: 2;

    position: absolute;
    left: 0;
    width: 100%;
    height: 100%;

    display: flex;
    justify-content: center;
    align-items: center;

    text-align: center;
    color: white;
    font-weight: normal;
    text-transform: uppercase;

    opacity: 0;
    background-color: #6441a4;
    transition: opacity 0.2s;
  }
}

.progress-bar .progress {
  background-color: rgba(100, 65, 164, 0.2);
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  z-index: 0;

  transition: min-width 0.2s;
}
</style>
