<template>
  <div class="index is-dark">
    <div class="titles container">
      <h1 class="title has-text-white is-1">Harbinger Oracle</h1>
      <h2 class="subtitle has-text-white">Defi on the Tezos Blockchain</h2>
    </div>
    <div class="container is-flex">
      <div class="box ticker-info">
        <h2 class="title is-3">Live Oracle Data</h2>
        <h2 class="subtitle is-6"><a target="_blank" href="https://better-call.dev/mainnet/KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9/operations">View Contract</a></h2>
        <table class="table is-hoverable is-fullwidth">
          <tbody>
            <tr class="pair-info" :key="pair[0]" v-for="pair in sorted($store.prices)">
              <td class="">
                <span><img :src="iconURL(pair[0])" /></span>
              </td>
              <td>
                <p class="ticker">{{pair[0]}}</p>
              </td>
              <td>
                <p class="price">${{ numberWithCommas((pair[1].close / 1000000).toFixed(2)) }}</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'

export default {
  name: 'Index',
  components: {
  },
  data() {
    return {
    }
  },
  mounted() {
  },
  methods: {
    numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    },
    sorted(payload) {
      return _(payload)
        .toPairs()
        .sortBy(1, (item) => item[1].close)
        .reverse()
        .value()
    },
    iconURL(ticker) {
      const images = require.context('../assets/', false, /\.png$/)
      return images(`./${ticker}.png`)
    },
  },
};
</script>

<style lang="scss">
  @import '../../node_modules/bulma/sass/utilities/_all';
  $blue: #123262;
  .index{
    min-height: 100vh;
    background: $blue;
    padding: 3rem;
    .titles{
      max-width: 50vw;
      margin-bottom: 1rem;
    }
    .container.is-flex{
      justify-content: center;
    }
    .ticker-info{
      min-width: 30rem;
      .pair-info{
        vertical-align: middle;
        td{
          padding: 0.5rem;
          vertical-align: middle;
          img{
            vertical-align: middle;
          }
        }
        .ticker{
          width: 100%;
        }
        .price{
          min-width: 3rem;
        }
        img{
          width: 2rem;
        }
      }
    }
  }
</style>
