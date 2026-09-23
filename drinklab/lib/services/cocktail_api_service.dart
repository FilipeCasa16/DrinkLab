import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/drink_model.dart';

class CocktailApiService {
  CocktailApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://www.thecocktaildb.com/api/json/v1/1/';

  final http.Client _client;

  // Ingredient image helpers
  String ingredientImageHigh(String ingredient) =>
      'https://www.thecocktaildb.com/images/ingredients/${Uri.encodeComponent(ingredient)}.png';

  String ingredientImageMedium(String ingredient) =>
      'https://www.thecocktaildb.com/images/ingredients/${Uri.encodeComponent(ingredient)}-Medium.png';

  String ingredientImageSmall(String ingredient) =>
      'https://www.thecocktaildb.com/images/ingredients/${Uri.encodeComponent(ingredient)}-Small.png';

  // Simple in-memory caches to reduce repeated network calls during a session
  List<DrinkSummaryModel>? _allDrinksCache;
  List<IngredientDetailModel>? _allIngredientsCache;

  Future<List<DrinkSummaryModel>> searchDrinks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final data = await _getData(
      'search.php?s=${Uri.encodeQueryComponent(cleanQuery)}',
    );
    return _decodeDrinkSummaries(data);
  }

  Future<List<DrinkSummaryModel>> searchByFirstLetter(String letter) async {
    if (letter.trim().isEmpty) return const [];
    final data = await _getData(
      'search.php?f=${Uri.encodeQueryComponent(letter)}',
    );
    return _decodeDrinkSummaries(data);
  }

  Future<IngredientDetailModel> searchIngredientByName(String name) async {
    final data = await _getData(
      'search.php?i=${Uri.encodeQueryComponent(name)}',
    );
    final items = data['ingredients'] as List<dynamic>? ?? const [];
    if (items.isEmpty) throw Exception('Ingrediente não encontrado: $name');
    return IngredientDetailModel.fromJson(items.first as Map<String, dynamic>);
  }

  Future<List<DrinkSummaryModel>> filterCocktails({
    String? category,
    String? glass,
    String? ingredient,
    String? alcoholic,
  }) async {
    final filters = <String>[];

    if (category != null && category.isNotEmpty) {
      filters.add('c=${Uri.encodeQueryComponent(category)}');
    }
    if (glass != null && glass.isNotEmpty) {
      filters.add('g=${Uri.encodeQueryComponent(glass)}');
    }
    if (ingredient != null && ingredient.isNotEmpty) {
      filters.add('i=${Uri.encodeQueryComponent(ingredient)}');
    }
    if (alcoholic != null && alcoholic.isNotEmpty) {
      filters.add('a=${Uri.encodeQueryComponent(alcoholic)}');
    }

    if (filters.isEmpty) {
      return const [];
    }

    final endpoint = 'filter.php?${filters.join('&')}';
    final data = await _getData(endpoint);
    return _decodeDrinkSummaries(data);
  }

  /// Support multi-ingredient filter (comma-separated)
  Future<List<DrinkSummaryModel>> filterByIngredients(
    List<String> ingredients,
  ) async {
    if (ingredients.isEmpty) return const [];
    final joined = ingredients
        .map((s) => Uri.encodeQueryComponent(s))
        .join(',');
    final data = await _getData('filter.php?i=$joined');
    return _decodeDrinkSummaries(data);
  }

  Future<List<DrinkSummaryModel>> fetchNonAlcoholicDrinks() async {
    final data = await _getData('filter.php?a=Non_Alcoholic');
    return _decodeDrinkSummaries(data);
  }

  Future<List<FilterOptionModel>> fetchFilterOptions(String type) async {
    final endpoint = switch (type) {
      'categories' => 'list.php?c=list',
      'glasses' => 'list.php?g=list',
      'ingredients' => 'list.php?i=list',
      'alcoholic' => 'list.php?a=list',
      _ => 'list.php?c=list',
    };

    final data = await _getData(endpoint);
    final items = data['drinks'] as List<dynamic>? ?? const [];

    return items
        .map(
          (item) => FilterOptionModel.fromJson(
            item as Map<String, dynamic>,
            key: switch (type) {
              'categories' => 'strCategory',
              'glasses' => 'strGlass',
              'ingredients' => 'strIngredient1',
              'alcoholic' => 'strAlcoholic',
              _ => 'strCategory',
            },
          ),
        )
        .toList();
  }

  // Lookup ingredient by id
  Future<IngredientDetailModel> lookupIngredientById(String id) async {
    final data = await _getData(
      'lookup.php?iid=${Uri.encodeQueryComponent(id)}',
    );
    final items = data['ingredients'] as List<dynamic>? ?? const [];
    if (items.isEmpty)
      throw Exception('Ingrediente não encontrado para o ID $id');
    return IngredientDetailModel.fromJson(items.first as Map<String, dynamic>);
  }

  // random selection (may return multiple drinks)
  Future<List<DrinkModel>> fetchRandomSelection() async {
    try {
      final data = await _getData('randomselection.php');
      final drinks = data['drinks'] as List<dynamic>? ?? const [];
      return drinks
          .whereType<Map<String, dynamic>>()
          .map(DrinkModel.fromJson)
          .toList();
    } catch (_) {
      // fallback: fetch 10 times random.php (best-effort)
      final results = <DrinkModel>[];
      for (var i = 0; i < 10; i++) {
        try {
          final d = await fetchRandomDrink();
          results.add(d);
        } catch (_) {
          // skip
        }
      }
      return results;
    }
  }

  // popular and latest
  Future<List<DrinkSummaryModel>> fetchPopular() async {
    final data = await _getData('popular.php');
    return _decodeDrinkSummaries(data);
  }

  Future<List<DrinkSummaryModel>> fetchLatest() async {
    final data = await _getData('latest.php');
    return _decodeDrinkSummaries(data);
  }

  Future<DrinkModel> fetchDrinkDetails(String drinkId) async {
    final data = await _getData(
      'lookup.php?i=${Uri.encodeQueryComponent(drinkId)}',
    );
    final drinks = data['drinks'] as List<dynamic>? ?? const [];

    if (drinks.isEmpty) {
      throw Exception('Nenhuma bebida encontrada para o ID $drinkId.');
    }

    return DrinkModel.fromJson(drinks.first as Map<String, dynamic>);
  }

  Future<DrinkModel> fetchRandomDrink() async {
    final data = await _getData('random.php');
    final drinks = data['drinks'] as List<dynamic>? ?? const [];

    if (drinks.isEmpty) {
      throw Exception('Não foi possível sortear uma bebida no momento.');
    }

    return DrinkModel.fromJson(drinks.first as Map<String, dynamic>);
  }

  /// Fetch all drinks by iterating first letters (a-z, 0-9) and aggregating unique results.
  Future<List<DrinkSummaryModel>> fetchAllDrinks({
    bool forceReload = false,
  }) async {
    if (!forceReload && _allDrinksCache != null) return _allDrinksCache!;

    final letters = <String>[];
    for (var c = 97; c <= 122; c++) letters.add(String.fromCharCode(c)); // a-z
    for (var d = 0; d <= 9; d++) letters.add(d.toString());

    final map = <String, DrinkSummaryModel>{};

    for (final l in letters) {
      try {
        final data = await _getData(
          'search.php?f=${Uri.encodeQueryComponent(l)}',
        );
        final items = _decodeDrinkSummaries(data);
        for (final it in items) {
          map[it.id] = it;
        }
      } catch (_) {
        // ignore single-letter failures
      }
    }

    _allDrinksCache = map.values.toList();
    return _allDrinksCache!;
  }

  /// Fetch a detailed list of all ingredients (calls list.php then detail per ingredient)
  Future<List<IngredientDetailModel>> fetchAllIngredientsDetailed({
    bool forceReload = false,
  }) async {
    if (!forceReload && _allIngredientsCache != null)
      return _allIngredientsCache!;

    final list = await fetchFilterOptions('ingredients');
    final results = <IngredientDetailModel>[];

    for (final item in list) {
      try {
        final detail = await searchIngredientByName(item.value);
        results.add(detail);
      } catch (_) {
        // ignore individual failures
      }
    }

    _allIngredientsCache = results;
    return _allIngredientsCache!;
  }

  /// Pick N unique random drinks from the cached full catalog (falls back to API random)
  Future<List<DrinkModel>> fetchRandomFromCatalog(int count) async {
    final catalog = _allDrinksCache ?? await fetchAllDrinks();
    if (catalog.isEmpty)
      return Future.wait(List.generate(count, (_) => fetchRandomDrink()));

    final rnd = <DrinkModel>[];
    final ids = <String>{};
    final random = Random();

    while (rnd.length < count && ids.length < catalog.length) {
      final pick = catalog[random.nextInt(catalog.length)];
      if (ids.contains(pick.id)) continue;
      ids.add(pick.id);
      try {
        final full = await fetchDrinkDetails(pick.id);
        rnd.add(full);
      } catch (_) {
        // skip
      }
    }

    if (rnd.isEmpty) {
      return Future.wait(List.generate(count, (_) => fetchRandomDrink()));
    }

    return rnd;
  }

  Future<Map<String, dynamic>> _getData(String endpoint) async {
    final response = await _client.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode != 200) {
      throw Exception('Erro na API do CocktailDB: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta inesperada da API do CocktailDB.');
    }

    return decoded;
  }

  List<DrinkSummaryModel> _decodeDrinkSummaries(Map<String, dynamic> data) {
    final drinks = data['drinks'] as List<dynamic>? ?? const [];

    return drinks
        .whereType<Map<String, dynamic>>()
        .map(DrinkSummaryModel.fromJson)
        .toList();
  }
}
