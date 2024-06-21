<template>
  <div class="options-strategy-analyzer">
    <h1>Options Strategy Risk & Reward Analysis</h1>
    <div>
      <div v-for="(option, index) in options" :key="index" class="option-input">
        <input
          v-model.number="option.strike"
          placeholder="Strike Price"
          type="number"
        />
        <input
          v-model.number="option.premium"
          placeholder="Premium"
          type="number"
        />
        <select v-model="option.type">
          <option value="call">Call</option>
          <option value="put">Put</option>
        </select>
      </div>
    </div>
    <button @click="calculateStrategy">Calculate</button>
    <div v-if="results">
      <line-chart :data="chartData" :options="chartOptions"></line-chart>
      <p>Max Profit: {{ results.maxProfit }}</p>
      <p>Max Loss: {{ results.maxLoss }}</p>
      <p>Break Even Points: {{ results.breakEvenPoints.join(", ") }}</p>
    </div>
  </div>
</template>

<script>
import { Line } from "vue-chartjs";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

export default {
  name: "OptionsStrategyAnalyzer",
  components: {
    LineChart: Line,
  },
  data() {
    return {
      options: [
        { strike: 0, premium: 0, type: "call" },
        { strike: 0, premium: 0, type: "call" },
        { strike: 0, premium: 0, type: "call" },
        { strike: 0, premium: 0, type: "call" },
      ],
      results: null,
      chartData: null,
      chartOptions: {
        responsive: true,
        plugins: {
          legend: {
            position: "top",
          },
          title: {
            display: true,
            text: "Risk & Reward Graph",
          },
        },
      },
    };
  },
  methods: {
    calculateStrategy() {
      const prices = [];
      const profits = [];

      for (let price = 0; price <= 200; price += 1) {
        prices.push(price);
        let profit = 0;

        this.options.forEach((option) => {
          if (option.type === "call") {
            profit += Math.max(0, price - option.strike) - option.premium;
          } else if (option.type === "put") {
            profit += Math.max(0, option.strike - price) - option.premium;
          }
        });

        profits.push(profit);
      }

      const maxProfit = Math.max(...profits);
      const maxLoss = Math.min(...profits);
      const breakEvenPoints = prices.filter(
        (price, index) => profits[index] === 0
      );

      this.results = {
        maxProfit,
        maxLoss,
        breakEvenPoints,
      };

      this.chartData = {
        labels: prices,
        datasets: [
          {
            label: "Profit/Loss",
            data: profits,
            borderColor: "rgba(75, 192, 192, 1)",
            borderWidth: 1,
            fill: false,
          },
        ],
      };
    },
  },
};
</script>

<style scoped>
.options-strategy-analyzer {
  max-width: 800px;
  margin: auto;
  text-align: center;
}

.option-input {
  margin: 10px 0;
}

input,
select {
  margin: 5px;
}

button {
  margin: 10px;
}
</style>
