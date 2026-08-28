import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../services/halal_service.dart';
import '../services/scan_history_service.dart';

class HalalScannerScreen extends StatefulWidget {
  const HalalScannerScreen({super.key});

  @override
  State<HalalScannerScreen> createState() => _HalalScannerScreenState();
}

class _HalalScannerScreenState extends State<HalalScannerScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  MobileScannerController? _cameraController;
  final _searchController = TextEditingController();
  late TabController _tabController;

  // State
  bool _isScanning = true;
  bool _isLoading = false;
  bool _torchOn = false;
  int _currentTab = 0; // 0=scan, 1=ocr, 2=search, 3=history
  ProductData? _productData;
  HalalVerdict? _verdict;
  String _ocrText = '';
  List<ScanHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
      if (_currentTab == 3) _loadHistory();
    });
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await ScanHistoryService.getHistory();
    if (mounted) setState(() => _history = h);
  }

  // ─── Barcode Scan ───────────────────────────────────────────
  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_isScanning || _isLoading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isScanning = false;
      _isLoading = true;
    });

    // Fetch from API
    final product = await HalalService.fetchProduct(barcode.rawValue!);

    if (product != null && product.name.isNotEmpty) {
      final verdict = HalalService.analyzeProduct(product);
      setState(() {
        _productData = product;
        _verdict = verdict;
        _isLoading = false;
      });

      // Save to history
      await ScanHistoryService.addScan(ScanHistoryItem(
        barcode: product.barcode,
        productName: product.name,
        brand: product.brand,
        status: verdict.status.name,
        verdictText: verdict.verdictText,
        confidence: verdict.confidence,
        imageUrl: product.imageUrl,
        scannedAt: DateTime.now(),
      ));
    } else {
      // Fallback — not found
      setState(() {
        _productData = null;
        _verdict = const HalalVerdict(
          status: HalalStatus.unknown,
          verdictText: 'Product Not Found',
          confidence: 0,
          haramIngredients: [],
          doubtfulIngredients: [],
          halalIndicators: [],
          warnings: ['Product not found in OpenFoodFacts database'],
          recommendations: [
            'Try scanning the ingredients label using OCR tab',
            'Or search by product name'
          ],
          ingredientsAnalyzed: false,
          totalIngredientsChecked: 0,
        );
        _isLoading = false;
      });
    }
  }

  // ─── OCR Scan ───────────────────────────────────────────────
  Future<void> _scanWithOCR() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final result = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = result.text;

      if (extractedText.isNotEmpty) {
        final verdict = HalalService.analyzeText(extractedText);
        setState(() {
          _ocrText = extractedText;
          _verdict = verdict;
          _productData = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _ocrText = '';
          _isLoading = false;
        });
        _showSnackbar('No text detected — try again with better lighting');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('OCR Error — try again');
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final result = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = result.text;

      if (extractedText.isNotEmpty) {
        final verdict = HalalService.analyzeText(extractedText);
        setState(() {
          _ocrText = extractedText;
          _verdict = verdict;
          _productData = null;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackbar('No text detected in image');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error reading image');
    }
  }

  // ─── Search ─────────────────────────────────────────────────
  void _searchProduct() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    HapticFeedback.mediumImpact();
    final verdict = HalalService.analyzeText(query);
    setState(() {
      _verdict = verdict;
      _productData = null;
    });
  }

  // ─── Reset ──────────────────────────────────────────────────
  void _resetScan() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _isLoading = false;
      _productData = null;
      _verdict = null;
      _ocrText = '';
      _searchController.clear();
    });
  }

  void _showSnackbar(String msg) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: colors.textPrimary)),
      backgroundColor: colors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildAppBarArea(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────
  Widget _buildAppBarArea() {
    final colors = QibraColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.background],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حَلَال / حَرَام',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontFamily: 'Amiri')),
                Text('Halal Scanner V2',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    color: colors.primary, size: 12),
                SizedBox(width: 4),
                Text('PRO',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() {
    final colors = QibraColors.of(context);
    final tabs = [
      const _TabItem(Icons.qr_code_scanner_rounded, 'Barcode'),
      const _TabItem(Icons.document_scanner_rounded, 'OCR'),
      const _TabItem(Icons.search_rounded, 'Search'),
      const _TabItem(Icons.history_rounded, 'History'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: colors.primary.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colors.primary,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        tabs: tabs
            .map((t) => Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icon, size: 14),
                      const SizedBox(width: 4),
                      Text(t.label),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Tab Content ────────────────────────────────────────────
  Widget _buildTabContent() {
    final colors = QibraColors.of(context);
    return TabBarView(
      controller: _tabController,
      children: [
        _buildBarcodeTab(),
        _buildOCRTab(),
        _buildSearchTab(),
        _buildHistoryTab(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: BARCODE SCANNER
  // ═══════════════════════════════════════════════════════════
  Widget _buildBarcodeTab() {
    final colors = QibraColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (_verdict == null && !_isLoading) _buildCameraView(),
          if (_isLoading) _buildLoadingView(),
          if (_verdict != null && !_isLoading) ...[
            _buildVerdictCard(),
            const SizedBox(height: 14),
            if (_productData != null) _buildProductDetails(),
            if (_productData != null) const SizedBox(height: 14),
            _buildIngredientsAnalysis(),
            const SizedBox(height: 14),
            _buildWarningsCard(),
            const SizedBox(height: 14),
            _buildRecommendationsCard(),
            const SizedBox(height: 14),
            _buildScanAgainButton(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: OCR
  // ═══════════════════════════════════════════════════════════
  Widget _buildOCRTab() {
    final colors = QibraColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // OCR Buttons
          Row(
            children: [
              Expanded(
                  child: _ocrButton(Icons.camera_alt_rounded, 'Take Photo',
                      _scanWithOCR, colors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ocrButton(Icons.photo_library_rounded, 'Gallery',
                      _pickFromGallery, colors.primarySoft)),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions
          if (_verdict == null && !_isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const Text('📸', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('Scan Ingredients Label',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Take a photo of the ingredients list on the back of the product packaging',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.4),
                        fontSize: 12,
                        height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _tipRow('💡', 'Good lighting helps accuracy'),
                  _tipRow('📐', 'Keep text straight and clear'),
                  _tipRow('🔍', 'Focus on ingredients section'),
                ],
              ),
            ),

          if (_isLoading) _buildLoadingView(),

          // OCR Text Preview
          if (_ocrText.isNotEmpty && _verdict != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_snippet_rounded,
                          color: colors.primary, size: 14),
                      const SizedBox(width: 8),
                      Text('DETECTED TEXT',
                          style: TextStyle(
                              color: colors.textPrimary.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_ocrText,
                      style: TextStyle(
                          color: colors.textPrimary.withValues(alpha: 0.6),
                          fontSize: 11,
                          height: 1.5),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildVerdictCard(),
            const SizedBox(height: 14),
            _buildIngredientsAnalysis(),
            const SizedBox(height: 14),
            _buildRecommendationsCard(),
            const SizedBox(height: 14),
            _buildScanAgainButton(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _ocrButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String emoji, String text) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: SEARCH
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchTab() {
    final colors = QibraColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: colors.textPrimary.withValues(alpha: 0.3), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchProduct(),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search product, ingredient, or E-code...',
                      hintStyle: TextStyle(
                          color: colors.textPrimary.withValues(alpha: 0.2),
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _searchProduct,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.search_rounded,
                        color: colors.textPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Search Chips
          if (_verdict == null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('gelatin'),
                _quickChip('E120'),
                _quickChip('E471'),
                _quickChip('pork'),
                _quickChip('alcohol'),
                _quickChip('lard'),
                _quickChip('carmine'),
                _quickChip('rennet'),
                _quickChip('shellac'),
                _quickChip('whey'),
                _quickChip('glycerin'),
                _quickChip('lecithin'),
              ],
            ),

          if (_verdict != null) ...[
            const SizedBox(height: 14),
            _buildVerdictCard(),
            const SizedBox(height: 14),
            _buildIngredientsAnalysis(),
            const SizedBox(height: 14),
            _buildRecommendationsCard(),
            const SizedBox(height: 14),
            _buildScanAgainButton(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _quickChip(String text) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _searchProduct();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
        ),
        child: Text(text,
            style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.5), fontSize: 12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: HISTORY
  // ═══════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    final colors = QibraColors.of(context);
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No Scan History',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text('Your scanned products will appear here',
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_history.length} scans',
                    style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.4),
                        fontSize: 12)),
                GestureDetector(
                  onTap: () async {
                    await ScanHistoryService.clearHistory();
                    _loadHistory();
                  },
                  child: Text('Clear All',
                      style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }

        final item = _history[i - 1];
        final color = _statusColor(item.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(item.status), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (item.brand.isNotEmpty)
                      Text(item.brand,
                          style: TextStyle(
                              color: colors.textPrimary.withValues(alpha: 0.4),
                              fontSize: 10)),
                    Text(_timeAgo(item.scannedAt),
                        style: TextStyle(
                            color: colors.textPrimary.withValues(alpha: 0.25),
                            fontSize: 9)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.verdictText,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildCameraView() {
    final colors = QibraColors.of(context);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: colors.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            MobileScanner(
                controller: _cameraController!, onDetect: _onBarcodeDetected),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                      width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _torchOn = !_torchOn);
                      _cameraController?.toggleTorch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _torchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: _torchOn
                                  ? colors.accent
                                  : Colors.white,
                              size: 16),
                          const SizedBox(width: 6),
                          Text('Point at barcode',
                              style: TextStyle(
                                  color: colors.textPrimary.withValues(alpha: 0.7),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
                color: colors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text('Analyzing Product...',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Checking 100+ ingredients & E-codes',
              style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVerdictCard() {
    final colors = QibraColors.of(context);
    final v = _verdict!;
    final color = _statusColor(v.status.name);
    final emoji = _statusEmoji(v.status.name);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.05)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(v.verdictText,
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.w900)),
          if (v.confidence > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  '${v.confidence}% confidence • ${v.totalIngredientsChecked} checks',
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final colors = QibraColors.of(context);
    final p = _productData!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: colors.primary, size: 14),
              const SizedBox(width: 8),
              Text('PRODUCT DETAILS',
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Name', p.name),
          if (p.brand.isNotEmpty) _detailRow('Brand', p.brand),
          if (p.categories.isNotEmpty) _detailRow('Category', p.categories),
          _detailRow('Barcode', p.barcode),
          if (p.countries.isNotEmpty) _detailRow('Country', p.countries),
          if (p.nutriscore.isNotEmpty)
            _detailRow('Nutri-Score', p.nutriscore.toUpperCase()),
          _detailRow('Halal Label',
              p.hasHalalCertification ? '✅ Found' : '❌ Not Found'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.35), fontSize: 11)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildIngredientsAnalysis() {
    final colors = QibraColors.of(context);
    final v = _verdict!;
    if (v.haramIngredients.isEmpty &&
        v.doubtfulIngredients.isEmpty &&
        v.halalIndicators.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded,
                  color: colors.primary, size: 14),
              const SizedBox(width: 8),
              Text('INGREDIENTS ANALYSIS',
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),

          // Haram
          ...v.haramIngredients.map((i) => _ingredientRow(
              i, colors.error, Icons.dangerous_rounded)),

          // Doubtful
          ...v.doubtfulIngredients.map((i) => _ingredientRow(
              i, colors.accent, Icons.warning_rounded)),

          // Halal
          ...v.halalIndicators.map((i) => _ingredientRow(
              i, colors.primary, Icons.check_circle_rounded)),
        ],
      ),
    );
  }

  Widget _ingredientRow(String text, Color color, IconData icon) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.6),
                      fontSize: 11,
                      height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildWarningsCard() {
    final colors = QibraColors.of(context);
    final warnings = _verdict?.warnings ?? [];
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: colors.accent, size: 14),
              const SizedBox(width: 8),
              Text('WARNINGS',
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 10),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️ ', style: TextStyle(fontSize: 10)),
                    Expanded(
                        child: Text(w,
                            style: TextStyle(
                                color: colors.textPrimary.withValues(alpha: 0.5),
                                fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final colors = QibraColors.of(context);
    final recs = _verdict?.recommendations ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: colors.primary, size: 14),
              const SizedBox(width: 8),
              Text('RECOMMENDATIONS',
                  style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 10),
          ...recs.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 10)),
                    Expanded(
                        child: Text(r,
                            style: TextStyle(
                                color: colors.textPrimary.withValues(alpha: 0.5),
                                fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScanAgainButton() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _resetScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [colors.primary, colors.primarySoft]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: colors.textPrimary, size: 22),
            SizedBox(width: 10),
            Text('Scan Again',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────
  Color _statusColor(String status) => switch (status) {
    final colors = QibraColors.of(context);
        'halal' || 'likelyHalal' => colors.primary,
        'haram' => colors.error,
        'doubtful' => colors.accent,
        _ => const Color(0xFF6B7280),
      };

  String _statusEmoji(String status) => switch (status) {
        'halal' || 'likelyHalal' => '✅',
        'haram' => '❌',
        'doubtful' => '⚠️',
        _ => '❓',
      };

  IconData _statusIcon(String status) => switch (status) {
        'halal' || 'likelyHalal' => Icons.check_circle_rounded,
        'haram' => Icons.dangerous_rounded,
        'doubtful' => Icons.warning_rounded,
        _ => Icons.help_outline_rounded,
      };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
