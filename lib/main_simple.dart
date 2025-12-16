import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trace - Crypto Portfolio',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trace - Crypto Portfolio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Portfolio'),
            Tab(icon: Icon(Icons.trending_up), text: 'Markets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(),
          _buildMarketsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add Transaction feature coming soon!')),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildPortfolioTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.purple),
          SizedBox(height: 20),
          Text(
            'Portfolio Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 10),
          Text(
            'Your crypto portfolio will be displayed here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 20),
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Portfolio Value',
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: 8),
                  Text('\$0.00',
                      style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('24h Change',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text('0.00%', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Holdings',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text('0 coins'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.purple),
          SizedBox(height: 20),
          Text(
            'Market Explorer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 10),
          Text(
            'Cryptocurrency market data will be displayed here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final coins = [
                  'Bitcoin',
                  'Ethereum',
                  'Cardano',
                  'Polkadot',
                  'Chainlink'
                ];
                final symbols = ['BTC', 'ETH', 'ADA', 'DOT', 'LINK'];
                final prices = [
                  '\$45,000',
                  '\$3,200',
                  '\$1.20',
                  '\$25.50',
                  '\$28.00'
                ];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(symbols[index]),
                      backgroundColor: Colors.purple[100],
                    ),
                    title: Text(coins[index]),
                    subtitle: Text(symbols[index]),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(prices[index],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('+2.5%', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
