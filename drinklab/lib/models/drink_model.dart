class DrinkSummaryModel {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? category;
  final String? alcoholic;
  final String? glass;
  final String? instructions;

  const DrinkSummaryModel({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.category,
    this.alcoholic,
    this.glass,
    this.instructions,
  });

  factory DrinkSummaryModel.fromJson(Map<String, dynamic> json) {
    final id = (json['idDrink'] ?? json['id'] ?? '').toString();
    final name = (json['strDrink'] ?? json['name'] ?? 'Drink sem nome')
        .toString();

    return DrinkSummaryModel(
      id: id,
      name: name,
      thumbnailUrl: (json['strDrinkThumb'] ?? json['thumbnailUrl'])?.toString(),
      category: (json['strCategory'] ?? json['category'])?.toString(),
      alcoholic: (json['strAlcoholic'] ?? json['alcoholic'])?.toString(),
      glass: (json['strGlass'] ?? json['glass'])?.toString(),
      instructions: (json['strInstructions'] ?? json['instructions'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idDrink': id,
      'strDrink': name,
      'strDrinkThumb': thumbnailUrl,
      'strCategory': category,
      'strAlcoholic': alcoholic,
      'strGlass': glass,
      'strInstructions': instructions,
    };
  }
}

class IngredientDetailModel {
  final String name;
  final String? description;
  final String? type;
  final bool? alcohol;
  final double? abv;
  final String imageUrlSmall;
  final String imageUrlMedium;
  final String imageUrlHigh;

  const IngredientDetailModel({
    required this.name,
    this.description,
    this.type,
    this.alcohol,
    this.abv,
    required this.imageUrlSmall,
    required this.imageUrlMedium,
    required this.imageUrlHigh,
  });

  factory IngredientDetailModel.fromJson(Map<String, dynamic> json) {
    final name =
        (json['strIngredient'] ?? json['strIngredient1'] ?? json['name'] ?? '')
            .toString();
    final description = (json['strDescription'] ?? '').toString();
    final type = (json['strType'] ?? '').toString();
    final strAlcohol = (json['strAlcohol'] ?? '').toString();
    final strAbv = (json['strABV'] ?? json['strAbv'] ?? '').toString();

    bool? alcohol;
    if (strAlcohol.isNotEmpty) {
      final lowered = strAlcohol.toLowerCase();
      alcohol =
          lowered == 'yes' ||
          lowered == 'true' ||
          lowered == 'alcohol' ||
          lowered == 'alcoholic';
    }

    double? abv;
    if (strAbv.isNotEmpty) {
      final parsed = double.tryParse(strAbv.replaceAll('%', ''));
      if (parsed != null) abv = parsed;
    }

    final encoded = Uri.encodeComponent(name.trim());

    return IngredientDetailModel(
      name: name,
      description: description.isEmpty ? null : description,
      type: type.isEmpty ? null : type,
      alcohol: alcohol,
      abv: abv,
      imageUrlSmall: encoded.isEmpty
          ? ''
          : 'https://www.thecocktaildb.com/images/ingredients/$encoded-Small.png',
      imageUrlMedium: encoded.isEmpty
          ? ''
          : 'https://www.thecocktaildb.com/images/ingredients/$encoded-Medium.png',
      imageUrlHigh: encoded.isEmpty
          ? ''
          : 'https://www.thecocktaildb.com/images/ingredients/$encoded.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strIngredient': name,
      'strDescription': description,
      'strType': type,
      'strAlcohol': alcohol == true ? 'Yes' : (alcohol == false ? 'No' : null),
      'strABV': abv?.toString(),
      'imageSmall': imageUrlSmall,
      'imageMedium': imageUrlMedium,
      'imageHigh': imageUrlHigh,
    }..removeWhere((key, value) => value == null);
  }
}

class DrinkIngredient {
  final String name;
  final String? measure;

  const DrinkIngredient({required this.name, this.measure});

  Map<String, dynamic> toJson() =>
      {'ingredient': name, 'measure': measure}
        ..removeWhere((k, v) => v == null);
}

class DrinkModel extends DrinkSummaryModel {
  final String? drinkAlternate;
  final String? tags;
  final String? video;
  final String? iba;
  final String? instructionsES;
  final String? instructionsDE;
  final String? instructionsFR;
  final String? instructionsIT;
  final String? imageSource;
  final String? imageAttribution;
  final String? creativeCommonsConfirmed;
  final String? dateModified;
  final List<DrinkIngredient> ingredientsFull;

  const DrinkModel({
    required super.id,
    required super.name,
    super.thumbnailUrl,
    super.category,
    super.alcoholic,
    super.glass,
    super.instructions,
    this.drinkAlternate,
    this.tags,
    this.video,
    this.iba,
    this.instructionsES,
    this.instructionsDE,
    this.instructionsFR,
    this.instructionsIT,
    this.imageSource,
    this.imageAttribution,
    this.creativeCommonsConfirmed,
    this.dateModified,
    this.ingredientsFull = const [],
  });

  factory DrinkModel.fromJson(Map<String, dynamic> json) {
    final ingredients = <DrinkIngredient>[];

    for (var i = 1; i <= 15; i++) {
      final ing = (json['strIngredient$i'] ?? '').toString().trim();
      if (ing.isEmpty) continue;
      final measure = (json['strMeasure$i'] ?? '').toString().trim();
      ingredients.add(
        DrinkIngredient(name: ing, measure: measure.isEmpty ? null : measure),
      );
    }

    return DrinkModel(
      id: (json['idDrink'] ?? json['id'] ?? '').toString(),
      name: (json['strDrink'] ?? json['name'] ?? 'Drink sem nome').toString(),
      thumbnailUrl: (json['strDrinkThumb'] ?? json['thumbnailUrl'])?.toString(),
      category: (json['strCategory'] ?? json['category'])?.toString(),
      alcoholic: (json['strAlcoholic'] ?? json['alcoholic'])?.toString(),
      glass: (json['strGlass'] ?? json['glass'])?.toString(),
      instructions: (json['strInstructions'] ?? json['instructions'])
          ?.toString(),
      drinkAlternate: (json['strDrinkAlternate'] ?? '').toString().isEmpty
          ? null
          : (json['strDrinkAlternate'] ?? '').toString(),
      tags: (json['strTags'] ?? '').toString().isEmpty
          ? null
          : (json['strTags'] ?? '').toString(),
      video: (json['strVideo'] ?? '').toString().isEmpty
          ? null
          : (json['strVideo'] ?? '').toString(),
      iba: (json['strIBA'] ?? '').toString().isEmpty
          ? null
          : (json['strIBA'] ?? '').toString(),
      instructionsES: (json['strInstructionsES'] ?? '').toString().isEmpty
          ? null
          : (json['strInstructionsES'] ?? '').toString(),
      instructionsDE: (json['strInstructionsDE'] ?? '').toString().isEmpty
          ? null
          : (json['strInstructionsDE'] ?? '').toString(),
      instructionsFR: (json['strInstructionsFR'] ?? '').toString().isEmpty
          ? null
          : (json['strInstructionsFR'] ?? '').toString(),
      instructionsIT: (json['strInstructionsIT'] ?? '').toString().isEmpty
          ? null
          : (json['strInstructionsIT'] ?? '').toString(),
      imageSource: (json['strImageSource'] ?? '').toString().isEmpty
          ? null
          : (json['strImageSource'] ?? '').toString(),
      imageAttribution: (json['strImageAttribution'] ?? '').toString().isEmpty
          ? null
          : (json['strImageAttribution'] ?? '').toString(),
      creativeCommonsConfirmed:
          (json['strCreativeCommonsConfirmed'] ?? '').toString().isEmpty
          ? null
          : (json['strCreativeCommonsConfirmed'] ?? '').toString(),
      dateModified: (json['dateModified'] ?? '').toString().isEmpty
          ? null
          : (json['dateModified'] ?? '').toString(),
      ingredientsFull: ingredients,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'strDrinkAlternate': drinkAlternate,
      'strTags': tags,
      'strVideo': video,
      'strIBA': iba,
      'strInstructionsES': instructionsES,
      'strInstructionsDE': instructionsDE,
      'strInstructionsFR': instructionsFR,
      'strInstructionsIT': instructionsIT,
      'strImageSource': imageSource,
      'strImageAttribution': imageAttribution,
      'strCreativeCommonsConfirmed': creativeCommonsConfirmed,
      'dateModified': dateModified,
      'ingredients': ingredientsFull.map((i) => i.toJson()).toList(),
    });

    return base..removeWhere((k, v) => v == null);
  }
}

class FilterOptionModel {
  final String label;
  final String value;

  const FilterOptionModel({required this.label, required this.value});

  factory FilterOptionModel.fromJson(
    Map<String, dynamic> json, {
    String key = 'strCategory',
  }) {
    final value = (json[key] ?? json['value'] ?? '').toString();
    final label = value.isEmpty ? 'Sem valor' : value;

    return FilterOptionModel(label: label, value: value);
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }
}
