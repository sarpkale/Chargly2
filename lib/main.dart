import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CharglyApp());
}

class CharglyApp extends StatelessWidget {
  const CharglyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chargly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08131F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39D6C0),
          brightness: Brightness.dark,
          surface: const Color(0xFF111F2D),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const CharglyDashboard(),
    );
  }
}

class UsageScenario {
  const UsageScenario({
    required this.name,
    required this.description,
    required this.baseConsumptionMa,
    required this.icon,
  });

  final String name;
  final String description;
  final double baseConsumptionMa;
  final IconData icon;
}

class PhoneModel {
  const PhoneModel({
    required this.name,
    required this.batteryCapacityMah,
    required this.capacityNote,
  });

  final String name;
  final int batteryCapacityMah;
  final String capacityNote;
}

class CharglyDashboard extends StatefulWidget {
  const CharglyDashboard({super.key});

  @override
  State<CharglyDashboard> createState() => _CharglyDashboardState();
}

class _CharglyDashboardState extends State<CharglyDashboard> {
  static const _accent = Color(0xFF39D6C0);
  static const _muted = Color(0xFF91A4B7);
  static const _panel = Color(0xFF111F2D);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _phones = [
    PhoneModel(
      name: 'Apple iPhone 14',
      batteryCapacityMah: 3279,
      capacityNote: 'Yaklaşık hücre kapasitesi; Apple mAh değeri yayımlamaz',
    ),
    PhoneModel(
      name: 'Apple iPhone 15',
      batteryCapacityMah: 3349,
      capacityNote: 'Yaklaşık hücre kapasitesi; Apple mAh değeri yayımlamaz',
    ),
    PhoneModel(
      name: 'Apple iPhone 16',
      batteryCapacityMah: 3561,
      capacityNote: 'Yaklaşık hücre kapasitesi; Apple mAh değeri yayımlamaz',
    ),
    PhoneModel(
      name: 'Samsung Galaxy S24',
      batteryCapacityMah: 4000,
      capacityNote: 'Samsung tipik kapasite değeri',
    ),
    PhoneModel(
      name: 'Samsung Galaxy S24 Ultra',
      batteryCapacityMah: 5000,
      capacityNote: 'Samsung tipik kapasite değeri',
    ),
    PhoneModel(
      name: 'Samsung Galaxy A55 5G',
      batteryCapacityMah: 5000,
      capacityNote: 'Samsung tipik kapasite değeri',
    ),
  ];
  bool _aiLoading = false;
  String _aiSuggestion = '';
  String? _aiError;

  static const _scenarios = [
    UsageScenario(
      name: 'Sosyal medya',
      description: 'Akış, fotoğraf ve kısa videolar',
      baseConsumptionMa: 520,
      icon: Icons.people_alt_outlined,
    ),
    UsageScenario(
      name: 'Oyun',
      description: 'Ekran ve işlemci yoğun kullanım',
      baseConsumptionMa: 1250,
      icon: Icons.sports_esports_outlined,
    ),
    UsageScenario(
      name: 'Müzik',
      description: 'Ekran çoğunlukla kapalı, ses çalma',
      baseConsumptionMa: 170,
      icon: Icons.headphones_rounded,
    ),
  ];

  int _percentage = 45;
  int _selectedScenario = 2;
  int _selectedPhone = 0;
  int _brightness = 1;
  int _batteryHealth = 90;
  bool _locationEnabled = false;
  bool _mobileDataEnabled = true;
  bool _calculationConfirmed = false;

  UsageScenario get _scenario => _scenarios[_selectedScenario];
  PhoneModel get _phone => _phones[_selectedPhone];

  double get _brightnessFactor => switch (_brightness) {
    0 => 0.85,
    1 => 1.0,
    _ => 1.25,
  };

  double get _estimatedConsumptionMa {
    final screenFactor = _scenario.name == 'Müzik'
        ? 1 + (_brightnessFactor - 1) * 0.15
        : _brightnessFactor;
    final locationDraw = _locationEnabled
        ? switch (_selectedScenario) {
            0 => 90,
            1 => 70,
            _ => 15,
          }
        : 0;
    final mobileDataDraw = _mobileDataEnabled
        ? switch (_selectedScenario) {
            0 => 110,
            1 => 100,
            _ => 65,
          }
        : 0;
    return _scenario.baseConsumptionMa * screenFactor +
        locationDraw +
        mobileDataDraw;
  }

  int get _remainingMinutes {
    final availableCapacity =
        _phone.batteryCapacityMah *
        (_percentage / 100) *
        (_batteryHealth / 100);
    return (availableCapacity / _estimatedConsumptionMa * 60).round();
  }

  Future<void> _getAiSuggestions() async {
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });

    try {
      final suggestion = await _requestAiReply(
        'Chargly için üç pil tasarrufu önerisi ver. Türkçe cevapla.',
      );
      if (!mounted) return;
      setState(() {
        _aiSuggestion = suggestion;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Bağlantı hatası: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _aiLoading = false;
        });
      }
    }
  }

  String get _remainingTime {
    final hours = _remainingMinutes ~/ 60;
    final minutes = _remainingMinutes % 60;
    if (hours == 0) return '$minutes dk';
    if (minutes == 0) return '$hours sa';
    return '$hours sa $minutes dk';
  }

  String get _batteryStatus {
    if (_percentage <= 15) return 'Kritik seviye';
    if (_percentage <= 30) return 'Düşük seviye';
    if (_percentage >= 80) return 'Çok iyi';
    return 'İyi durumda';
  }

  void _calculateEstimate() {
    setState(() => _calculationConfirmed = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Tahmini süre: $_remainingTime'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D3544),
        ),
      );
  }

  void _resetDemo() {
    setState(() {
      _percentage = 45;
      _selectedScenario = 2;
      _selectedPhone = 0;
      _brightness = 1;
      _batteryHealth = 90;
      _locationEnabled = false;
      _mobileDataEnabled = true;
      _calculationConfirmed = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Demo başlangıç değerlerine döndürüldü.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1D3544),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 20,
                      vertical: wide ? 32 : 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(wide),
                        const SizedBox(height: 20),
                        _buildPhonePicker(),
                        const SizedBox(height: 20),
                        _buildSectionHeading(
                          'Ne yapacaksın?',
                          'Kullanım türünü seç',
                        ),
                        const SizedBox(height: 12),
                        _buildScenarioPicker(wide),
                        const SizedBox(height: 18),
                        _buildControls(),
                        const SizedBox(height: 14),
                        _buildImpactSettings(),
                        const SizedBox(height: 18),
                        _buildOverview(wide),
                        const SizedBox(height: 14),
                        _buildMetricCards(wide),
                        const SizedBox(height: 14),
                        _buildAiCard(),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Tahmin; model kapasitesi, pil sağlığı, ekran '
                            'parlaklığı, konum ve mobil veri kullanımına göre '
                            'hesaplanır. Gerçek sonuçlar değişebilir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool wide) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('main-menu-button'),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menüyü aç',
          icon: const Icon(Icons.menu_rounded),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.bolt_rounded, color: _accent, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chargly',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            Text(
              'PİL TAHMİN ASİSTANI',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (wide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF111F2D),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, size: 16, color: _accent),
                const SizedBox(width: 7),
                Text(
                  'Web demosu',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF111F2D)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.bolt_rounded, color: _accent, size: 34),
                  SizedBox(height: 8),
                  Text(
                    'Chargly',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Pil tahmin asistanı',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: const Text('AI ile sohbet'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const _AiSuggestionsPage(initialSuggestion: ''),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.design_services_outlined),
              title: const Text('Tasarım ekibi'),
              onTap: () => _showInfoDialog(
                'Tasarım ekibi',
                'Tasarımcı bilgilerini paylaştığınızda bu alana ekleyebiliriz.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Destek hattı'),
              onTap: () => _showInfoDialog(
                'Destek hattı',
                'Destek iletişim bilgileri henüz eklenmedi.',
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'YAPIMCI EKİP',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.groups_2_outlined, color: _accent),
              title: Text('Psikolojik Destek'),
              subtitle: Text('Sarp Kale · İsmet Yüksel · Rafael Oulbars'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telefon modelinizi seçin',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const ValueKey('phone-model-selector'),
            initialValue: _selectedPhone,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_iphone_rounded),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items: [
              for (var index = 0; index < _phones.length; index++)
                DropdownMenuItem(
                  value: index,
                  child: Text(
                    '${_phones[index].name} · '
                    '${_phones[index].batteryCapacityMah} mAh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedPhone = value;
                _calculationConfirmed = false;
              });
            },
          ),
          const SizedBox(height: 7),
          Text(
            '${_phone.capacityNote}. Model seçenekleri şu an Apple ve Samsung '
            'telefonlarını kapsar.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard() {
    return SizedBox(
      height: 208,
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: _accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chargly AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _aiLoading
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Öneriler hazırlanıyor...'),
                          ],
                        )
                      : _aiError != null
                      ? Text(
                          _aiError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFFF7373)),
                        )
                      : _aiSuggestion.isNotEmpty
                      ? Text(
                          _aiSuggestion,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.35),
                        )
                      : const Text(
                          "Pil tasarrufu ve kullanım süresi hakkında Chargly "
                          "AI'dan öneri al.",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _aiLoading
                      ? null
                      : _aiSuggestion.isNotEmpty
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _AiSuggestionsPage(
                                initialSuggestion: _aiSuggestion,
                              ),
                            ),
                          );
                        }
                      : _getAiSuggestions,
                  icon: Icon(
                    _aiSuggestion.isNotEmpty
                        ? Icons.arrow_forward_rounded
                        : _aiError != null
                        ? Icons.refresh_rounded
                        : Icons.auto_awesome,
                    size: 18,
                  ),
                  label: Text(
                    _aiSuggestion.isNotEmpty
                        ? 'Daha fazla görüntüle'
                        : _aiError != null
                        ? 'Tekrar dene'
                        : 'Öneri al',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(bool wide) {
    final battery = _buildBatteryVisual();
    final estimate = _buildEstimatePanel();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: battery),
                Container(
                  width: 1,
                  height: 172,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(child: estimate),
              ],
            )
          : Column(
              children: [
                battery,
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 18),
                estimate,
              ],
            ),
    );
  }

  Widget _buildBatteryVisual() {
    final batteryColor = _percentage <= 15
        ? const Color(0xFFFF7373)
        : _percentage <= 30
        ? const Color(0xFFFFB454)
        : _accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEVCUT PİL',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Pil seviyesi yüzde $_percentage',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final batteryWidth = constraints.maxWidth;
                    return SizedBox(
                      height: 92,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            width: batteryWidth - 9,
                            height: 86,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: const Color(0xFF1A2B38)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _percentage / 100,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: batteryColor.withValues(
                                            alpha: 0.22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$_percentage%',
                                          style: const TextStyle(
                                            fontSize: 33,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.bolt_rounded,
                                          color: batteryColor,
                                          size: 23,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              width: 7,
                              height: 27,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _percentage <= 15 ? 'Şarj etmeniz önerilir' : 'Kalan enerji seviyesi',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEstimatePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule_rounded, color: _accent, size: 19),
            const SizedBox(width: 8),
            Text(
              'TAHMİNİ KALAN SÜRE',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _remainingTime,
            key: ValueKey(_remainingTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_phone · ${_scenario.name.toLowerCase()} için yaklaşık süre',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              _calculationConfirmed
                  ? Icons.check_circle_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 16,
              color: _accent,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _calculationConfirmed
                    ? 'Seçimlere göre güncellendi'
                    : 'Canlı tahmin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards(bool wide) {
    final cards = [
      _MetricCard(
        icon: Icons.battery_full_rounded,
        label: 'BATARYA KAPASİTESİ',
        value: '${_phone.batteryCapacityMah} mAh',
        detail: _phone.capacityNote,
        color: const Color(0xFF70B8FF),
      ),
      _MetricCard(
        icon: Icons.bolt_rounded,
        label: 'TAHMİNİ TÜKETİM',
        value: '${_estimatedConsumptionMa.round()} mA',
        detail: 'Parlaklık ve sensörler dahil',
        color: _percentage <= 15
            ? const Color(0xFFFF7373)
            : _percentage <= 30
            ? const Color(0xFFFFB454)
            : _accent,
      ),
      _MetricCard(
        icon: Icons.health_and_safety_outlined,
        label: 'ŞARJ DURUMU',
        value: _batteryStatus,
        detail: 'Pil sağlığı: %$_batteryHealth',
        color: const Color(0xFFB89AFF),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = wide ? 3 : 1;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }

  Widget _buildScenarioPicker(bool wide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < _scenarios.length; index++) ...[
              SizedBox(
                width: itemWidth,
                child: _buildScenarioCard(index, _scenarios[index], wide),
              ),
              if (index != _scenarios.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildScenarioCard(int index, UsageScenario scenario, bool wide) {
    final selected = index == _selectedScenario;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${scenario.name} kullanımı, '
          '${scenario.baseConsumptionMa.toStringAsFixed(0)} miliamper yaklaşık tüketim',
      child: Material(
        color: selected ? const Color(0xFF15302F) : _panel,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          key: ValueKey('scenario-${scenario.name.toLowerCase()}'),
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            setState(() {
              _selectedScenario = index;
              _calculationConfirmed = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(wide ? 16 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? _accent.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.07),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      scenario.icon,
                      size: 18,
                      color: selected ? _accent : _muted,
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _accent,
                        size: 17,
                      ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  scenario.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${scenario.baseConsumptionMa.round()} mA',
                  style: TextStyle(
                    color: selected ? _accent : _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final resetButton = OutlinedButton.icon(
      onPressed: _resetDemo,
      icon: const Icon(Icons.restart_alt_rounded, size: 18),
      label: const Text('Demoyu sıfırla'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFC3D0DC),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
    final calculateButton = FilledButton.icon(
      onPressed: _calculateEstimate,
      icon: const Icon(Icons.bolt_rounded, size: 18),
      label: const Text('Tahmini süreyi hesapla'),
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF06211F),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _accent, size: 19),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Şarj seviyen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$_percentage%',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('battery-slider'),
            value: _percentage.toDouble(),
            min: 5,
            max: 100,
            divisions: 95,
            activeColor: _accent,
            inactiveColor: const Color(0xFF293947),
            label: '$_percentage%',
            onChanged: (value) {
              setState(() {
                _percentage = value.round();
                _calculationConfirmed = false;
              });
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    resetButton,
                    const SizedBox(height: 10),
                    calculateButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: resetButton),
                  const SizedBox(width: 12),
                  Expanded(child: calculateButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahmini etkileyen koşullar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Ekran parlaklığı',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Düşük')),
              ButtonSegment(value: 1, label: Text('Orta')),
              ButtonSegment(value: 2, label: Text('Yüksek')),
            ],
            selected: {_brightness},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() {
                _brightness = selection.first;
                _calculationConfirmed = false;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: _muted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Pil sağlığı', style: TextStyle(fontSize: 13)),
              ),
              Text(
                '$_batteryHealth%',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('battery-health-slider'),
            value: _batteryHealth.toDouble(),
            min: 50,
            max: 100,
            divisions: 50,
            label: '$_batteryHealth%',
            activeColor: _accent,
            onChanged: (value) {
              setState(() {
                _batteryHealth = value.round();
                _calculationConfirmed = false;
              });
            },
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: _muted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Konum / GPS açık', style: TextStyle(fontSize: 13)),
              ),
              Switch.adaptive(
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                    _calculationConfirmed = false;
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt_rounded, color: _muted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mobil veri kullanımı',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch.adaptive(
                value: _mobileDataEnabled,
                onChanged: (value) {
                  setState(() {
                    _mobileDataEnabled = value;
                    _calculationConfirmed = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionsPage extends StatefulWidget {
  const _AiSuggestionsPage({required this.initialSuggestion});

  final String initialSuggestion;

  @override
  State<_AiSuggestionsPage> createState() => _AiSuggestionsPageState();
}

class _AiSuggestionsPageState extends State<_AiSuggestionsPage> {
  bool _aiLoading = false;
  String? _aiError;
  final _questionController = TextEditingController();
  final _messages = <_AiChatMessage>[];
  final _scrollController = ScrollController();

  static const _suggestedQuestions = [
    'Ekran parlaklığı şarjı nasıl etkiler?',
    'Pilimi daha uzun kullanmak için ne yapabilirim?',
    'Bir uygulamanın şarjı ne kadar tükettiğini nasıl anlarım?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _AiChatMessage(
        text: widget.initialSuggestion.isEmpty
            ? 'Merhaba! Pil, batarya ve şarj tüketimi hakkında bana soru '
                  'sorabilirsin.'
            : widget.initialSuggestion,
        isAi: true,
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askAi([String? question]) async {
    final text = (question ?? _questionController.text).trim();
    if (text.isEmpty || _aiLoading) return;

    setState(() {
      _messages.add(_AiChatMessage(text: text, isAi: false));
      _aiLoading = true;
      _aiError = null;
      _questionController.clear();
    });
    _scrollToLatest();

    try {
      final answer = await _requestAiReply('$text Türkçe cevapla.');
      if (!mounted) return;
      setState(() {
        _messages.add(_AiChatMessage(text: answer, isAi: true));
      });
      _scrollToLatest();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Bağlantı hatası: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _aiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chargly AI önerileri')),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Geri dön'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pil ve şarj hakkında Chargly AI'ya soru sor.",
                  style: TextStyle(color: Color(0xFF91A4B7), fontSize: 13),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount:
                    _messages.length +
                    (_aiLoading ? 1 : 0) +
                    (_aiError != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessage(_messages[index]);
                  }
                  if (_aiLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _aiError!,
                      style: const TextStyle(color: Color(0xFFFF7373)),
                    ),
                  );
                },
              ),
            ),
            _buildQuestionComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_AiChatMessage message) {
    return Align(
      alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isAi
              ? const Color(0xFF111F2D)
              : const Color(0xFF15302F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text, style: const TextStyle(height: 1.45)),
      ),
    );
  }

  Widget _buildQuestionComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111F2D),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final question in _suggestedQuestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _aiLoading ? null : () => _askAi(question),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _askAi(),
                  decoration: const InputDecoration(
                    hintText: 'Pil hakkında bir soru yaz...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _aiLoading ? null : _askAi,
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Soruyu gönder',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _AiChatMessage {
  const _AiChatMessage({required this.text, required this.isAi});

  final String text;
  final bool isAi;
}

Future<String> _requestAiReply(String message) async {
  final uri = kIsWeb
      ? _webAiEndpoint
      : Uri.parse('https://chargly-api-1.onrender.com/suggest');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'message': message}),
  );

  if (response.statusCode != 200) {
    var detail = 'Sunucu hatası: ${response.statusCode}';
    try {
      final error = jsonDecode(response.body);
      if (error is Map<String, dynamic> && error['detail'] is String) {
        detail = error['detail'] as String;
      }
    } on FormatException {
      // Keep the HTTP status when the server does not return JSON.
    }
    throw Exception(detail);
  }

  final data = jsonDecode(response.body);
  if (data is! Map<String, dynamic> ||
      data['choices'] is! List ||
      (data['choices'] as List).isEmpty ||
      (data['choices'] as List).first is! Map<String, dynamic>) {
    throw const FormatException('AI sunucusundan beklenmeyen yanıt alındı.');
  }

  final firstChoice = (data['choices'] as List).first as Map<String, dynamic>;
  final messageData = firstChoice['message'];
  if (messageData is! Map<String, dynamic> ||
      messageData['content'] is! String ||
      (messageData['content'] as String).trim().isEmpty) {
    throw const FormatException('AI sunucusu boş bir yanıt döndürdü.');
  }
  return messageData['content'] as String;
}

Uri get _webAiEndpoint {
  final host = Uri.base.host;
  if (host == 'localhost' || host == '127.0.0.1') {
    return Uri.parse('http://127.0.0.1:8000/suggest');
  }
  return Uri.base.resolve('/api/suggest');
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF111F2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF91A4B7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF91A4B7),
                    fontSize: 10,
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
