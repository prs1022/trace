import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(TraceApp());
}

class TraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trace',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          elevation: 1.0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: TraceTabs(),
    );
  }
}

class TraceTabs extends StatefulWidget {
  @override
  _TraceTabsState createState() => _TraceTabsState();
}

class _TraceTabsState extends State<TraceTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> marketListData = [];
  List<dynamic> portfolioDisplay = [];
  Map<String, dynamic> totalPortfolioStats = {
    "value_usd": 0.0,
    "percent_change_24h": 0.0,
    "percent_change_1h": 0.0
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMarketData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://min-api.cryptocompare.com/data/top/mktcapfull?tsym=USD&limit=50'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Data'] != null) {
          setState(() {
            marketListData = data['Data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading market data: $e');
      // Use mock data if API fails
      setState(() {
        marketListData = _getMockMarketData();
        isLoading = false;
      });
    }
  }

  List<dynamic> _getMockMarketData() {
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
      },
      {
        "CoinInfo": {"Name": "DOT", "FullName": "Polkadot", "Id": "5899"},
        "RAW": {
          "USD": {
            "PRICE": 25.50,
            "CHANGEPCT24HOUR": 3.2,
            "CHANGEPCTHOUR": 1.1,
            "MKTCAP": 25000000000.0,
            "TOTALVOLUME24H": 1500000000.0
          }
        }
      },
      {
        "CoinInfo": {"Name": "LINK", "FullName": "Chainlink", "Id": "3808"},
        "RAW": {
          "USD": {
            "PRICE": 28.00,
            "CHANGEPCT24HOUR": -2.1,
            "CHANGEPCTHOUR": 0.7,
            "MKTCAP": 13000000000.0,
            "TOTALVOLUME24H": 800000000.0
          }
        }
      }
    ];
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '\$${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '\$${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '\$${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${number.toStringAsFixed(2)}';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(6)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text(
                'Trace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.timeline),
              title: Text('Portfolio Timeline'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.pie_chart),
              title: Text('Portfolio Breakdown'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(_tabController.index == 0
                  ? "Portfolio"
                  : "Aggregate Markets"),
              pinned: true,
              floating: true,
              elevation: 1.0,
              forceElevated: innerBoxIsScrolled,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(38.0),
                child: Container(
                  height: 38.0,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.purple,
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.person)),
                      Tab(icon: Icon(Icons.trending_up)),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPortfolioPage(),
            _buildMarketsPage(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Add Transaction feature coming soon!')),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Add Transaction"),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  Widget _buildPortfolioPage() {
    return RefreshIndicator(
      onRefresh: _loadMarketData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Portfolio Value",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatPrice(totalPortfolioStats["value_usd"]),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "1h Change",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${totalPortfolioStats["percent_change_1h"] >= 0 ? '+' : ''}${totalPortfolioStats["percent_change_1h"].toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: totalPortfolioStats["percent_change_1h"] >= 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "24h Change",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${totalPortfolioStats["percent_change_24h"] >= 0 ? '+' : ''}${totalPortfolioStats["percent_change_24h"].toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: totalPortfolioStats["percent_change_24h"] >= 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Text(
                      "Currency",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      "Holdings",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: Text(
                      "Price/24h",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          portfolioDisplay.isEmpty
              ? SliverFillRemaining(
                  child: Container(
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Your portfolio is empty. Add a transaction!",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Add Transaction feature coming soon!')),
                            );
                          },
                          child: Text("New Transaction"),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final coin = portfolioDisplay[index];
                      return _buildPortfolioItem(coin);
                    },
                    childCount: portfolioDisplay.length,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMarketsPage() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarketData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.32,
                    child: Text(
                      "Currency",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Text(
                      "Market Cap/24h",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    width: MediaQuery.of(context).size.width * 0.28,
                    child: Text(
                      "Price/24h",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final coin = marketListData[index];
                return _buildMarketItem(coin, index + 1);
              },
              childCount: marketListData.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(Map<String, dynamic> coin) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Coin icon and info
          Expanded(
            flex: 25,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.purple[100],
                  child: Text(
                    coin["symbol"] ?? "?",
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin["name"] ?? coin["symbol"] ?? "Unknown",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        coin["symbol"] ?? "",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Holdings
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(coin["value"] ?? 0),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  "${coin["total_quantity"]?.toStringAsFixed(4) ?? '0'} ${coin["symbol"] ?? ''}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          // Price and change
          Expanded(
            flex: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(coin["price_usd"] ?? 0),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  "${coin["percent_change_24h"] >= 0 ? '+' : ''}${coin["percent_change_24h"]?.toStringAsFixed(2) ?? '0.00'}%",
                  style: TextStyle(
                    color: (coin["percent_change_24h"] ?? 0) >= 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketItem(Map<String, dynamic> coin, int rank) {
    final coinInfo = coin["CoinInfo"];
    final rawData = coin["RAW"];
    final usdData = rawData?["USD"];

    if (coinInfo == null || usdData == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Rank and coin info
          Expanded(
            flex: 32,
            child: Row(
              children: [
                Container(
                  width: 24,
                  child: Text(
                    rank.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple[100],
                  child: Text(
                    coinInfo["Name"] ?? "?",
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coinInfo["Name"] ?? "Unknown",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Market cap and volume
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber((usdData["MKTCAP"] ?? 0).toDouble()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  _formatNumber((usdData["TOTALVOLUME24H"] ?? 0).toDouble()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          // Price and change
          Expanded(
            flex: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice((usdData["PRICE"] ?? 0).toDouble()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  "${(usdData["CHANGEPCT24HOUR"] ?? 0) >= 0 ? '+' : ''}${(usdData["CHANGEPCT24HOUR"] ?? 0).toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: (usdData["CHANGEPCT24HOUR"] ?? 0) >= 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
