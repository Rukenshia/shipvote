<template>
  <mdc-layout-grid style="padding: 4px 0 16px 0">
    <mdc-layout-cell phone=2 tablet=4 desktop=6>
        <mdc-select
          class="fullwidth"
          style="width: 100%;"
          v-model="tier"
          label="Tier">
          <option>any</option>
          <template v-for="option in tiers">
          <option>{{ option }}</option>
          </template>
        </mdc-select>
    </mdc-layout-cell>
    <mdc-layout-cell phone=2 tablet=4 desktop=6>
        <mdc-select
          class="fullwidth"
          style="width: 100%;"
          v-model="nation"
          label="Nation">
          <option>any</option>
          <template v-for="option in nations">
          <option>{{ option }}</option>
          </template>
        </mdc-select>
    </mdc-layout-cell>
  </mdc-layout-grid>
</template>

<script>
export default {
  props: ['tiers', 'nations'],
  data() {
    return {
      tier: "any",
      nation: "any",
    };
  },
  watch: {
    tier() {
      let value = this.tier;

      if (value !== 'any') {
        value = parseInt(value, 10);
      }
      this.$emit('updateFilter', { name: 'tier', value });
    },
    nation() {
      this.$emit('updateFilter', { name: 'nation', value: this.nation });
    },
  },
  methods: {
    reset() {
      this.tier = 'any';
      this.nation = 'any';
    },
  },
};
</script>
