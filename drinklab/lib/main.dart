import 'package:flutter/material.dart';

import 'models/drink_model.dart';
import 'services/cocktail_api_service.dart';
import 'utils/app_theme.dart';

void main() => runApp(const DrinkLabApp());

class DrinkLabApp extends StatelessWidget {
  const DrinkLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrinkLab',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final drink = settings.arguments is DrinkModel
              ? settings.arguments as DrinkModel
              : null;
          return MaterialPageRoute(
            builder: (_) => DrinkDetailScreen(drink: drink),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const DrinkLabShell());
      },
    );
  }
}

class DrinkLabShell extends StatefulWidget {
  const DrinkLabShell({super.key});

  @override
  State<DrinkLabShell> createState() => _DrinkLabShellState();
}

class _DrinkLabShellState extends State<DrinkLabShell> {
  int _selectedIndex = 0;

  static const List<_NavTab> _tabs = [
    _NavTab(icon: Icons.home_rounded, label: 'Home'),
    _NavTab(icon: Icons.kitchen_rounded, label: 'Bar'),
    _NavTab(icon: Icons.calculate_rounded, label: 'Drinkômetro'),
    _NavTab(icon: Icons.casino_rounded, label: 'Surpresa'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const _BarTab(),
      const _CalculatorTab(),
      const _RandomTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundAlt,
        selectedItemColor: AppTheme.accentGold,
        unselectedItemColor: AppTheme.textSecondary,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _service = CocktailApiService();
  final _searchController = TextEditingController();
  List<DrinkSummaryModel> _drinks = [];
  bool _loading = false;
  bool _loadingMore = false;
  String _error = '';
  final _scrollController = ScrollController();
  final _loadedIds = <String>{};
  bool _isSearching = false;

  static const int _initialLoad = 12;
  static const int _pageLoad = 8;

  @override
  void initState() {
    super.initState();
    _loadInitialRandoms();
    _scrollController.addListener(() {
      if (!_isSearching &&
          !_loading &&
          !_loadingMore &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300) {
        _loadMoreRandoms();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRandoms() async {
    setState(() {
      _loading = true;
      _error = '';
      _drinks = [];
      _loadedIds.clear();
    });

    try {
      final items = await _service.fetchRandomFromCatalog(_initialLoad);
      for (final it in items) {
        if (!_loadedIds.contains(it.id)) {
          _loadedIds.add(it.id);
          _drinks.add(it);
        }
      }
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreRandoms() async {
    if (_loading || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final items = await _service.fetchRandomFromCatalog(_pageLoad);
      var added = 0;
      for (final it in items) {
        if (!_loadedIds.contains(it.id)) {
          _loadedIds.add(it.id);
          _drinks.add(it);
          added++;
        }
      }
      if (added > 0) setState(() {});
    } catch (e) {
      // ignore load-more failures silently
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _search(String q) async {
    _isSearching = q.trim().isNotEmpty;
    if (!_isSearching) {
      await _loadInitialRandoms();
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _drinks = [];
      _loadedIds.clear();
    });

    try {
      final items = await _service.searchDrinks(q);
      setState(() => _drinks = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome do drink...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: _search,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _search(_searchController.text),
                  child: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_loading && _error.isNotEmpty)
              Expanded(child: Center(child: Text(_error))),
            if (!_loading && _error.isEmpty)
              Expanded(
                child: _drinks.isEmpty
                    ? const Center(child: Text('Nenhum drink encontrado.'))
                    : GridView.builder(
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: _drinks.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _drinks.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final d = _drinks[index];
                          return GestureDetector(
                            onTap: () async {
                              try {
                                final details = d is DrinkModel
                                    ? d
                                    : await _service.fetchDrinkDetails(d.id);
                                Navigator.pushNamed(
                                  context,
                                  '/detail',
                                  arguments: details,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao carregar detalhes'),
                                  ),
                                );
                              }
                            },
                            child: Card(
                              color: AppTheme.surface,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundAlt,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Center(
                                      child:
                                          d.thumbnailUrl != null &&
                                              d.thumbnailUrl!.isNotEmpty
                                          ? Image.network(
                                              d.thumbnailUrl!,
                                              fit: BoxFit.contain,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : Container(),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                d.category ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFFB0B8C2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              d.alcoholic ?? '',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFB0B8C2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarTab extends StatelessWidget {
  const _BarTab();

  @override
  Widget build(BuildContext context) {
    return const _BarTabBody();
  }
}

class _BarTabBody extends StatefulWidget {
  const _BarTabBody();

  @override
  State<_BarTabBody> createState() => _BarTabBodyState();
}

class _BarTabBodyState extends State<_BarTabBody> {
  final _service = CocktailApiService();
  List<FilterOptionModel> _ingredients = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final items = await _service.fetchFilterOptions('ingredients');
      setState(() => _ingredients = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showIngredientDetail(String name) async {
    try {
      final detail = await _service.searchIngredientByName(name);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(detail.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.imageUrlHigh.isNotEmpty)
                  Image.network(detail.imageUrlHigh, height: 120),
                const SizedBox(height: 8),
                if (detail.type != null) Text('Tipo: ${detail.type}'),
                if (detail.alcohol != null)
                  Text('Contém álcool: ${detail.alcohol! ? 'Sim' : 'Não'}'),
                if (detail.abv != null) Text('ABV: ${detail.abv}%'),
                const SizedBox(height: 8),
                if (detail.description != null) Text(detail.description!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar ingrediente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Ingredientes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_loading && _error.isNotEmpty)
              Expanded(child: Center(child: Text(_error))),
            if (!_loading && _error.isEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final item = _ingredients[index];
                    final encoded = Uri.encodeComponent(item.value.trim());
                    final imageUrl = encoded.isEmpty
                        ? ''
                        : 'https://www.thecocktaildb.com/images/ingredients/$encoded-Small.png';

                    return GestureDetector(
                      onTap: () => _showIngredientDetail(item.value),
                      child: Card(
                        color: AppTheme.backgroundAlt,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    imageUrl,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorTab extends StatelessWidget {
  const _CalculatorTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(child: Text('Tela: Drinkômetro / Calculadora para festas')),
    );
  }
}

class _RandomTab extends StatefulWidget {
  const _RandomTab();

  @override
  State<_RandomTab> createState() => _RandomTabState();
}

class _RandomTabState extends State<_RandomTab> {
  final _service = CocktailApiService();
  List<DrinkModel> _randoms = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRandoms();
  }

  Future<void> _loadRandoms() async {
    setState(() => _loading = true);
    try {
      final items = await _service.fetchRandomSelection();
      // deduplicate by id
      final map = <String, DrinkModel>{};
      for (var d in items) {
        map[d.id] = d;
      }
      setState(() => _randoms = map.values.toList());
    } catch (_) {
      // fallback: get 6 random unique
      final ids = <String>{};
      final list = <DrinkModel>[];
      for (var i = 0; i < 8; i++) {
        try {
          final d = await _service.fetchRandomDrink();
          if (!ids.contains(d.id)) {
            ids.add(d.id);
            list.add(d);
          }
        } catch (_) {}
      }
      setState(() => _randoms = list);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _surprise() async {
    try {
      final d = await _service.fetchRandomDrink();
      Navigator.pushNamed(context, '/detail', arguments: d);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erro ao sortear drink')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sorteios',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ElevatedButton(
                  onPressed: _surprise,
                  child: const Text('Surpresa'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loadRandoms,
                  child: const Text('Atualizar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_loading)
              Expanded(
                child: _randoms.isEmpty
                    ? const Center(child: Text('Nenhum drink sorteado'))
                    : ListView.separated(
                        itemCount: _randoms.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final d = _randoms[index];
                          return ListTile(
                            leading:
                                d.thumbnailUrl != null &&
                                    d.thumbnailUrl!.isNotEmpty
                                ? Image.network(
                                    d.thumbnailUrl!,
                                    width: 56,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            title: Text(d.name),
                            subtitle: Text(d.category ?? ''),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/detail',
                              arguments: d,
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class DrinkDetailScreen extends StatelessWidget {
  const DrinkDetailScreen({super.key, this.drink});

  final DrinkModel? drink;

  @override
  Widget build(BuildContext context) {
    final currentDrink =
        drink ??
        const DrinkModel(
          id: '0',
          name: 'Drink não encontrado',
          thumbnailUrl: '',
          ingredientsFull: [],
        );

    return Scaffold(
      appBar: AppBar(title: Text(currentDrink.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentDrink.thumbnailUrl != null &&
                currentDrink.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  currentDrink.thumbnailUrl!,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              currentDrink.name,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentDrink.category != null)
                  Chip(label: Text(currentDrink.category!)),
                if (currentDrink.alcoholic != null)
                  Chip(label: Text(currentDrink.alcoholic!)),
                if (currentDrink.glass != null)
                  Chip(label: Text(currentDrink.glass!)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ingredientes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (currentDrink.ingredientsFull.isEmpty)
              const Text('Nenhum ingrediente carregado para esta receita.')
            else
              ...currentDrink.ingredientsFull.map((ingredient) {
                final encoded = Uri.encodeComponent(ingredient.name.trim());
                final imageUrl = encoded.isEmpty
                    ? ''
                    : 'https://www.thecocktaildb.com/images/ingredients/$encoded-Small.png';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ingredient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(ingredient.measure ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
