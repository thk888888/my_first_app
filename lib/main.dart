import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CertificateApp());
}

// ============================================================
// App
// ============================================================

class CertificateApp extends StatelessWidget {
  const CertificateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '我的证书',
      themeMode: ThemeMode.system,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.dark,
        ),
      ),

      home: const CertificateHomePage(),
    );
  }
}

// ============================================================
// Certificate Model
// ============================================================

class Certificate {
  String id;
  String title;
  String subtitle;
  String category;
  DateTime date;
  String organization;
  String number;
  String note;

  Certificate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.date,
    required this.organization,
    required this.number,
    required this.note,
  });

  // 保存到本地时转换成 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'date': date.toIso8601String(),
      'organization': organization,
      'number': number,
      'note': note,
    };
  }

  // 从本地读取
  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      category: json['category'] ?? '其他',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      organization: json['organization'] ?? '',
      number: json['number'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

// ============================================================
// Home Page
// ============================================================

class CertificateHomePage extends StatefulWidget {
  const CertificateHomePage({super.key});

  @override
  State<CertificateHomePage> createState() =>
      _CertificateHomePageState();
}

class _CertificateHomePageState
    extends State<CertificateHomePage> {
  static const String _storageKey = 'certificates';

  final List<Certificate> _certificates = [];

  String _searchText = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  // ==========================================================
  // Load
  // ==========================================================

  Future<void> _loadCertificates() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData = prefs.getString(_storageKey);

    if (savedData == null || savedData.isEmpty) {
      _certificates.addAll(_demoCertificates());
    } else {
      try {
        final List<dynamic> decoded =
            jsonDecode(savedData) as List<dynamic>;

        _certificates.addAll(
          decoded.map(
            (item) => Certificate.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      } catch (_) {
        _certificates.addAll(_demoCertificates());
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // ==========================================================
  // Save
  // ==========================================================

  Future<void> _saveCertificates() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _certificates
        .map((certificate) => certificate.toJson())
        .toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  // ==========================================================
  // Demo Data
  // ==========================================================

  List<Certificate> _demoCertificates() {
    return [
      Certificate(
        id: 'demo_1',
        title: '大学英语四级',
        subtitle: 'CET-4',
        category: '英语',
        date: DateTime(2025, 6, 1),
        organization: '全国大学英语四、六级考试',
        number: '',
        note: '',
      ),
      Certificate(
        id: 'demo_2',
        title: '全国计算机等级考试',
        subtitle: 'MS Office 二级',
        category: '计算机',
        date: DateTime(2025, 9, 1),
        organization: '教育部教育考试院',
        number: '',
        note: '',
      ),
      Certificate(
        id: 'demo_3',
        title: '普通话水平测试',
        subtitle: '二级甲等',
        category: '专业',
        date: DateTime(2025, 5, 1),
        organization: '国家普通话水平测试',
        number: '',
        note: '',
      ),
    ];
  }

  // ==========================================================
  // Search
  // ==========================================================

  List<Certificate> get _filteredCertificates {
    if (_searchText.trim().isEmpty) {
      return _certificates;
    }

    final keyword = _searchText.trim().toLowerCase();

    return _certificates.where((certificate) {
      return certificate.title
              .toLowerCase()
              .contains(keyword) ||
          certificate.subtitle
              .toLowerCase()
              .contains(keyword) ||
          certificate.category
              .toLowerCase()
              .contains(keyword) ||
          certificate.organization
              .toLowerCase()
              .contains(keyword) ||
          certificate.number
              .toLowerCase()
              .contains(keyword) ||
          certificate.note
              .toLowerCase()
              .contains(keyword);
    }).toList();
  }

  // ==========================================================
  // Category Count
  // ==========================================================

  int _categoryCount(String category) {
    return _certificates
        .where(
          (certificate) =>
              certificate.category == category,
        )
        .length;
  }

  // ==========================================================
  // Add
  // ==========================================================

  Future<void> _addCertificate() async {
    final result = await Navigator.of(context).push<Certificate>(
      MaterialPageRoute(
        builder: (_) => const AddCertificatePage(),
      ),
    );

    if (result == null) return;

    setState(() {
      _certificates.insert(0, result);
    });

    await _saveCertificates();
  }

  // ==========================================================
  // Open
  // ==========================================================

  Future<void> _openCertificate(
    Certificate certificate,
  ) async {
    final result =
        await Navigator.of(context).push<CertificateDetailResult>(
      MaterialPageRoute(
        builder: (_) => CertificateDetailPage(
          certificate: certificate,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (result.deleted) {
        _certificates.removeWhere(
          (item) => item.id == certificate.id,
        );
      } else if (result.updatedCertificate != null) {
        final index = _certificates.indexWhere(
          (item) => item.id == certificate.id,
        );

        if (index != -1) {
          _certificates[index] =
              result.updatedCertificate!;
        }
      }
    });

    await _saveCertificates();
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = _primaryColor(isDark);

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF1D1D1F);

    final secondaryTextColor = isDark
        ? Colors.white60
        : const Color(0xFF6E6E73);

    final certificates = _filteredCertificates;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),

        slivers: [
          // ==================================================
          // Navigation Bar
          // ==================================================

          SliverAppBar(
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.78)
                : Colors.white.withOpacity(0.78),

            surfaceTintColor: Colors.transparent,

            elevation: 0,

            pinned: true,

            expandedHeight: 110,

            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 20,
                bottom: 14,
              ),

              title: Text(
                '我的证书',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _GlassButton(
                  icon: Icons.settings_outlined,
                  onTap: () {},
                ),
              ),
            ],
          ),

          // ==================================================
          // Main Content
          // ==================================================

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              120,
            ),

            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Text(
                    '大学期间',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '我获得了',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -1.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_certificates.length}',
                        style: TextStyle(
                          fontSize: 64,
                          height: 0.95,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: -3,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 7,
                        ),
                        child: Text(
                          '项证书',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // Categories
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.language_rounded,
                          title: '英语',
                          count:
                              '${_categoryCount('英语')}',
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.computer_rounded,
                          title: '计算机',
                          count:
                              '${_categoryCount('计算机')}',
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.school_rounded,
                          title: '专业',
                          count:
                              '${_categoryCount('专业')}',
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.more_horiz_rounded,
                          title: '其他',
                          count:
                              '${_categoryCount('其他')}',
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // ==================================================
                  // Search
                  // ==================================================

                  _SearchBar(
                    isDark: isDark,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // Certificate Header
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '我的证书',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.8,
                        ),
                      ),

                      Text(
                        '${certificates.length} 项',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // Certificate List
                  // ==================================================

                  if (certificates.isEmpty)
                    _EmptyState(
                      isDark: isDark,
                      onAdd: _addCertificate,
                    )
                  else
                    ...certificates.map(
                      (certificate) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child: _CertificateCard(
                            certificate: certificate,
                            isDark: isDark,
                            iconColor: primaryColor,
                            onTap: () {
                              _openCertificate(
                                certificate,
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: _GlassAddButton(
        primaryColor: primaryColor,
        onTap: _addCertificate,
      ),
    );
  }

  Color _primaryColor(bool isDark) {
    return isDark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
  }
}

// ============================================================
// Add / Edit Certificate Page
// ============================================================

class AddCertificatePage extends StatefulWidget {
  final Certificate? certificate;

  const AddCertificatePage({
    super.key,
    this.certificate,
  });

  @override
  State<AddCertificatePage> createState() =>
      _AddCertificatePageState();
}

class _AddCertificatePageState
    extends State<AddCertificatePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController
      _organizationController;
  late final TextEditingController _numberController;
  late final TextEditingController _noteController;

  String _category = '其他';

  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();

    final certificate = widget.certificate;

    _titleController = TextEditingController(
      text: certificate?.title ?? '',
    );

    _subtitleController = TextEditingController(
      text: certificate?.subtitle ?? '',
    );

    _organizationController =
        TextEditingController(
      text: certificate?.organization ?? '',
    );

    _numberController = TextEditingController(
      text: certificate?.number ?? '',
    );

    _noteController = TextEditingController(
      text: certificate?.note ?? '',
    );

    if (certificate != null) {
      _category = certificate.category;
      _date = certificate.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _organizationController.dispose();
    _numberController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _date = selected;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final certificate = Certificate(
      id: widget.certificate?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      title: _titleController.text.trim(),

      subtitle: _subtitleController.text.trim(),

      category: _category,

      date: _date,

      organization:
          _organizationController.text.trim(),

      number:
          _numberController.text.trim(),

      note:
          _noteController.text.trim(),
    );

    Navigator.pop(context, certificate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);

    final isEditing =
        widget.certificate != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '编辑证书' : '添加证书',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              '保存',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            physics:
                const BouncingScrollPhysics(),

            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              40,
            ),

            children: [
              _SectionTitle(
                title: '基本信息',
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _FormCard(
                isDark: isDark,
                children: [
                  _TextField(
                    controller:
                        _titleController,
                    label: '证书名称',
                    hint: '例如：大学英语四级',
                    icon: Icons
                        .workspace_premium_outlined,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return '请输入证书名称';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _TextField(
                    controller:
                        _subtitleController,
                    label: '证书简称 / 等级',
                    hint: '例如：CET-4',
                    icon: Icons
                        .label_outline_rounded,
                  ),

                  const SizedBox(height: 16),

                  _TextField(
                    controller:
                        _organizationController,
                    label: '颁发机构',
                    hint: '例如：教育部教育考试院',
                    icon: Icons
                        .account_balance_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: '证书分类',
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _FormCard(
                isDark: isDark,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,

                    decoration:
                        const InputDecoration(
                      labelText: '分类',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                      ),
                      border: InputBorder.none,
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: '英语',
                        child: Text('英语'),
                      ),
                      DropdownMenuItem(
                        value: '计算机',
                        child: Text('计算机'),
                      ),
                      DropdownMenuItem(
                        value: '专业',
                        child: Text('专业'),
                      ),
                      DropdownMenuItem(
                        value: '其他',
                        child: Text('其他'),
                      ),
                    ],

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: '获得时间',
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _FormCard(
                isDark: isDark,
                children: [
                  InkWell(
                    borderRadius:
                        BorderRadius.circular(18),
                    onTap: _selectDate,

                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 8,
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .calendar_today_outlined,
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  '获得日期',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  _formatDate(_date),
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons
                                .chevron_right_rounded,
                            color: isDark
                                ? Colors.white38
                                : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: '更多信息',
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _FormCard(
                isDark: isDark,
                children: [
                  _TextField(
                    controller:
                        _numberController,
                    label: '证书编号',
                    hint: '可选',
                    icon:
                        Icons.numbers_outlined,
                  ),

                  const SizedBox(height: 16),

                  _TextField(
                    controller:
                        _noteController,
                    label: '备注',
                    hint: '可选',
                    icon:
                        Icons.notes_outlined,
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              FilledButton(
                onPressed: _save,

                style:
                    FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(54),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  backgroundColor:
                      primaryColor,
                ),

                child: Text(
                  isEditing
                      ? '保存修改'
                      : '添加证书',

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Certificate Detail Result
// ============================================================

class CertificateDetailResult {
  final Certificate? updatedCertificate;
  final bool deleted;

  CertificateDetailResult({
    this.updatedCertificate,
    this.deleted = false,
  });
}

// ============================================================
// Certificate Detail Page
// ============================================================

class CertificateDetailPage
    extends StatelessWidget {
  final Certificate certificate;

  const CertificateDetailPage({
    super.key,
    required this.certificate,
  });

  Future<void> _edit(
    BuildContext context,
  ) async {
    final updated =
        await Navigator.of(context)
            .push<Certificate>(
      MaterialPageRoute(
        builder: (_) =>
            AddCertificatePage(
          certificate: certificate,
        ),
      ),
    );

    if (updated == null) return;

    if (!context.mounted) return;

    Navigator.pop(
      context,
      CertificateDetailResult(
        updatedCertificate: updated,
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
  ) async {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text('删除证书？'),

          content: const Text(
            '删除后，这项证书的信息将从 App 中移除。',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('取消'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: Text(
                '删除',
                style: TextStyle(
                  color: isDark
                      ? Colors.redAccent
                      : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    Navigator.pop(
      context,
      CertificateDetailResult(
        deleted: true,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF1D1D1F);

    final secondaryTextColor = isDark
        ? Colors.white60
        : const Color(0xFF6E6E73);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '证书详情',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        backgroundColor:
            Colors.transparent,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        actions: [
          IconButton(
            onPressed: () {
              _edit(context);
            },

            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),

          IconButton(
            onPressed: () {
              _delete(context);
            },

            icon: const Icon(
              Icons
                  .delete_outline_rounded,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: ListView(
        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40,
        ),

        children: [
          _DetailHeroCard(
            certificate: certificate,
            primaryColor:
                primaryColor,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          Text(
            '证书信息',
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          _DetailCard(
            isDark: isDark,

            children: [
              _DetailRow(
                icon:
                    Icons.category_outlined,
                title: '分类',
                value:
                    certificate.category,
                isDark: isDark,
              ),

              _DetailDivider(
                isDark: isDark,
              ),

              _DetailRow(
                icon: Icons
                    .calendar_today_outlined,
                title: '获得时间',
                value:
                    _formatDate(
                  certificate.date,
                ),
                isDark: isDark,
              ),

              _DetailDivider(
                isDark: isDark,
              ),

              _DetailRow(
                icon: Icons
                    .account_balance_outlined,
                title: '颁发机构',
                value: certificate
                        .organization
                        .isEmpty
                    ? '未填写'
                    : certificate
                        .organization,
                isDark: isDark,
              ),

              _DetailDivider(
                isDark: isDark,
              ),

              _DetailRow(
                icon:
                    Icons.numbers_outlined,
                title: '证书编号',
                value: certificate
                        .number
                        .isEmpty
                    ? '未填写'
                    : certificate.number,
                isDark: isDark,
              ),
            ],
          ),

          if (certificate.note.isNotEmpty) ...[
            const SizedBox(height: 24),

            Text(
              '备注',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            _DetailCard(
              isDark: isDark,

              children: [
                Text(
                  certificate.note,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color:
                        secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),

          OutlinedButton.icon(
            onPressed: () {
              _edit(context);
            },

            icon: const Icon(
              Icons.edit_outlined,
            ),

            label:
                const Text('编辑证书'),

            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(
                52,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Detail Hero Card
// ============================================================

class _DetailHeroCard
    extends StatelessWidget {
  final Certificate certificate;
  final Color primaryColor;
  final bool isDark;

  const _DetailHeroCard({
    required this.certificate,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(30),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(24),

          decoration: BoxDecoration(
            color: isDark
                ? Colors.white
                    .withOpacity(0.08)
                : Colors.white
                    .withOpacity(0.82),

            borderRadius:
                BorderRadius.circular(30),

            border: Border.all(
              color: isDark
                  ? Colors.white
                      .withOpacity(0.10)
                  : Colors.white
                      .withOpacity(0.85),
            ),
          ),

          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,

                decoration:
                    BoxDecoration(
                  color: primaryColor
                      .withOpacity(0.12),

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),

                child: Icon(
                  _categoryIcon(
                    certificate.category,
                  ),
                  color:
                      primaryColor,
                  size: 36,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                certificate.title,
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.w800,
                  color: isDark
                      ? Colors.white
                      : const Color(
                          0xFF1D1D1F,
                        ),
                  letterSpacing: -0.8,
                ),
              ),

              if (certificate
                  .subtitle
                  .isNotEmpty) ...[
                const SizedBox(height: 6),

                Text(
                  certificate.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),

                decoration:
                    BoxDecoration(
                  color: primaryColor
                      .withOpacity(0.10),

                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),

                child: Text(
                  certificate.category,
                  style: TextStyle(
                    color:
                        primaryColor,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Category Card
// ============================================================

class _CategoryCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final Color color;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(18),

          decoration:
              BoxDecoration(
            color: isDark
                ? Colors.white
                    .withOpacity(0.08)
                : Colors.white
                    .withOpacity(0.72),

            borderRadius:
                BorderRadius.circular(24),

            border: Border.all(
              color: isDark
                  ? Colors.white
                      .withOpacity(0.10)
                  : Colors.white
                      .withOpacity(0.9),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? Colors.white70
                      : Colors.black54,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                count,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w700,
                  color: isDark
                      ? Colors.white
                      : const Color(
                          0xFF1D1D1F,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Certificate Card
// ============================================================

class _CertificateCard
    extends StatelessWidget {
  final Certificate certificate;
  final bool isDark;
  final Color iconColor;
  final VoidCallback onTap;

  const _CertificateCard({
    required this.certificate,
    required this.isDark,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(28),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),

        child: Material(
          color: isDark
              ? Colors.white
                  .withOpacity(0.075)
              : Colors.white
                  .withOpacity(0.82),

          child: InkWell(
            onTap: onTap,

            child: Container(
              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),

                border: Border.all(
                  color: isDark
                      ? Colors.white
                          .withOpacity(0.10)
                      : Colors.white
                          .withOpacity(0.85),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      isDark ? 0.15 : 0.04,
                    ),
                    blurRadius: 20,
                    offset:
                        const Offset(0, 8),
                  ),
                ],
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration:
                        BoxDecoration(
                      color: iconColor
                          .withOpacity(
                        0.12,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        17,
                      ),
                    ),

                    child: Icon(
                      _categoryIcon(
                        certificate.category,
                      ),
                      color: iconColor,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          certificate.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color: isDark
                                ? Colors.white
                                : const Color(
                                    0xFF1D1D1F,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (certificate
                            .subtitle
                            .isNotEmpty)
                          Text(
                            certificate.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),

                        const SizedBox(height: 13),

                        Row(
                          children: [
                            Text(
                              _formatYearMonth(
                                certificate.date,
                              ),

                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              width: 3,
                              height: 3,

                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black26,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                certificate
                                        .organization
                                        .isEmpty
                                    ? certificate
                                        .category
                                    : certificate
                                        .organization,

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons
                        .chevron_right_rounded,
                    color: isDark
                        ? Colors.white38
                        : Colors.black26,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Search Bar
// ============================================================

class _SearchBar
    extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: TextField(
          onChanged: onChanged,

          style: const TextStyle(
            fontSize: 16,
          ),

          decoration:
              InputDecoration(
            hintText: '搜索证书',

            prefixIcon:
                const Icon(
              Icons.search_rounded,
            ),

            filled: true,

            fillColor: isDark
                ? Colors.white
                    .withOpacity(0.08)
                : Colors.white
                    .withOpacity(0.75),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              borderSide:
                  BorderSide.none,
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              borderSide:
                  BorderSide.none,
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              borderSide:
                  BorderSide.none,
            ),

            contentPadding:
                const EdgeInsets
                    .symmetric(
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Empty State
// ============================================================

class _EmptyState
    extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(28),

      child: Container(
        padding:
            const EdgeInsets.all(30),

        decoration:
            BoxDecoration(
          color: isDark
              ? Colors.white
                  .withOpacity(0.06)
              : Colors.white
                  .withOpacity(0.72),

          borderRadius:
              BorderRadius.circular(28),
        ),

        child: Column(
          children: [
            Icon(
              Icons
                  .workspace_premium_outlined,
              size: 48,
              color: isDark
                  ? Colors.white38
                  : Colors.black26,
            ),

            const SizedBox(height: 16),

            const Text(
              '还没有找到证书',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '点击右下角 + 添加你的第一张证书',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed: onAdd,
              child:
                  const Text('添加证书'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Form Section Title
// ============================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight:
            FontWeight.w700,
        color: isDark
            ? Colors.white
            : const Color(
                0xFF1D1D1F,
              ),
        letterSpacing: -0.4,
      ),
    );
  }
}

// ============================================================
// Form Card
// ============================================================

class _FormCard
    extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _FormCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),

      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration:
            BoxDecoration(
          color: isDark
              ? Colors.white
                  .withOpacity(0.075)
              : Colors.white
                  .withOpacity(0.82),

          borderRadius:
              BorderRadius.circular(24),

          border: Border.all(
            color: isDark
                ? Colors.white
                    .withOpacity(0.10)
                : Colors.white
                    .withOpacity(0.85),
          ),
        ),

        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// Text Field
// ============================================================

class _TextField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return TextFormField(
      controller: controller,

      maxLines: maxLines,

      validator: validator,

      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon:
            Icon(icon),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),

          borderSide:
              BorderSide.none,
        ),

        filled: true,

        fillColor: isDark
            ? Colors.white
                .withOpacity(0.06)
            : Colors.black
                .withOpacity(0.035),
      ),
    );
  }
}

// ============================================================
// Detail Card
// ============================================================

class _DetailCard
    extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _DetailCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),

      child: Container(
        padding:
            const EdgeInsets.all(20),

        decoration:
            BoxDecoration(
          color: isDark
              ? Colors.white
                  .withOpacity(0.075)
              : Colors.white
                  .withOpacity(0.82),

          borderRadius:
              BorderRadius.circular(24),

          border: Border.all(
            color: isDark
                ? Colors.white
                    .withOpacity(0.10)
                : Colors.white
                    .withOpacity(0.85),
          ),
        ),

        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// Detail Row
// ============================================================

class _DetailRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 22,
          color: isDark
              ? Colors.white54
              : Colors.black45,
        ),

        const SizedBox(width: 14),

        SizedBox(
          width: 75,

          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white54
                  : Colors.black45,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,

            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
              color: isDark
                  ? Colors.white
                  : const Color(
                      0xFF1D1D1F,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Detail Divider
// ============================================================

class _DetailDivider
    extends StatelessWidget {
  final bool isDark;

  const _DetailDivider({
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),

      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white
                .withOpacity(0.08)
            : Colors.black
                .withOpacity(0.06),
      ),
    );
  }
}

// ============================================================
// Glass Button
// ============================================================

class _GlassButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Material(
          color: isDark
              ? Colors.white
                  .withOpacity(0.10)
              : Colors.white
                  .withOpacity(0.65),

          child: InkWell(
            onTap: onTap,

            child: SizedBox(
              width: 42,
              height: 42,

              child: Icon(
                icon,
                size: 21,
                color: isDark
                    ? Colors.white
                    : const Color(
                        0xFF1D1D1F,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Glass Add Button
// ============================================================

class _GlassAddButton
    extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _GlassAddButton({
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),

        child: Material(
          color: isDark
              ? Colors.white
                  .withOpacity(0.12)
              : Colors.white
                  .withOpacity(0.80),

          child: InkWell(
            onTap: onTap,

            child: Container(
              width: 62,
              height: 62,

              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),

                border: Border.all(
                  color: isDark
                      ? Colors.white
                          .withOpacity(0.12)
                      : Colors.white,
                ),

                boxShadow: [
                  BoxShadow(
                    color: primaryColor
                        .withOpacity(0.18),
                    blurRadius: 20,
                    offset:
                        const Offset(0, 8),
                  ),
                ],
              ),

              child: Icon(
                Icons.add_rounded,
                size: 30,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Utilities
// ============================================================

String _formatDate(
  DateTime date,
) {
  return '${date.year}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatYearMonth(
  DateTime date,
) {
  return '${date.year}.'
      '${date.month.toString().padLeft(2, '0')}';
}

IconData _categoryIcon(
  String category,
) {
  switch (category) {
    case '英语':
      return Icons.language_rounded;

    case '计算机':
      return Icons.computer_rounded;

    case '专业':
      return Icons.school_rounded;

    default:
      return Icons
          .workspace_premium_rounded;
  }
}