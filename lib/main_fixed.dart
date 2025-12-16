import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

const double appBarHeight = 48.0;
const double appBarElevation = 1.0;

bool shortenOn = false;

List<dynamic> marketListData = [];
Map<String, dynamic> portfolioMap = {};
List<dynamic> portfolioDisplay = [];
Map<String, dynamic> totalPortfolioStats = {};

bool isIOS = false;
String upArrow = "⬆";
String downArrow = "⬇";

int lastUpdate = 0;

Future<void> getMarketData() async {
  try {
    var response = await http.get(
        Uri.parse(
            "https://min-api.cryptocompare.com/data/top/mktcapfull?tsym=USD&limit=100"),
        headers: {"Accept": "application/json"});

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['Data'] != null) {
        marketListData = data['Data'];
        lastUpdate = DateTime.now().millisecondsSinceEpoch;
        print("Got new market data: ${marketListData.length} coins");
      }
    }
  } catch (e) {
    print("Error fetching market data: $e");
    // Use mock data if API fails
    marketListData = _getMockData();
  }
}

List<dynamic> _getMockData() {
  return [
    {
      "CoinInfo": {"Name": "BTC", "FullName": "Bitcoin", "Id": "1182"},
      "RAW": {
        "USD": {
          "PRICE": 45000.0,
          "CHANGEPCT24HOUR": 2.5,
          "CHANGEPCTHOUR": 0.5,
          "MKTCAP": 850000000000.0,
          "TOTALVOLUME24H": 25000000000.0
        }
      }
    },
    {
      "CoinInfo": {"Name": "ETH", "FullName": "Ethereum", "Id": "7605"},
      "RAW": {
        "USD": {
          "PRICE": 3200.0,
          "CHANGEPCT24HOUR": -1.2,
          "CHANGEPCTHOUR": 0.8,
          "MKTCAP": 380000000000.0,
          "TOTALVOLUME24H": 15000000000.0
        }
      }
    },
    {
      "CoinInfo": {"Name": "ADA", "FullName": "Cardano", "Id": "5031"},
      "RAW": {
        "USD": {
          "PRICE": 1.20,
          "CHANGEPCT24HOUR": 5.8,
          "CHANGEPCTHOUR": -0.3,
          "MKTCAP": 40000000000.0,
          "TOTALVOLUME24H": 2000000000.0
        }
      }
    }
  ];
}

String numCommaParse(String numString) {
  if (shortenOn) {
    double num = double.tryParse(numString) ?? 0;
    if (num >= 1000000000) {
      return "${(num / 1000000000).toStringAsFixed(1)}B";
    } else if (num >= 1000000) {
      return "${(num / 1000000).toStringAsFixed(1)}M";
    } else if (num >= 1000) {
      return "${(num / 1000).toStringAsFixed(1)}K";
    }
  }

  double num = double.tryParse(numString) ?? 0;
  return num.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
}

String normalizeNum(double input) {
  if (input >= 100000) {
    return numCommaParse(input.round().toString());
  } else if (input >= 1000) {
    return numCommaParse(input.toStringAsFixed(2));
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize portfolio data
  try {
    final directory = await getApplicationDocumentsDirectory();
    final portfolioFile = File('${directory.path}/portfolio.json');

    if (portfolioFile.existsSync()) {
      final content = portfolioFile.readAsStringSync();
      portfolioMap = Map<String, dynamic>.from(json.decode(content));
    }
  } catch (e) {
    print("Error loading portfolio: $e");
  }

  // Load preferences
  final prefs = await SharedPreferences.getInstance();
  shortenOn = prefs.getBool("shortenOn") ?? false;

  // Load initial market data
  await getMarketData();

  runApp(TraceApp());
}

class TraceApp extends StatefulWidget {
  @override
  TraceAppState createState() => TraceAppState();
}

class TraceAppState extends State<TraceApp> {
  bool darkEnabled = false;
  String themeMode = "Automatic";
  bool darkOLED = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Trace",
      home: TraceTabs(),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class TraceTabs extends StatefulWidget {
  @override
  TraceTabsState createState() => TraceTabsState();
}

class TraceTabsState extends State<TraceTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _tabIndex = _tabController.index;
      });
    });
    _makePortfolioDisplay();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _makePortfolioDisplay() {
    portfolioDisplay = [];
    totalPortfolioStats = {
      "value_usd": 0.0,
      "percent_change_24h": 0.0,
      "percent_change_1h": 0.0
    };

    if (portfolioMap.isNotEmpty && marketListData.isNotEmpty) {
      double totalValue = 0;

      portfolioMap.forEach((symbol, transactions) {
        double totalQuantity = 0;
        for (var transaction in transactions) {
          totalQuantity += transaction["quantity"] ?? 0;
        }

        // Find market data for this symbol
        var coinData;
        try {
          coinData = marketListData.firstWhere(
            (coin) => coin["CoinInfo"]["Name"] == symbol,
          );
        } catch (e) {
          coinData = null;
        }

        if (coinData != null && totalQuantity > 0) {
          try {
            var rawData = coinData["RAW"];
            var usdData = rawData?["USD"];
            if (rawData != null && usdData != null) {
              double price = (usdData["PRICE"] ?? 0).toDouble();
              double value = totalQuantity * price;
              totalValue += value;

              portfolioDisplay.add({
                "symbol": symbol,
                "price_usd": price,
                "percent_change_24h": usdData["CHANGEPCT24HOUR"] ?? 0,
                "percent_change_1h": usdData["CHANGEPCTHOUR"] ?? 0,
                "total_quantity": totalQuantity,
                "name": coinData["CoinInfo"]?["FullName"] ?? symbol,
                "value": value,
              });
            }
          } catch (e) {
            print("Error processing coin data for $symbol: $e");
          }
        }
      });

      totalPortfolioStats["value_usd"] = totalValue;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? "Portfolio" : "Markets"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: "Portfolio"),
            Tab(icon: Icon(Icons.trending_up), text: "Markets"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioPage(),
          _buildMarketsPage(),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addTransaction,
              icon: Icon(Icons.add),
              label: Text("Add Transaction"),
            )
          : null,
    );
  }

  Widget _buildPortfolioPage() {
    return RefreshIndicator(
      onRefresh: () async {
        await getMarketData();
        _makePortfolioDisplay();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Portfolio Value",
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: 8),
                      Text(
                        "\$${normalizeNum(totalPortfolioStats["value_usd"] ?? 0)}",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text("24h Change",
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                "${(totalPortfolioStats["percent_change_24h"] ?? 0).toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: (totalPortfolioStats[
                                                  "percent_change_24h"] ??
                                              0) >=
                                          0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Holdings",
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text("${portfolioDisplay.length} coins"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          portfolioDisplay.isNotEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final coin = portfolioDisplay[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(coin["symbol"]),
                            backgroundColor: Colors.purple[100],
                          ),
                          title: Text(coin["name"]),
                          subtitle: Text(
                              "${coin["total_quantity"]} ${coin["symbol"]}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("\$${normalizeNum(coin["value"])}",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                "${coin["percent_change_24h"].toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: coin["percent_change_24h"] >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: portfolioDisplay.length,
                  ),
                )
              : SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Your portfolio is empty",
                            style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 8),
                        Text("Add a transaction to get started!",
                            style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _addTransaction,
                          child: Text("Add Transaction"),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMarketsPage() {
    return RefreshIndicator(
      onRefresh: getMarketData,
      child: marketListData.isNotEmpty
          ? ListView.builder(
              itemCount: marketListData.length,
              itemBuilder: (context, index) {
                final coin = marketListData[index];
                final coinInfo = coin["CoinInfo"];
                final usdData = coin["RAW"]["USD"];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(coinInfo["Name"]),
                      backgroundColor: Colors.purple[100],
                    ),
                    title: Text(coinInfo["FullName"]),
                    subtitle: Text(coinInfo["Name"]),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("\$${normalizeNum(usdData["PRICE"])}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          "${usdData["CHANGEPCT24HOUR"].toStringAsFixed(2)}%",
                          style: TextStyle(
                            color: usdData["CHANGEPCT24HOUR"] >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading market data..."),
                ],
              ),
            ),
    );
  }

  void _addTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionSheet(
          onTransactionAdded: () {
            _makePortfolioDisplay();
          },
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback onTransactionAdded;

  const AddTransactionSheet({Key? key, required this.onTransactionAdded})
      : super(key: key);

  @override
  _AddTransactionSheetState createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String? selectedSymbol;
  bool isBuy = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Add Transaction",
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text("Buy"),
                  value: true,
                  groupValue: isBuy,
                  onChanged: (value) => setState(() => isBuy = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text("Sell"),
                  value: false,
                  groupValue: isBuy,
                  onChanged: (value) => setState(() => isBuy = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Cryptocurrency",
              border: OutlineInputBorder(),
            ),
            value: selectedSymbol,
            items: marketListData.map<DropdownMenuItem<String>>((coin) {
              return DropdownMenuItem<String>(
                value: coin["CoinInfo"]["Name"],
                child: Text(
                    "${coin["CoinInfo"]["Name"]} - ${coin["CoinInfo"]["FullName"]}"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSymbol = value;
                _symbolController.text = value ?? "";

                // Auto-fill current price
                var coinData = marketListData.firstWhere(
                  (coin) => coin["CoinInfo"]["Name"] == value,
                  orElse: () => null,
                );
                if (coinData != null) {
                  _priceController.text =
                      coinData["RAW"]["USD"]["PRICE"].toString();
                }
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: "Quantity",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: "Price (USD)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveTransaction,
            child: Text("Add Transaction"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _saveTransaction() async {
    if (selectedSymbol == null ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter valid numbers")),
      );
      return;
    }

    final transaction = {
      "quantity": isBuy ? quantity : -quantity,
      "price": price,
      "time": DateTime.now().millisecondsSinceEpoch,
      "type": isBuy ? "buy" : "sell",
    };

    if (portfolioMap[selectedSymbol!] == null) {
      portfolioMap[selectedSymbol!] = [];
    }
    portfolioMap[selectedSymbol!].add(transaction);

    // Save to file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/portfolio.json');
      await file.writeAsString(json.encode(portfolioMap));
    } catch (e) {
      print("Error saving portfolio: $e");
    }

    widget.onTransactionAdded();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Transaction added successfully!")),
    );
  }
}
