import 'dart:convert';
import 'package:http/http.dart' as http;

class HalalService {
  static const String _openFoodFactsBase =
      'https://world.openfoodfacts.org/api/v2/product';

  // ─── Fetch Product from OpenFoodFacts API ───────────────────
  static Future<ProductData?> fetchProduct(String barcode) async {
    try {
      final url = '$_openFoodFactsBase/$barcode.json';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['status'] != 1) return null;

      final product = json['product'];
      if (product == null) return null;

      final name = product['product_name'] ?? product['product_name_en'] ?? '';
      final brand = product['brands'] ?? '';
      final categories = product['categories'] ?? '';
      final ingredients =
          product['ingredients_text'] ?? product['ingredients_text_en'] ?? '';
      final imageUrl = product['image_front_url'] ?? product['image_url'] ?? '';
      final nutriscore = product['nutriscore_grade'] ?? '';
      final countries = product['countries'] ?? '';
      final labels = product['labels'] ?? '';
      final allergens = product['allergens'] ?? '';
      final traces = product['traces'] ?? '';

      // Check for halal labels
      final allLabels = labels.toString().toLowerCase();
      final hasHalalLabel = allLabels.contains('halal');

      return ProductData(
        barcode: barcode,
        name: name.toString(),
        brand: brand.toString(),
        categories: categories.toString(),
        ingredients: ingredients.toString(),
        imageUrl: imageUrl.toString(),
        nutriscore: nutriscore.toString(),
        countries: countries.toString(),
        labels: labels.toString(),
        allergens: allergens.toString(),
        traces: traces.toString(),
        hasHalalCertification: hasHalalLabel,
      );
    } catch (e) {
      return null;
    }
  }

  // ─── MASTER ANALYSIS ENGINE ─────────────────────────────────
  static HalalVerdict analyzeProduct(ProductData product) {
    final ingredients = product.ingredients.toLowerCase();
    final name = product.name.toLowerCase();
    final brand = product.brand.toLowerCase();

    List<String> haramFound = [];
    List<String> doubtfulFound = [];
    List<String> halalFound = [];
    List<String> warnings = [];
    List<String> recommendations = [];

    // ── Step 1: Check Halal Certification ──
    if (product.hasHalalCertification) {
      halalFound.add('Product has Halal certification label');
    }

    // ── Step 2: Check Haram Ingredients ──
    // P0.3/ Halal fix: avoid false positive for vegetable gelatin
    bool isVegetableGelatin(String ing) {
      return ing.contains('vegetable gelatin') ||
          ing.contains('agar') ||
          ing.contains('pectin') ||
          ing.contains('carrageenan') ||
          ing.contains('vegetarian gelatin');
    }

    for (final item in _haramDatabase) {
      // Skip gelatin if plant-based alternative explicitly mentioned
      if (item.name == 'Gelatin' && isVegetableGelatin(ingredients)) {
        halalFound.add(
            'Contains vegetable/agar gelatin — plant-based, not haram pork gelatin');
        continue;
      }
      if (ingredients.contains(item.name.toLowerCase()) ||
          name.contains(item.name.toLowerCase())) {
        // Double-check gelatin case inside generic match too
        if (item.name == 'Gelatin' && isVegetableGelatin(ingredients)) continue;
        haramFound.add('${item.name}: ${item.reason}');
      }
      for (final alias in item.aliases) {
        if (ingredients.contains(alias.toLowerCase())) {
          if (item.name == 'Gelatin' && isVegetableGelatin(ingredients))
            continue;
          haramFound.add('${item.name} (as $alias): ${item.reason}');
        }
      }
    }

    // ── Step 3: Check E-Codes ──
    for (final ecode in _eCodeDatabase) {
      if (ingredients.contains(ecode.code.toLowerCase())) {
        // E441 gelatin — check vegetable alternative
        if (ecode.code == 'e441' && ingredients.contains('vegetable')) continue;
        if (ecode.status == 'haram') {
          haramFound.add('${ecode.code} (${ecode.name}): ${ecode.reason}');
        } else if (ecode.status == 'doubtful') {
          doubtfulFound.add('${ecode.code} (${ecode.name}): ${ecode.reason}');
        }
      }
    }

    // ── Step 4: Check Doubtful Ingredients ──
    for (final item in _doubtfulDatabase) {
      if (ingredients.contains(item.name.toLowerCase())) {
        doubtfulFound.add('${item.name}: ${item.reason}');
      }
      for (final alias in item.aliases) {
        if (ingredients.contains(alias.toLowerCase())) {
          doubtfulFound.add('${item.name} (as $alias): ${item.reason}');
        }
      }
    }

    // ── Step 5: Check Known Haram Brands ──
    for (final entry in _haramBrands) {
      if (brand.contains(entry.toLowerCase()) ||
          name.contains(entry.toLowerCase())) {
        haramFound.add('Brand "$entry" is known for non-Halal products');
      }
    }

    // ── Step 6: Alcohol Check ──
    if (_containsAlcohol(ingredients, name)) {
      haramFound.add('Contains alcohol / alcoholic content');
    }

    // ── Step 7: Generate Warnings ──
    // Persistent disclaimer (Phase 5): heuristic does not replace certification
    warnings.add(
        'Ingredient analysis is heuristic and does not replace certification from a trusted Halal authority.');
    // Structured tags preferred: OFF provides ingredients_tags (e.g., en:gelatin) which are exact; fallback to text substring is less precise.
    // TODO: Prefer product.ingredientsTags where available (exact match) over substring on ingredients_text.
    if (ingredients.isEmpty) {
      warnings.add(
          'No ingredients data available — verify manually with manufacturer');
    }
    if (!product.hasHalalCertification) {
      warnings.add('No Halal certification found on this product');
    } else {
      // Certification priority: if certified halal, heuristic haram findings are less certain (possible labeling error but cert takes precedence for confidence)
      warnings.add(
          'Halal certification found — certification takes priority over ingredient heuristics, but verify cert validity.');
    }
    if (product.allergens.toLowerCase().contains('milk') ||
        product.allergens.toLowerCase().contains('eggs')) {
      warnings.add('Contains animal-derived allergens — verify source');
    }

    // ── Step 8: Generate Recommendations ──
    if (haramFound.isNotEmpty) {
      recommendations.add('Avoid this product — contains Haram ingredients');
      recommendations.add('Look for Halal-certified alternatives');
    } else if (doubtfulFound.isNotEmpty) {
      recommendations.add('Contact manufacturer to verify ingredient sources');
      recommendations.add('Look for Halal-certified version of this product');
      recommendations.add('When in doubt, it is better to avoid');
    } else {
      recommendations.add('Always check for Halal certification on packaging');
      recommendations.add('Ingredients can change — re-verify periodically');
    }

    // ── Step 9: Determine Final Verdict (Phase 5: certification priority, reduced heuristic confidence) ──
    HalalStatus status;
    String verdictText;
    int confidence;

    if (haramFound.isNotEmpty) {
      status = HalalStatus.haram;
      // Distinguish: confirmed haram (certified haram label or pork/alcohol) vs heuristic substring
      // For now, haram via heuristic substring without certification → lower confidence (65)
      // If hasHalalCertification but haram found, it's conflicting → lower confidence and warn
      if (product.hasHalalCertification) {
        verdictText =
            'Conflicting: Halal Certified but Haram Ingredients Detected — Verify Cert';
        confidence = 65;
        warnings.add(
            'Product claims Halal certification but ingredients analysis flagged Haram — verify certification with authority.');
      } else {
        verdictText = 'Contains Haram Ingredients (Heuristic)';
        // Heuristic-only: 65 (not 95 definitive). 95 only if OFF explicitly tags haram or lab confirmed.
        confidence = ingredients.isNotEmpty ? 65 : 45;
      }
    } else if (doubtfulFound.isNotEmpty) {
      status = HalalStatus.doubtful;
      verdictText = 'Contains Doubtful Ingredients';
      confidence = 60; // reduced from 70 for heuristic
    } else if (product.hasHalalCertification) {
      status = HalalStatus.halal;
      verdictText = 'Halal Certified';
      confidence =
          92; // high but not 100 — cert could be expired/forged, still heuristic ingredient check passed
    } else if (ingredients.isNotEmpty &&
        haramFound.isEmpty &&
        doubtfulFound.isEmpty) {
      status = HalalStatus.likelyHalal;
      verdictText = 'Likely Halal (Heuristic)';
      confidence = 55; // reduced from 75 — heuristic only, no cert
      warnings.add(
          'No Haram/Doubtful ingredients detected via heuristic, but without Halal certification this is not a guarantee.');
    } else {
      status = HalalStatus.unknown;
      verdictText = 'Unable to Determine';
      confidence = 0;
    }

    return HalalVerdict(
      status: status,
      verdictText: verdictText,
      confidence: confidence,
      haramIngredients: haramFound,
      doubtfulIngredients: doubtfulFound,
      halalIndicators: halalFound,
      warnings: warnings,
      recommendations: recommendations,
      ingredientsAnalyzed: ingredients.isNotEmpty,
      totalIngredientsChecked: _haramDatabase.length +
          _eCodeDatabase.length +
          _doubtfulDatabase.length,
    );
  }

  // ─── Analyze Text (OCR / Manual) ───────────────────────────
  static HalalVerdict analyzeText(String text) {
    final fakeProduct = ProductData(
      barcode: '',
      name: 'Manual Check',
      brand: '',
      categories: '',
      ingredients: text,
      imageUrl: '',
      nutriscore: '',
      countries: '',
      labels: '',
      allergens: '',
      traces: '',
      hasHalalCertification: false,
    );
    return analyzeProduct(fakeProduct);
  }

  // ─── Alcohol Detection ─────────────────────────────────────
  static bool _containsAlcohol(String ingredients, String name) {
    final alcoholTerms = [
      'alcohol',
      'ethanol',
      'ethyl alcohol',
      'wine',
      'beer',
      'rum',
      'vodka',
      'whiskey',
      'whisky',
      'brandy',
      'gin',
      'champagne',
      'sake',
      'malt liquor',
      'liqueur',
      'liquor',
      'tequila',
      'absinthe',
      'bourbon',
      'scotch',
      'cognac',
      'port wine',
      'sherry',
      'vermouth',
      'mead',
      'cider',
      'alcoholic',
      'brewing',
      'distilled spirits',
    ];

    for (final term in alcoholTerms) {
      if (ingredients.contains(term) || name.contains(term)) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════
  // COMPREHENSIVE DATABASES
  // ═══════════════════════════════════════════════════════════

  static const List<_IngredientEntry> _haramDatabase = [
    _IngredientEntry('Pork', 'Derived from pig — strictly Haram',
        ['swine', 'pig', 'porcine', 'sus scrofa']),
    _IngredientEntry(
        'Lard', 'Pig fat — Haram', ['pork fat', 'pig fat', 'schmaltz']),
    _IngredientEntry('Gelatin', 'Usually from pork/non-halal animals',
        ['gelatine', 'pork gelatin', 'bovine gelatin']),
    _IngredientEntry(
        'Pepsin', 'Enzyme from pig stomach lining', ['porcine pepsin']),
    _IngredientEntry('Carmine', 'Red dye from crushed insects',
        ['cochineal', 'natural red 4', 'crimson lake']),
    _IngredientEntry('Rennet', 'From non-halal slaughtered animal stomach',
        ['animal rennet', 'calf rennet']),
    _IngredientEntry('Bacon', 'Pork product — Haram',
        ['bacon bits', 'bacon flavor', 'bacon fat']),
    _IngredientEntry(
        'Ham', 'Pork product — Haram', ['prosciutto', 'gammon', 'pork ham']),
    _IngredientEntry('Pepperoni', 'Usually contains pork', ['pork pepperoni']),
    _IngredientEntry('Salami', 'Usually contains pork', ['pork salami']),
    _IngredientEntry('Sausage', 'May contain pork — verify source',
        ['pork sausage', 'hot dog']),
    _IngredientEntry('Blood', 'Blood of any animal is Haram',
        ['blood pudding', 'blood sausage', 'black pudding']),
    _IngredientEntry('L-Cysteine', 'Often from human hair or duck feathers',
        ['l cysteine', 'e920', 'cysteine']),
    _IngredientEntry('Tallow', 'Rendered beef/pork fat', ['animal tallow']),
    _IngredientEntry('Shellac', 'Insect secretion — Haram per many scholars',
        ['confectioner\'s glaze', 'resinous glaze']),
    _IngredientEntry('Bone Char', 'Used in sugar processing from animal bones',
        ['bone charcoal']),
    _IngredientEntry('Collagen', 'Usually from non-halal animal sources',
        ['marine collagen', 'bovine collagen', 'porcine collagen']),
    _IngredientEntry(
        'Aspic', 'Meat jelly — usually from non-halal sources', []),
    _IngredientEntry('Suet', 'Hard fat around kidneys — usually beef/pork', []),
    _IngredientEntry('Dripping', 'Animal fat from roasting',
        ['beef dripping', 'pork dripping']),
  ];

  static const List<_IngredientEntry> _doubtfulDatabase = [
    _IngredientEntry('Glycerin', 'Can be plant or animal-derived',
        ['glycerol', 'glycerine', 'e422']),
    _IngredientEntry('Lecithin', 'Usually soy-based but can be animal',
        ['e322', 'soy lecithin', 'soya lecithin']),
    _IngredientEntry(
        'Natural Flavors',
        'Source unclear — could be animal-derived',
        ['natural flavours', 'natural flavoring', 'natural flavouring']),
    _IngredientEntry(
        'Emulsifier', 'Could be plant or animal-derived', ['emulsifiers']),
    _IngredientEntry('Whey', 'Dairy byproduct — rennet source matters',
        ['whey powder', 'whey protein', 'sweet whey']),
    _IngredientEntry('Casein', 'Milk protein — generally halal but verify',
        ['sodium caseinate', 'calcium caseinate', 'caseinates']),
    _IngredientEntry('Mono Diglycerides', 'Can be from animal fat',
        ['mono and diglycerides', 'monoglycerides', 'diglycerides']),
    _IngredientEntry(
        'Stearic Acid', 'Can be animal or plant-derived', ['e570', 'stearate']),
    _IngredientEntry(
        'Magnesium Stearate', 'Source can be animal fat', ['e572']),
    _IngredientEntry('Enzyme', 'Source matters — animal or microbial',
        ['enzymes', 'lipase', 'protease', 'amylase']),
    _IngredientEntry('Vanilla Extract', 'May contain ethanol as solvent',
        ['vanilla essence']),
    _IngredientEntry('Calcium Phosphate', 'Can be from bone ash', ['e341']),
    _IngredientEntry('Vitamin D3', 'Often from lanolin (sheep wool) or fish',
        ['cholecalciferol']),
    _IngredientEntry('Omega 3', 'Usually from fish — verify source',
        ['fish oil', 'cod liver oil']),
    _IngredientEntry('Confectioner Glaze',
        'May contain shellac (insect-derived)', ['pharmaceutical glaze']),
  ];

  static const List<_ECodeEntry> _eCodeDatabase = [
    // Haram E-Codes
    _ECodeEntry(
        'E120', 'Carmine / Cochineal', 'haram', 'Insect-derived red dye'),
    _ECodeEntry('E441', 'Gelatin', 'haram', 'Usually pork-derived'),
    _ECodeEntry('E542', 'Bone Phosphate', 'haram', 'From animal bones'),
    _ECodeEntry('E904', 'Shellac', 'haram', 'Insect secretion'),
    _ECodeEntry('E920', 'L-Cysteine', 'haram', 'Often from human hair'),
    _ECodeEntry('E921', 'L-Cystine', 'haram', 'Often from human hair'),
    _ECodeEntry(
        'E252', 'Potassium Nitrate', 'haram', 'Used in pork processing'),
    _ECodeEntry(
        'E631', 'Disodium Inosinate', 'haram', 'Often from animal sources'),
    _ECodeEntry('E635', 'Disodium Ribonucleotides', 'haram',
        'Often from animal sources'),

    // Doubtful E-Codes
    _ECodeEntry('E471', 'Mono & Diglycerides', 'doubtful',
        'Can be plant or animal-derived'),
    _ECodeEntry(
        'E472', 'Esters of Mono & Diglycerides', 'doubtful', 'Source unclear'),
    _ECodeEntry('E473', 'Sucrose Esters', 'doubtful', 'May use animal fats'),
    _ECodeEntry('E474', 'Sucroglycerides', 'doubtful', 'May use animal fats'),
    _ECodeEntry(
        'E475', 'Polyglycerol Esters', 'doubtful', 'May be animal-derived'),
    _ECodeEntry('E476', 'Polyglycerol Polyricinoleate', 'doubtful',
        'Usually plant but verify'),
    _ECodeEntry('E477', 'Propane Diol Esters', 'doubtful', 'Source varies'),
    _ECodeEntry('E481', 'Sodium Stearoyl Lactylate', 'doubtful',
        'Stearic acid source matters'),
    _ECodeEntry('E482', 'Calcium Stearoyl Lactylate', 'doubtful',
        'Stearic acid source matters'),
    _ECodeEntry('E483', 'Stearyl Tartrate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry(
        'E491', 'Sorbitan Monostearate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry(
        'E492', 'Sorbitan Tristearate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry(
        'E493', 'Sorbitan Monolaurate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry(
        'E494', 'Sorbitan Monooleate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry(
        'E495', 'Sorbitan Monopalmitate', 'doubtful', 'Animal fat possible'),
    _ECodeEntry('E322', 'Lecithin', 'doubtful', 'Usually soy but verify'),
    _ECodeEntry('E422', 'Glycerol', 'doubtful', 'Can be animal-derived'),
    _ECodeEntry('E433', 'Polysorbate 80', 'doubtful', 'Source varies'),
    _ECodeEntry('E434', 'Polysorbate 40', 'doubtful', 'Source varies'),
    _ECodeEntry('E435', 'Polysorbate 60', 'doubtful', 'Source varies'),
    _ECodeEntry('E436', 'Polysorbate 65', 'doubtful', 'Source varies'),
    _ECodeEntry('E570', 'Stearic Acid', 'doubtful', 'Can be animal-derived'),
  ];

  static const List<String> _haramBrands = [
    'jack daniels',
    'heineken',
    'budweiser',
    'smirnoff',
    'absolut',
    'bacardi',
    'johnnie walker',
    'grey goose',
    'corona beer',
    'guinness',
    'carlsberg',
  ];
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

class ProductData {
  final String barcode;
  final String name;
  final String brand;
  final String categories;
  final String ingredients;
  final String imageUrl;
  final String nutriscore;
  final String countries;
  final String labels;
  final String allergens;
  final String traces;
  final bool hasHalalCertification;

  const ProductData({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.categories,
    required this.ingredients,
    required this.imageUrl,
    required this.nutriscore,
    required this.countries,
    required this.labels,
    required this.allergens,
    required this.traces,
    required this.hasHalalCertification,
  });
}

enum HalalStatus { halal, haram, doubtful, likelyHalal, unknown }

class HalalVerdict {
  final HalalStatus status;
  final String verdictText;
  final int confidence;
  final List<String> haramIngredients;
  final List<String> doubtfulIngredients;
  final List<String> halalIndicators;
  final List<String> warnings;
  final List<String> recommendations;
  final bool ingredientsAnalyzed;
  final int totalIngredientsChecked;

  const HalalVerdict({
    required this.status,
    required this.verdictText,
    required this.confidence,
    required this.haramIngredients,
    required this.doubtfulIngredients,
    required this.halalIndicators,
    required this.warnings,
    required this.recommendations,
    required this.ingredientsAnalyzed,
    required this.totalIngredientsChecked,
  });
}

class _IngredientEntry {
  final String name;
  final String reason;
  final List<String> aliases;
  const _IngredientEntry(this.name, this.reason, this.aliases);
}

class _ECodeEntry {
  final String code;
  final String name;
  final String status;
  final String reason;
  const _ECodeEntry(this.code, this.name, this.status, this.reason);
}
