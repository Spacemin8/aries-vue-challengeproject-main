import 'package:flutter/material.dart';

import 'option_strategy_chart.dart';
import 'package:fl_chart/fl_chart.dart';

class OptionsCalculator extends StatefulWidget {
  const OptionsCalculator({super.key, required this.optionsData});

  final List<Map<String, dynamic>> optionsData;

  @override
  State<OptionsCalculator> createState() => _OptionsCalculatorState();
}

class _OptionsCalculatorState extends State<OptionsCalculator> {
  List<Map<String, dynamic>> optionsData = [];

  @override
  void initState() {
    super.initState();
    optionsData = List.from(widget.optionsData);
  }

  final _formKey = GlobalKey<FormState>();

  TextEditingController strikeController = TextEditingController();
  TextEditingController bidController = TextEditingController();
  TextEditingController askController = TextEditingController();

  String? selectedType;
  String? selectedLongShort;

  //add option if validate passes, option was added
  addOption() {
    if (optionsData.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 options allowed')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        optionsData.add({
          "strike_price": double.parse(strikeController.text),
          "type": selectedType!,
          "bid": double.parse(bidController.text),
          "ask": double.parse(askController.text),
          "long_short": selectedLongShort!,
          "expiration_date": DateTime.now().toIso8601String(),
        });
      });
      // Clear the form
      strikeController.clear();
      bidController.clear();
      askController.clear();
      selectedType = null;
      selectedLongShort = null;
    }
  }

  /// Calculates the break-even points from the list of data points.
  ///
  /// Iterates through the data points to find where the profit/loss crosses zero.
  List<double> calculateBreakEvenPoints(List<FlSpot> dataPoints) {
    List<double> breakEvenPoints = [];
    for (int i = 0; i < dataPoints.length - 1; i++) {
      if ((dataPoints[i].y <= 0 && dataPoints[i + 1].y >= 0) ||
          (dataPoints[i].y >= 0 && dataPoints[i + 1].y <= 0)) {
        double x1 = dataPoints[i].x;
        double y1 = dataPoints[i].y;
        double x2 = dataPoints[i + 1].x;
        double y2 = dataPoints[i + 1].y;
        double breakEvenX = x1 + (0 - y1) * (x2 - x1) / (y2 - y1);
        breakEvenPoints.add(breakEvenX);
      }
    }
    return breakEvenPoints;
  }

  /// Calculates the risk and reward for the given options data.
  /// Generates a list of data points representing profit/loss for a range of underlying prices.
  /// Calculates the maximum profit, maximum loss, and break-even points.
  List<FlSpot> calculateRiskReward(List<Map<String, dynamic>> optionsData) {
    List<FlSpot> dataPoints = [];
    double maxProfit = double.negativeInfinity;
    double maxLoss = double.infinity;

    // Define a range of underlying prices to analyze
    for (double price = 90.0; price <= 120.0; price += 0.5) {
      double profitLoss = 0.0;
      for (var option in optionsData) {
        double strikePrice = option['strike_price'].toDouble();
        String type = option['type'];
        String longShort = option['long_short'];
        double ask = option['ask'].toDouble();
        double bid = option['bid'].toDouble();
        double premium = (ask + bid) / 2.0;

        if (type == 'Call') {
          if (longShort == 'long') {
            profitLoss +=
                (price > strikePrice ? price - strikePrice : 0.0) - premium;
          } else {
            profitLoss +=
                premium - (price > strikePrice ? price - strikePrice : 0.0);
          }
        } else if (type == 'Put') {
          if (longShort == 'long') {
            profitLoss +=
                (price < strikePrice ? strikePrice - price : 0.0) - premium;
          } else {
            profitLoss +=
                premium - (price < strikePrice ? strikePrice - price : 0.0);
          }
        }
      }
      dataPoints.add(FlSpot(price, profitLoss));
      if (profitLoss > maxProfit) maxProfit = profitLoss;
      if (profitLoss < maxLoss) maxLoss = profitLoss;
    }
    List<double> breaksEvenPoints = calculateBreakEvenPoints(dataPoints);

    setState(() {
      this.maxProfit = maxProfit;
      this.maxLoss = maxLoss;
      breakEvenPoints = breaksEvenPoints;
    });

    return dataPoints;
  }

  double maxProfit = 0;
  double maxLoss = 0;
  List<double> breakEvenPoints = [];
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Options Profit Calculator"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: strikeController,
                      decoration: const InputDecoration(
                        labelText: 'Strike Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a strike price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Call', 'Put'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedType = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bidController,
                      decoration: const InputDecoration(
                        labelText: 'Bid',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: askController,
                      decoration: const InputDecoration(
                        labelText: 'Ask',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an ask';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedLongShort,
                      decoration: const InputDecoration(
                        labelText: 'Long/Short',
                        border: OutlineInputBorder(),
                      ),
                      items: ['long', 'short'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedLongShort = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select long or short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: addOption,
                      child: const Text('Add Option'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: optionsData.length,
                  itemBuilder: (context, index) {
                    var option = optionsData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          option['type'].toLowerCase() == 'call'
                              ? Icons.call_made_outlined
                              : Icons.call_received_outlined,
                          color: option['type'].toLowerCase() == 'call'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                            '${option['type']} ${option['long_short']} @ ${option['strike_price']}'),
                        subtitle: Text(
                            'Bid: ${option['bid']}, Ask: ${option['ask']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              optionsData.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  List<FlSpot> dataPoints = calculateRiskReward(optionsData);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OptionStrategyChart(
                        dataPoints: dataPoints,
                        maxProfit: maxProfit,
                        maxLoss: maxLoss,
                        breakEvenPoints: breakEvenPoints,
                      ),
                    ),
                  );
                },
                child: const Text('Calculate Risk & Reward'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
